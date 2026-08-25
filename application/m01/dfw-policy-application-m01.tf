resource "nsxt_policy_security_policy" "m01_vc_policy" {
  display_name = "Menagement Domain vCenter Policy"
  description  = "Menagement Domain vCenter Policy"
  category     = "Application"
  locked       = false
  stateful     = true
  tcp_strict   = true
  scope        = [var.group_paths["m01_vc"]]
  sequence_number = 5

  rule {
    display_name       = "vCenter to Hosts"
    source_groups      = [var.group_paths["m01_vc"]]
    destination_groups = [var.group_paths["m01_hosts"]]
    services           = [data.nsxt_policy_service.update_manager.path,data.nsxt_policy_service.icmp_all.path,var.service_paths["tcp_1443"]]
    action             = "ALLOW"
    logged             = false
  }

  rule {
    display_name       = "Hosts to vCenter"
    source_groups      = [var.group_paths["m01_hosts"]]
    destination_groups = [var.group_paths["m01_vc"]]
    services           = [data.nsxt_policy_service.https.path,data.nsxt_policy_service.tcp_9087.path,data.nsxt_policy_service.tcp_9084.path,data.nsxt_policy_service.udp_902.path,var.service_paths["tcp_6500"],var.service_paths["tcp_6501_6502"],var.service_paths["tcp_7475_7476"]]
    action             = "ALLOW"
    logged             = false
  }

  rule {
    display_name       = "vCenter to NSX"
    source_groups      = [var.group_paths["m01_vc"]]
    destination_groups = [var.group_paths["m01_nsx"]]
    services           = [data.nsxt_policy_service.https.path]
    action             = "ALLOW"
    logged             = false
  }

  rule {
    display_name       = "NSX to vCenter"
    source_groups      = [var.group_paths["m01_nsx"]]
    destination_groups = [var.group_paths["m01_vc"]]
    services           = [data.nsxt_policy_service.https.path,data.nsxt_policy_service.http.path,data.nsxt_policy_service.tcp_9087.path]
    action             = "ALLOW"
    logged             = false
  }

  rule {
    display_name       = "SSPI and SSPs to vCenter"
    source_groups      = [var.group_paths["vcf01_sspi"],var.group_paths["m01_ssp"]]
    destination_groups = [var.group_paths["m01_vc"]]
    services           = [data.nsxt_policy_service.https.path]
    action             = "ALLOW"
    logged             = false
  }

  rule {
    display_name       = "Avi to VCF01 Management domain"
    source_groups      = [var.group_paths["m01_avi"]]
    destination_groups = [var.group_paths["m01_vc"]]
    services           = [data.nsxt_policy_service.https.path]
    action             = "ALLOW"
    logged             = false
  }

  rule {
    display_name       = "vCenter Lock Down"
    scope              = [var.group_paths["m01_vc"]]
    action             = "ALLOW"
    logged             = true
    log_label          = "m01_vc"
  }
}

resource "nsxt_policy_security_policy" "m01_avi_policy" {
  display_name = "Management Domain Avi Policy"
  description  = "Management Domain Avi Policy"
  category     = "Application"
  locked       = false
  stateful     = true
  tcp_strict   = true
  scope        = [var.group_paths["m01_avi"]]
  sequence_number = 6

  rule {
    display_name       = "Avi controller cluster"
    source_groups      = [var.group_paths["m01_avi"]]
    destination_groups = [var.group_paths["m01_avi"]]
    action             = "ALLOW"
    logged             = false
  }

  rule {
    display_name       = "Avi to VCF01 Management domain"
    source_groups      = [var.group_paths["m01_avi"]]
    destination_groups = [var.group_paths["m01_vc"],var.group_paths["m01_nsx"],var.group_paths["m01_hosts"]]
    services           = [data.nsxt_policy_service.https.path]
    action             = "ALLOW"
    logged             = false
  }

  rule {
    display_name       = "Avi to/from SE Management"
    source_groups      = [var.group_paths["m01_avi"],var.group_paths["m01_avi_se"]]
    destination_groups = [var.group_paths["m01_avi"],var.group_paths["m01_avi_se"]]
    services           = [data.nsxt_policy_service.ssh.path,var.service_paths["tcp_8443"]]
    action             = "ALLOW"
    logged             = false
  }

  rule {
    display_name       = "Avi Lock Down"
    action             = "ALLOW"
    logged             = true
    log_label          = "m01_avi"
  }
}

resource "nsxt_policy_security_policy" "m01_ssp_policy" {
  display_name = "Management Domain SSP Policy"
  description  = "Management Domain SSP Policy"
  category     = "Application"
  locked       = false
  stateful     = true
  tcp_strict   = true
  scope        = [var.group_paths["vcf01_sspi"],var.group_paths["m01_ssp"]]
  sequence_number = 7

  rule {
    display_name       = "SSPI and SSPs to vCenter"
    source_groups      = [var.group_paths["vcf01_sspi"],var.group_paths["m01_ssp"]]
    destination_groups = [var.group_paths["m01_vc"]]
    services           = [data.nsxt_policy_service.https.path]
    action             = "ALLOW"
    logged             = false
  }

  rule {
    display_name       = "SSP to NSX Manager"
    source_groups      = [var.group_paths["m01_ssp"]]
    destination_groups = [var.group_paths["m01_nsx"]]
    services           = [data.nsxt_policy_service.https.path]
    action             = "ALLOW"
    logged             = false
  }

  rule {
    display_name       = "SSPI to SSP"
    source_groups      = [var.group_paths["vcf01_sspi"]]
    destination_groups = [var.group_paths["m01_ssp"]]
    services           = [var.service_paths["tcp_6443"],data.nsxt_policy_service.https.path]
    action             = "ALLOW"
    logged             = false
  }

  rule {
    display_name       = "SSP to SSPI Registry"
    source_groups      = [var.group_paths["m01_ssp"]]
    destination_groups = [var.group_paths["vcf01_sspi"]]
    services           = [data.nsxt_policy_service.https.path]
    action             = "ALLOW"
    logged             = false
  }

  rule {
    display_name       = "SSP Ingestion"
    source_groups      = [var.group_paths["m01_nsx"],var.group_paths["m01_hosts"],var.group_paths["m01_edges"]]
    destination_groups = [var.group_paths["m01_sspm"]]
    services           = [data.nsxt_policy_service.https.path,var.service_paths["tcp_9092"]]
    action             = "ALLOW"
    logged             = false
  }

  rule {
    display_name       = "SSP Feeds"
    source_groups      = [var.group_paths["m01_ssp"]]
    services           = [data.nsxt_policy_service.https.path]
    action             = "ALLOW"
    logged             = false
  }

  rule {
    display_name       = "SSP Internal"
    source_groups      = [var.group_paths["m01_ssp"]]
    destination_groups = [var.group_paths["m01_ssp"]]
    action             = "ALLOW"
    logged             = false
  }

  rule {
    display_name       = "Management Domain SSP Lock Down"
    action             = "ALLOW"
    logged             = true
    log_label          = "m01_ssp"
  }
}
