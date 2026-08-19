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

The configuration is split into a root module and per-category/per-domain child modules, so that each can be planned/applied independently with `-target=module.<name>`:

```
.
├── main.tf                  # Provider configuration and module wiring
├── variables.tf              # Input variable declarations (all modules' inputs)
├── terraform.tfvars          # Variable values (copy and edit before use)
├── infrastructure/           # DFW "Infrastructure" category module
├── environment/              # DFW "Environment" category module
└── application/               # DFW "Application" category modules
    ├── fm/                    #   VCF Fleet Management application policies
    ├── m01/                   #   Management domain (m01) application policies
    └── w01/                   #   Workload domain 01 (w01) application policies
```

| Module | File | Description |
|--------|------|-------------|
| root | `main.tf` | Terraform provider configuration and `module` blocks for `infrastructure`, `environment`, and the three `application` modules |
| root | `variables.tf` | Input variable declarations |
| root | `terraform.tfvars` | Variable values (copy and edit before use) |
| `infrastructure` | `groups.tf` | NSX groups for the core infrastructure services (DNS, NTP, DHCP, AD) |
| `infrastructure` | `services.tf` | NSX service and context profile definitions used by the Infrastructure policy |
| `infrastructure` | `dfw-policy-infrastructure.tf` | DFW Infrastructure category policy |
| `infrastructure` | `variables.tf` / `versions.tf` | Module inputs (including the VCF Fleet group path from `environment`) and provider requirements |
| `environment` | `groups-vcf_ext.tf` | NSX groups for external services used by Environment policies (bastion, tools, backup, SMTP, SIEM) |
| `environment` | `groups-vcf_fm.tf` | NSX groups for VCF Fleet Management components |
| `environment` | `groups-vcf01_m01.tf` | NSX groups for management domain (m01) components |
| `environment` | `groups-vcf01_w01.tf` | NSX groups for workload domain 01 (w01) components |
| `environment` | `services.tf` | NSX service and context profile definitions used by Environment policies |
| `environment` | `dfw-policy-environment.tf` | DFW Environment category policies |
| `environment` | `variables.tf` / `outputs.tf` / `versions.tf` | Module inputs, `group_paths`/`service_paths` maps (and the individual `vcf_f_path`/`vcf_ops_logs_path` outputs) consumed by the other modules, and provider requirements |
| `application/fm` | `dfw-policy-application-fm.tf` | Application policies for VCF Operations, VCF Operations for Logs, VCF Operations for Networks, and VCF Automation |
| `application/m01` | `dfw-policy-application-m01.tf` | Application policies for the management domain's vCenter, Avi, and SSP components |
| `application/w01` | `dfw-policy-application-w01.tf` | Application policies for workload domain 01's vCenter, NSX, and Avi components |
| `application/*` | `variables.tf` / `versions.tf` | Module inputs (`group_paths`, `service_paths`) and provider requirements |
| `application/*` | `services.tf` | Local re-declarations of the shared NSX service data sources each module's rules use |

None of the `application`, `infrastructure`, or `environment` modules define their own NSX groups or custom services beyond what they own: `infrastructure` and `environment` create the groups/services referenced by their own policies, and `environment` exposes all of its group paths and custom service paths via the `group_paths` and `service_paths` outputs so the `application` modules (and `infrastructure`, for the VCF Fleet/Ops Logs groups) can reference them without re-declaring the underlying NSX resources. This keeps each NSX group and custom service defined exactly once.

**Dependencies and apply order.** `infrastructure` and all three `application` modules read groups and services from `environment`, so `environment` must exist before they can be applied — always run modules in this order: **1. `infrastructure`, 2. `environment`, 3. `application`.** In practice this is safe even though `infrastructure` is applied first: because it depends on `environment`'s outputs, `terraform apply -target=module.infrastructure` automatically creates the subset of `environment` it needs first. Running `-target=module.environment` next fills in the rest of the environment resources, and the `application` modules can then apply cleanly against the complete `environment` state.

**Workload domain 01 SSP.** The `w01_sspi`, `w01_ssp`, and `w01_sspm` groups in `environment/groups-vcf01_w01.tf` are commented out (SSP is not yet deployed on workload domain 01), so they are omitted from `group_paths`. The corresponding "Workload Domain 01 SSP Policy" in `application/w01/dfw-policy-application-w01.tf` is commented out to match — uncomment both together once SSP is deployed there. The management domain equivalent (`m01_sspi`/`m01_ssp`/`m01_sspm` and the "Management Domain SSP Policy" in `application/m01`) is active.

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

To apply just one module, target it directly. Follow the dependency order described above — `infrastructure`, then `environment`, then the `application` modules — even though targeting `infrastructure` first will transparently pull in the `environment` resources it depends on:

```bash
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
| Infrastructure | VCF Infrastructure Policy | Allows DNS, NTP, DHCP, AD, and syslog traffic; drops anything else |
| Environment | VCF Fleet Environment | Controls inbound access and outbound backup/mail/depot traffic for the full VCF fleet |
| Environment | VCF Fleet Management Environment | Controls traffic between fleet management tools and VCF domains |
| Environment | VCF01 Management Domain Environment | Intra-domain rules and a default deny for the management domain |
| Environment | VCF01 Workload Domain 01 Environment | Intra-domain rules and a default deny for workload domain 01 |
| Application | VCF Operations / Operations for Logs / Operations for Networks / Automation Policies | Component-level rules and a default deny for VCF Fleet Management applications |
| Application | Management Domain vCenter / Avi / SSP Policies | Component-level rules and a default deny for management domain (m01) applications |
| Application | Workload Domain 01 vCenter / NSX / Avi Policies | Component-level rules and a default deny for workload domain 01 (w01) applications (SSP policy present but disabled — see above) |

All policies use `tcp_strict = true` and `stateful = true`. Each policy ends with an explicit **Lock Down** (DROP + log) rule to enforce a default-deny posture.
