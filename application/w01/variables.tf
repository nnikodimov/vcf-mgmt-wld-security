variable "group_paths" {
  type        = map(string)
  description = "Map of NSX group names to policy path, provided by the environment module"
}

variable "service_paths" {
  type        = map(string)
  description = "Map of custom NSX service names to policy path, provided by the environment module"
}
