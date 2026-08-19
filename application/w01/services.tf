data "nsxt_policy_service" "https" {
  display_name = "HTTPS"
}

data "nsxt_policy_service" "http" {
  display_name = "HTTP"
}

data "nsxt_policy_service" "ssh" {
  display_name = "SSH"
}

data "nsxt_policy_service" "icmp_all" {
  display_name = "ICMP ALL"
}

data "nsxt_policy_service" "update_manager" {
  display_name = "Update Manager"
}

data "nsxt_policy_service" "udp_902" {
  display_name = "VMware-ESXi5.x-UDP"
}

data "nsxt_policy_service" "tcp_9087" {
  display_name = "Vmware-UpdateMgr-update"
}

data "nsxt_policy_service" "tcp_9084" {
  display_name = "VMware-UpdateMgr-VUM"
}
