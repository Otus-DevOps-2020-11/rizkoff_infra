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
