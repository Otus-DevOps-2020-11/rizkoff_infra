provider "yandex" {
  version   = "~> 0.35.0"
  token     = var.token
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = var.zone
}

module "app" {
  source          = "./modules/app"
  public_key_path = var.public_key_path
  app_disk_image  = var.app_disk_image
  subnet_id = yandex_vpc_subnet.app-subnet.id
  db_nat_ip_address = module.db.internal_ip_address_db
}

module "db" {
  source          = "./modules/db"
  public_key_path = var.public_key_path
  db_disk_image   = var.db_disk_image
  subnet_id = yandex_vpc_subnet.app-subnet.id
}
