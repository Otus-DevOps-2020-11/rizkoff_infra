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
variable app_scale {
  description = "app scaling factor for lb"
  default     = 1
}
variable app_disk_image {
  description = "Disk image for reddit app"
  default     = "reddit-app-base"
}
variable db_disk_image {
  description = "Disk image for reddit db"
  default     = "reddit-db-base"
}
variable db_nat_ip_address {
  description = "db vm ip address"
  default     = "N/A"
}
