# Securing the VMware Cloud Foundation management domain with VMware vDefend

Terraform configuration to automate the deployment of vDefend Distributed Firewall (DFW) policies that secure VMware Cloud Foundation (VCF) management components, including VCF Fleet, VCF Fleet management service, SDDC Manager, vCenter Servers, NSX Managers, vDefend Security Services Platfrom, Avi Load Balancer, etc.

## Disclaimer

This configuration is provided as a reference example of how to quickly secure VCF management components. You are solely responsible for reviewing, adapting, and validating it for your own environment before applying it in production.

## Applicable Versions

| Component | Version |
|-----------|---------|
| VMware Cloud Foundation | 9.1.x |
| NSX Terraform Provider | Latest |

## Prerequisites

- VCF 9.1.x deployment with at least one management domain and one workload domain
- NSX Manager accessible from the Terraform host
- **NSX on DVPGs** enabled on all vSphere clusters whose VMs should be protected
- Terraform CLI installed on the host running these configurations
- NSX Enterprise Administrator credentials

## Repository Structure

The configuration is split into a root module, a shared `groups-and-services` module that
owns every cross-module NSX group/service, and per-category/per-domain policy child
modules, so that each policy module can be planned/applied independently with
`-target=module.<name>`:

```
.
├── main.tf                    # Provider configuration and module wiring
├── variables.tf               # Input variable declarations (all modules' inputs)
├── terraform.tfvars           # Variable values (copy and edit before use)
├── groups-and-services/       # Shared NSX groups and custom services
├── infrastructure/            # DFW "Infrastructure" category module
├── environment/                # DFW "Environment" category module
└── application/                 # DFW "Application" category modules
    ├── fm/                       #   VCF Fleet Management application policies
    ├── m01/                      #   Management domain (m01) application policies
    └── w01/                      #   Workload domain 01 (w01) application policies
```

| Module | File | Description |
|--------|------|-------------|
| root | `main.tf` | Terraform provider configuration and `module` blocks for `groups_and_services`, `infrastructure`, `environment`, and the three `application` modules |
| root | `variables.tf` | Input variable declarations |
| root | `terraform.tfvars` | Variable values (copy and edit before use) |
| `groups-and-services` | `groups-vcf_ext.tf` | NSX groups for external services (bastion, tools, backup, SMTP, SIEM) |
| `groups-and-services` | `groups-vcf_fm.tf` | NSX groups for VCF Fleet Management components |
| `groups-and-services` | `groups-vcf01_m01.tf` | NSX groups for management domain (m01) components |
| `groups-and-services` | `groups-vcf01_w01.tf` | NSX groups for workload domain 01 (w01) components |
| `groups-and-services` | `services.tf` | NSX service and context profile definitions shared across policy modules |
| `groups-and-services` | `variables.tf` / `outputs.tf` / `versions.tf` | Module inputs, the `group_paths`/`service_paths`/`context_profile_paths` maps consumed by every other module, and provider requirements |
| `infrastructure` | `groups.tf` | NSX groups for the core infrastructure services (DNS, NTP, DHCP, AD) — owned locally, not shared |
| `infrastructure` | `services.tf` | Local re-declarations of the shared NSX service data sources this module's rules use |
| `infrastructure` | `dfw-policy-infrastructure.tf` | DFW Infrastructure category policy |
| `infrastructure` | `variables.tf` / `versions.tf` | Module inputs (`group_paths`, `service_paths`, plus its own `dns_server`/`ntp_server`/`dhcp_server`/`ad_server`) and provider requirements |
| `environment` | `services.tf` | Local re-declarations of the shared NSX service data sources this module's rules use |
| `environment` | `dfw-policy-environment.tf` | DFW Environment category policies |
| `environment` | `variables.tf` / `versions.tf` | Module inputs (`group_paths`, `service_paths`, `context_profile_paths`) and provider requirements |
| `application/fm` | `dfw-policy-application-fm.tf` | Application policies for VCF Operations, VCF Operations for Logs, VCF Operations for Networks, and VCF Automation |
| `application/m01` | `dfw-policy-application-m01.tf` | Application policies for the management domain's vCenter, Avi, and SSP components |
| `application/w01` | `dfw-policy-application-w01.tf` | Application policies for workload domain 01's vCenter, NSX, and Avi components |
| `application/*` | `variables.tf` / `versions.tf` | Module inputs (`group_paths`, `service_paths`) and provider requirements |
| `application/*` | `services.tf` | Local re-declarations of the shared NSX service data sources each module's rules use |

