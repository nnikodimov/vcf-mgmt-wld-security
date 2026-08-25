resource "nsxt_policy_security_policy" "w01_vc_policy" {
  display_name    = "Workload Domain 01 vCenter Policy"
  description     = "Workload Domain 01 vCenter Policy"
  category        = "Application"
  locked          = false
  stateful        = true
  tcp_strict      = true
  scope           = [var.group_paths["w01_vc"]]
  sequence_number = 9

  rule {
    display_name       = "vCenter to Hosts"
    source_groups      = [var.group_paths["w01_vc"]]
    destination_groups = [var.group_paths["w01_hosts"]]
    services           = [data.nsxt_policy_service.update_manager.path, data.nsxt_policy_service.icmp_all.path, var.service_paths["tcp_1443"]]
    action             = "ALLOW"
    logged             = false
  }

  rule {
    display_name       = "Hosts to vCenter"
    source_groups      = [var.group_paths["w01_hosts"]]
    destination_groups = [var.group_paths["w01_vc"]]
    services           = [data.nsxt_policy_service.https.path, data.nsxt_policy_service.tcp_9087.path, data.nsxt_policy_service.tcp_9084.path, data.nsxt_policy_service.udp_902.path, var.service_paths["tcp_6500"], var.service_paths["tcp_6501_6502"], var.service_paths["tcp_7475_7476"]]
    action             = "ALLOW"
    logged             = false
  }

  rule {
    display_name       = "vCenter to NSX"
    source_groups      = [var.group_paths["w01_vc"]]
    destination_groups = [var.group_paths["w01_nsx"]]
    services           = [data.nsxt_policy_service.https.path]
    action             = "ALLOW"
    logged             = false
  }

  rule {
    display_name       = "NSX to vCenter"
    source_groups      = [var.group_paths["w01_nsx"]]
    destination_groups = [var.group_paths["w01_vc"]]
    services           = [data.nsxt_policy_service.https.path, data.nsxt_policy_service.http.path, data.nsxt_policy_service.tcp_9087.path]
    action             = "ALLOW"
    logged             = false
  }

  # SSPI and SSPs to vCenter rule intentionally omitted: the workload domain 01
  # SSP groups (w01_sspi/w01_ssp) are not deployed, so they are not exposed by
  # the environment module's group_paths map. See "Workload Domain 01 SSP
  # Policy" below for the rest of the disabled SSP ruleset.

  rule {
    display_name       = "Avi to VCF01 Workload Domain 01"
    source_groups      = [var.group_paths["w01_avi"]]
    destination_groups = [var.group_paths["w01_vc"]]
    services           = [data.nsxt_policy_service.https.path]
    action             = "ALLOW"
    logged             = false
  }

  rule {
    display_name       = "vCenter to Supervisor"
    source_groups      = [var.group_paths["w01_vc"]]
    destination_groups = [var.group_paths["w01_sup01"]]
    services           = [var.service_paths["tcp_6443"]]
    action             = "ALLOW"
    logged             = false
  }

  rule {
    display_name       = "Supervisor to vCenter"
    source_groups      = [var.group_paths["w01_sup01"]]
    destination_groups = [var.group_paths["w01_vc"]]
    services           = [data.nsxt_policy_service.https.path]
    action             = "ALLOW"
    logged             = false
  }

  rule {
    display_name       = "vCenter Lock Down"
    scope              = [var.group_paths["w01_vc"]]
    action             = "ALLOW"
    logged             = true
    log_label          = "w01_vc"
  }
}

resource "nsxt_policy_security_policy" "w01_nsx_policy" {
  display_name    = "Workload Domain 01 NSX Policy"
  description     = "Workload Domain 01 NSX Policy"
  category        = "Application"
  locked          = false
  stateful        = true
  tcp_strict      = true
  scope           = [var.group_paths["w01_nsx"]]
  sequence_number = 10

  rule {
    display_name       = "NSX Messaging"
    source_groups      = [var.group_paths["w01_nsx"], var.group_paths["w01_hosts"], var.group_paths["w01_edges"]]
    destination_groups = [var.group_paths["w01_nsx"], var.group_paths["w01_hosts"], var.group_paths["w01_edges"]]
    services           = [var.service_paths["tcp_1234_1235"], var.service_paths["tcp_5671"]]
    action             = "ALLOW"
    scope              = [var.group_paths["w01_nsx"]]
    logged             = false
  }

  rule {
    display_name       = "vCenter to NSX"
    source_groups      = [var.group_paths["w01_vc"]]
    destination_groups = [var.group_paths["w01_nsx"]]
    services           = [data.nsxt_policy_service.https.path]
    action             = "ALLOW"
    logged             = false
  }

  rule {
    display_name       = "NSX to vCenter"
    source_groups      = [var.group_paths["w01_nsx"]]
    destination_groups = [var.group_paths["w01_vc"]]
    services           = [data.nsxt_policy_service.https.path, data.nsxt_policy_service.http.path, data.nsxt_policy_service.tcp_9087.path]
    action             = "ALLOW"
    logged             = false
  }

  rule {
    display_name       = "NSX Manager Cluster"
    source_groups      = [var.group_paths["w01_nsx"]]
    destination_groups = [var.group_paths["w01_nsx"]]
    services           = [var.service_paths["tcp_9000"], var.service_paths["tcp_9040"], data.nsxt_policy_service.icmp_all.path]
    action             = "ALLOW"
    logged             = false
  }

  rule {
    display_name       = "Avi to VCF01 Workload Domain 01 NSX"
    source_groups      = [var.group_paths["w01_avi"]]
    destination_groups = [var.group_paths["w01_nsx"]]
    services           = [data.nsxt_policy_service.https.path]
    action             = "ALLOW"
    logged             = false
  }

  rule {
    display_name       = "Supervisor to NSX"
    source_groups      = [var.group_paths["w01_sup01"]]
    destination_groups = [var.group_paths["w01_nsx"]]
    services           = [data.nsxt_policy_service.https.path]
    action             = "ALLOW"
    logged             = false
  }

  rule {
    display_name       = "NSX Lock Down"
    action             = "ALLOW"
    logged             = true
    log_label          = "w01_nsx"
  }
}

