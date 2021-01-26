variable token {
  description = "iam token"
}
variable cloud_id {
  description = "cloud id"
}
variable folder_id {
  description = "folder id"
}
variable zone {
  description = "zone"
  default     = "ru-central1-a"
}
variable public_key_path {
  description = "Path to the public key used for ssh access"
}
variable private_key_path {
  description = "Path to the private key used for ssh access"
}
variable image_id {
  description = "boot disk image id"
}
variable subnet_id {
  description = "subnet id"
}
variable app_scale {
  description = "app scaling factor for lb"
  default     = 1
}
variable lb_external_port {
  description = "app listening external lb port"
  default     = 9292
}
variable lb_target_group_region_id {
  description = "lb tgt grp region id"
  default     = "ru-central1"
}
