provider "yandex" {
  version   = "~> 0.35.0"
  token     = var.token
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = var.zone
}
