provider "yandex" {
  version   = "~> 0.35.0"
  token     = var.token
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = var.zone
}

resource "yandex_vpc_network" "app-network" {
  name = "reddit-app-network"
}

resource "yandex_vpc_subnet" "app-subnet" {
  name           = "reddit-app-subnet"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.app-network.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

resource "yandex_compute_instance" "app" {
  count       = var.app_scale
  name        = "reddit-app-${count.index}-tf"
  platform_id = "standard-v2"

  metadata = {
    ssh-keys = "ubuntu:${file(var.public_key_path)}"
  }

  resources {
    cores         = 2
    core_fraction = 5
    memory        = 0.5
  }

  boot_disk {
    initialize_params {
      image_id = var.image_id
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.app-subnet.id
    nat = true
  }

  connection {
    type        = "ssh"
    host        = self.network_interface.0.nat_ip_address
    user        = "ubuntu"
    agent       = false
    private_key = file(var.private_key_path)
  }

  provisioner "file" {
    source      = "files/puma.service"
    destination = "/tmp/puma.service"
  }

  provisioner "remote-exec" {
    script = "files/deploy.sh"
  }

}