resource "nsxt_policy_security_policy" "w01_avi_policy" {
  display_name    = "Workload Domain 01 Avi Policy"
  description     = "Workload Domain 01 Avi Policy"
  category        = "Application"
  locked          = false
  stateful        = true
  tcp_strict      = true
  scope           = [var.group_paths["w01_avi"], var.group_paths["w01_avi_se"]]
  sequence_number = 11

  rule {
    display_name       = "Avi to VCF01 Workload Domain 01"
    source_groups      = [var.group_paths["w01_avi"]]
    destination_groups = [var.group_paths["w01_vc"], var.group_paths["w01_nsx"], var.group_paths["w01_hosts"]]
    services           = [data.nsxt_policy_service.https.path]
    action             = "ALLOW"
    logged             = false
  }

  rule {
    display_name       = "Avi to SE Management"
    source_groups      = [var.group_paths["w01_avi"]]
    destination_groups = [var.group_paths["w01_avi_se"]]
    services           = [var.service_paths["tcp_8443"]]
    action             = "ALLOW"
    logged             = false
  }

  rule {
    display_name       = "SE Management to Avi"
    source_groups      = [var.group_paths["w01_avi_se"]]
    destination_groups = [var.group_paths["w01_avi"]]
    services           = [data.nsxt_policy_service.ssh.path, var.service_paths["tcp_8443"]]
    action             = "ALLOW"
    scope              = [var.group_paths["w01_avi"], var.group_paths["w01_avi_se"]]
    logged             = false
  }

  rule {
    display_name       = "Avi Lock Down"
    scope              = [var.group_paths["w01_avi"]]
    action             = "ALLOW"
    logged             = true
    log_label          = "w01_avi"
  }
}

# Workload Domain 01 SSP Policy - disabled.
#
# The w01_sspi, w01_ssp and w01_sspm groups are commented out in
# environment/groups-vcf01_w01.tf because SSP is not yet deployed on
# workload domain 01, so they are not exposed via the environment module's
# group_paths output. Uncomment those groups in the environment module and
# this policy together once SSP is deployed here.
#
# resource "nsxt_policy_security_policy" "w01_ssp_policy" {
#   display_name = "Workload Domain 01 SSP Policy"
#   description  = "Workload Domain 01 SSP Policy"
#   category     = "Application"
#   locked       = false
#   stateful     = true
#   tcp_strict   = true
#   scope              = [var.group_paths["w01_sspi"],var.group_paths["w01_ssp"]]
#   sequence_number = 12
#
#   rule {
#     display_name       = "SSPI and SSPs to vCenter"
#     source_groups      = [var.group_paths["w01_sspi"],var.group_paths["w01_ssp"]]
#     destination_groups = [var.group_paths["w01_vc"]]
#     services           = [data.nsxt_policy_service.https.path]
#     action             = "ALLOW"
#     logged             = false
#   }
#
#   rule {
#     display_name       = "SSP to NSX Manager"
#     source_groups      = [var.group_paths["w01_ssp"]]
#     destination_groups = [var.group_paths["w01_nsx"]]
#     services           = [data.nsxt_policy_service.https.path]
#     action             = "ALLOW"
#     logged             = false
#   }
#
#   rule {
#     display_name       = "SSPI to SSP"
#     source_groups      = [var.group_paths["w01_sspi"]]
#     destination_groups = [var.group_paths["w01_ssp"]]
#     services           = [var.service_paths["tcp_6443"],data.nsxt_policy_service.https.path]
#     action             = "ALLOW"
#     logged             = false
#   }
#
#   rule {
#     display_name       = "SSP to SSPI Registry"
#     source_groups      = [var.group_paths["w01_ssp"]]
#     destination_groups = [var.group_paths["w01_sspi"]]
#     services           = [data.nsxt_policy_service.https.path]
#     action             = "ALLOW"
#     logged             = false
#   }
#
#   rule {
#     display_name       = "SSP Ingestion"
#     source_groups      = [var.group_paths["w01_nsx"],var.group_paths["w01_hosts"],var.group_paths["w01_edges"]]
#     destination_groups = [var.group_paths["w01_sspm"]]
#     services           = [data.nsxt_policy_service.https.path,var.service_paths["tcp_9092"]]
#     action             = "ALLOW"
#     logged             = false
#   }
#
#   rule {
#     display_name       = "SSP Feeds"
#     source_groups      = [var.group_paths["w01_ssp"]]
#     services           = [data.nsxt_policy_service.https.path]
#     action             = "ALLOW"
#     logged             = false
#   }
#
#   rule {
#     display_name       = "SSP to SIEM Server"
#     source_groups      = [var.group_paths["w01_ssp"]]
#     destination_groups = [var.group_paths["siem_svc"]]
#     services           = [data.nsxt_policy_service.https.path]
#     action             = "ALLOW"
#     logged             = false
#   }
#
#   rule {
#     display_name       = "SSP Internal"
#     source_groups      = [var.group_paths["w01_ssp"]]
#     destination_groups = [var.group_paths["w01_ssp"]]
#     action             = "ALLOW"
#     logged             = false
#   }
#
#   rule {
#     display_name       = "Workload Domain 01 SSP Lock Down"
#     action             = "ALLOW"
#     logged             = true
#     log_label          = "w01_ssp"
#   }
# }
