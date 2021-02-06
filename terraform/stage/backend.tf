terraform {
  backend "s3" {
    endpoint   = "storage.yandexcloud.net"
    bucket     = "state-remote-backend"
    region     = "ru-central1"
    key        = "terraform.tfstate"
    access_key = "8h4SdiyJ8cJ9AgpYyiQO"
    secret_key = "PS0efcgSWdfcofu9BA8xR7Y-YmrNp6WFW5dnvtlk"

    skip_region_validation      = true
    skip_credentials_validation = true
  }
}