Every NSX group and custom service that's referenced from more than one policy module
is defined exactly once, in `groups-and-services`, and exposed via its `group_paths` /
`service_paths` / `context_profile_paths` outputs. `environment`, `infrastructure`,
and all three `application` modules consume those maps identically
(`var.group_paths["x"]`, `var.service_paths["x"]`) — only `groups-and-services` itself
references the underlying resources directly. `infrastructure` additionally owns a
small set of groups/services used only by its own policy (DNS/NTP/DHCP/AD), and every
policy module locally re-declares the read-only NSX service *data sources* it needs
(safe to duplicate, since they're lookups, not managed resources).

**Dependencies and apply order.** `environment`, `infrastructure`, and all three
`application` modules depend only on `groups-and-services` — not on each other — so they
can be applied in any order relative to one another; `terraform apply -target=module.<name>`
for any of them automatically creates the `groups-and-services` resources it needs first.

**Workload domain 01 SSP.** The `w01_sspi`, `w01_ssp`, and `w01_sspm` groups in
`groups-and-services/groups-vcf01_w01.tf` are commented out (SSP is not yet deployed on
workload domain 01), so they are omitted from `group_paths`. The corresponding
"Workload Domain 01 SSP Policy" in `application/w01/dfw-policy-application-w01.tf` is
commented out to match — uncomment both together once SSP is deployed there. The
management domain equivalent (`vcf01_sspi`/`m01_ssp`/`m01_sspm` and the "Management
Domain SSP Policy" in `application/m01`) is active.

## Usage

**1. Clone the repository**

```bash
git clone <repo-url>
cd vcf-mgmt-wld-security
```

**2. Configure variables**

Copy the example values file and populate it with your environment's values:

```bash
cp terraform.tfvars terraform.tfvars.local
```

Edit `terraform.tfvars.local` and set the NSX Manager address, credentials, IP addresses, and VM name prefixes that match your deployment.

> **Note:** `terraform.tfvars` is excluded from version control by `.gitignore` to prevent accidental credential exposure.

**3. Initialize Terraform**

```bash
terraform init
```

**4. Review the plan**

```bash
terraform plan -var-file=terraform.tfvars.local
```

**5. Apply**

```bash
terraform apply -var-file=terraform.tfvars.local
```

To apply just one module, target it directly — `groups-and-services`, `infrastructure`,
`environment`, and the three `application` modules can be applied in any order
relative to one another, since only `groups-and-services` is a shared dependency:

```bash
terraform apply -var-file=terraform.tfvars.local -target=module.groups_and_services
terraform apply -var-file=terraform.tfvars.local -target=module.infrastructure
terraform apply -var-file=terraform.tfvars.local -target=module.environment
terraform apply -var-file=terraform.tfvars.local -target=module.application_fm
terraform apply -var-file=terraform.tfvars.local -target=module.application_m01
terraform apply -var-file=terraform.tfvars.local -target=module.application_w01
```

## DFW Policy Overview

The configuration creates three categories of DFW policies scoped to VCF components:

| Category | Policy | Description |
|----------|--------|-------------|
| Infrastructure | VCF Infrastructure Policy | Allows DNS, NTP, DHCP, AD, and syslog traffic; logs anything else |
| Environment | VCF Fleet Environment | Controls inbound access and outbound backup/mail/depot traffic for the full VCF fleet |
| Environment | VCF Fleet Management Environment | Controls traffic between fleet management tools and VCF domains |
| Environment | VCF01 Management Domain Environment | Intra-domain rules for the management domain |
| Environment | VCF01 Workload Domain 01 Environment | Intra-domain rules for workload domain 01 |
| Application | VCF Operations / Operations for Logs / Operations for Networks / Automation Policies | Component-level rules for VCF Fleet Management applications |
| Application | Management Domain vCenter / Avi / SSP Policies | Component-level rules for management domain (m01) applications |
| Application | Workload Domain 01 vCenter / NSX / Avi Policies | Component-level rules for workload domain 01 (w01) applications (SSP policy present but disabled — see above) |

All policies use `tcp_strict = true` and `stateful = true`. Each policy ends with an explicit **Lock Down** rule (`action = "ALLOW"`, `logged = true`) that allows and logs any traffic not matched by the rules above it, rather than dropping it.
