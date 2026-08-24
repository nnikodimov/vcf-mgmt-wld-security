# Terraform Initialization
terraform {
  required_providers {
    nsxt = {
      source = "vmware/nsxt"
    }
  }
}

provider "nsxt" {
  host                  = var.nsx_manager
  username              = var.nsx_username
  password              = var.nsx_password
  allow_unverified_ssl  = true
  max_retries           = 10
  retry_min_delay       = 500
  retry_max_delay       = 5000
  retry_on_status_codes = [429]
}

module "environment" {
  source = "./environment"

  smtp_server   = var.smtp_server
  bastion_host  = var.bastion_host
  tools_server  = var.tools_server
  backup_server = var.backup_server
  siem_server   = var.siem_server

  vcfops01      = var.vcfops01
  vcfmsvc       = var.vcfmsvc
  vcfops_logs   = var.vcfops_logs
  vcfops_net    = var.vcfops_net
  vcfa          = var.vcfa
  vcf_lic       = var.vcf_lic
  sddc          = var.sddc
  vcfops_cp     = var.vcfops_cp
  vcfops_net_cn = var.vcfops_net_cn

  m01_vcenter          = var.m01_vcenter
  m01_nsx_manager_a    = var.m01_nsx_manager_a
  m01_nsx_manager_b    = var.m01_nsx_manager_b
  m01_nsx_manager_c    = var.m01_nsx_manager_c
  m01_avi_controller_a = var.m01_avi_controller_a
  m01_avi_controller_b = var.m01_avi_controller_b
  m01_avi_controller_c = var.m01_avi_controller_c
  m01_edges            = var.m01_edges
  m01_hosts            = var.m01_hosts
  m01_sspi_vm          = var.m01_sspi_vm
  m01_sspm             = var.m01_sspm

  w01_vcenter          = var.w01_vcenter
  w01_nsx_manager_a    = var.w01_nsx_manager_a
  w01_nsx_manager_b    = var.w01_nsx_manager_b
  w01_nsx_manager_c    = var.w01_nsx_manager_c
  w01_avi_controller_a = var.w01_avi_controller_a
  w01_avi_controller_b = var.w01_avi_controller_b
  w01_avi_controller_c = var.w01_avi_controller_c
  w01_edges            = var.w01_edges
  w01_hosts            = var.w01_hosts
  w01_sspi_vm          = var.w01_sspi_vm
  w01_sspm             = var.w01_sspm
  w01_sup01            = var.w01_sup01

  vm_management_dvpg = var.vm_management_dvpg
}

module "infrastructure" {
  source = "./infrastructure"

  dns_server  = var.dns_server
  ntp_server  = var.ntp_server
  dhcp_server = var.dhcp_server
  ad_server   = var.ad_server

  vcf_f_path        = module.environment.vcf_f_path
  vcf_ops_logs_path = module.environment.vcf_ops_logs_path
  tcp_9543_path     = module.environment.service_paths["tcp_9543"]
}

module "application_fm" {
  source = "./application/fm"

  group_paths   = module.environment.group_paths
  service_paths = module.environment.service_paths
}

module "application_m01" {
  source = "./application/m01"

  group_paths   = module.environment.group_paths
  service_paths = module.environment.service_paths
}

module "application_w01" {
  source = "./application/w01"

  group_paths   = module.environment.group_paths
  service_paths = module.environment.service_paths
}
