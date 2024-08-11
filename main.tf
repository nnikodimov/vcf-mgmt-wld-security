# Terrafrom Initialization
terraform {
  required_providers {
    nsxt = {
      source = "vmware/nsxt"
      version = "3.6.2"
    }
  }
}

provider "nsxt" {
  host                  = "m01-nsx01.sfo.ans.lab"
  username              = "admin"
  password              = "VMware123!VMware123!"
  allow_unverified_ssl  = true
  max_retries           = 10
  retry_min_delay       = 500
  retry_max_delay       = 5000
  retry_on_status_codes = [429]
}
