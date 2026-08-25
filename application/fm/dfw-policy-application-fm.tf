resource "nsxt_policy_security_policy" "vcfops_policy" {
  display_name = "VCF Operations Policy"
  description  = "VCF Operations Policy"
  category     = "Application"
  locked       = false
  stateful     = true
  tcp_strict   = true
  scope        = [var.group_paths["vcf_ops"],var.group_paths["vcf_ops_fm"],var.group_paths["vcf01_ops_cp"],var.group_paths["vcf01_sddc"]]
  sequence_number = 1

  rule {
    display_name       = "VCF Ops HTTPS"
    source_groups      = [var.group_paths["vcf_ops"],var.group_paths["vcf_ops_fm"],var.group_paths["vcf01_ops_cp"],var.group_paths["vcf01_sddc"]]
    destination_groups = [var.group_paths["vcf_ops"],var.group_paths["vcf_ops_fm"],var.group_paths["vcf01_ops_cp"],var.group_paths["vcf01_sddc"]]
    services           = [data.nsxt_policy_service.https.path]
    action             = "ALLOW"
    logged             = false
  }

  rule {
    display_name       = "VCF Ops to VCFA, VCFOPS_LOGS and VCFOPS_NET"
    source_groups      = [var.group_paths["vcf_ops"]]
    destination_groups = [var.group_paths["vcf_a"],var.group_paths["vcf_ops_logs"],var.group_paths["vcf_ops_net"]]
    services           = [data.nsxt_policy_service.https.path]
    action             = "ALLOW"
    logged             = false
  }

  rule {
    display_name       = "VCF Ops for Logs to  VCF Ops"
    source_groups      = [var.group_paths["vcf_ops_logs"]]
    destination_groups = [var.group_paths["vcf_ops"]]
    services           = [data.nsxt_policy_service.https.path]
    action             = "ALLOW"
    logged             = false
  }

  rule {
    display_name       = "VCF Ops Fleet Management to VCFA"
    source_groups      = [var.group_paths["vcf_ops_fm"]]
    destination_groups = [var.group_paths["vcf_a"]]
    services           = [data.nsxt_policy_service.https.path,data.nsxt_policy_service.ssh.path,var.service_paths["tcp_6443"],var.service_paths["tcp_30000_30005"]]
    action             = "ALLOW"
    logged             = false
  }

  rule {
    display_name       = "VCF Operations Lock Down"
    action             = "ALLOW"
    logged             = true
    log_label          = "vcf_ops"
  }
}

resource "nsxt_policy_security_policy" "vcfops_logs_policy" {
  display_name = "VCF Operations for Logs Policy"
  description  = "VCF Operations for Logs Policy"
  category     = "Application"
  locked       = false
  stateful     = true
  tcp_strict   = true
  scope        = [var.group_paths["vcf_ops_logs"]]
  sequence_number = 2

  rule {
    display_name       = "VCF Ops VCFOPS_LOGS"
    source_groups      = [var.group_paths["vcf_ops"],var.group_paths["vcf_ops_logs"]]
    destination_groups = [var.group_paths["vcf_ops"],var.group_paths["vcf_ops_logs"]]
    services           = [data.nsxt_policy_service.https.path]
    action             = "ALLOW"
    logged             = false
  }

  rule {
    display_name       = "VCF Operations for Logs Lock Down"
    action             = "ALLOW"
    logged             = true
    log_label          = "vcf_ops_logs"
  }
}

resource "nsxt_policy_security_policy" "vcfops_net_policy" {
  display_name = "VCF Operations for Networks Policy"
  description  = "VCF Operations for Networks Policy"
  category     = "Application"
  locked       = false
  stateful     = true
  tcp_strict   = true
  scope        = [var.group_paths["vcf01_ops_net_cn"],var.group_paths["vcf_ops_net"]]
  sequence_number = 3

  rule {
    display_name       = "VCF Ops to VCFA and VCFOPS_LOGS"
    source_groups      = [var.group_paths["vcf_ops"]]
    destination_groups = [var.group_paths["vcf_ops_net"]]
    services           = [data.nsxt_policy_service.https.path]
    action             = "ALLOW"
    logged             = false
  }

  rule {
    display_name       = "VCF Ops for Net Collector to VCF Ops for Net"
    source_groups      = [var.group_paths["vcf01_ops_net_cn"]]
    destination_groups = [var.group_paths["vcf_ops_net"]]
    services           = [data.nsxt_policy_service.https.path]
    action             = "ALLOW"
    logged             = false
  }

  rule {
    display_name       = "VCF Operations for Networks Lock Down"
    action             = "ALLOW"
    logged             = true
    log_label          = "vcf_ops_net"
  }
}

resource "nsxt_policy_security_policy" "vcfa_policy" {
  display_name = "VCF Automation Policy"
  description  = "VCF Automation Policy"
  category     = "Application"
  locked       = false
  stateful     = true
  tcp_strict   = true
  scope        = [var.group_paths["vcf_a"]]
  sequence_number = 4

  rule {
    display_name       = "VCF Ops to VCFA"
    source_groups      = [var.group_paths["vcf_ops"]]
    destination_groups = [var.group_paths["vcf_a"]]
    services           = [data.nsxt_policy_service.https.path]
    action             = "ALLOW"
    logged             = false
  }

  rule {
    display_name       = "VCF Ops Fleet Management to VCFA"
    source_groups      = [var.group_paths["vcf_ops_fm"]]
    destination_groups = [var.group_paths["vcf_a"]]
    services           = [data.nsxt_policy_service.https.path,data.nsxt_policy_service.ssh.path,var.service_paths["tcp_6443"],var.service_paths["tcp_30000_30005"]]
    action             = "ALLOW"
    logged             = false
  }

  rule {
    display_name       = "VCF Automation Cloud User Access"
    destination_groups = [var.group_paths["vcf_a_lb"]]
    services           = [data.nsxt_policy_service.https.path]
    profiles           = [data.nsxt_policy_context_profile.cxt_ssl.path]
    action             = "ALLOW"
    logged             = false
  }

  rule {
    display_name       = "VCF Automation Lock Down"
    action             = "ALLOW"
    logged             = true
    log_label          = "vcfa"
  }
}
