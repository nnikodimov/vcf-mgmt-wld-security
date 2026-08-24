variable "dns_server" {
  type        = string
  description = "DNS server IP address"
}

variable "ntp_server" {
  type        = string
  description = "NTP server IP address"
}

variable "dhcp_server" {
  type        = string
  description = "DHCP server IP address"
}

variable "ad_server" {
  type        = string
  description = "Active Directory server IP address"
}

variable "vcf_f_path" {
  type        = string
  description = "Policy path of the VCF_FLEET group, provided by the environment module"
}

variable "vcf_ops_logs_path" {
  type        = string
  description = "Policy path of the VCF_OPS_LOGS group, provided by the environment module"
}

variable "tcp_9543_path" {
  type        = string
  description = "Policy path of the TCP-9543 (Aria Suite LCM) service, provided by the environment module"
}
