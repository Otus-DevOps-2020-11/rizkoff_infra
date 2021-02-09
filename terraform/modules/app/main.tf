resource "yandex_compute_instance" "app" {
  name = "reddit-app"
  platform_id = "standard-v2"
  labels = {
    tags = "reddit-app"
  }

  resources {
    cores  = 2
    core_fraction = 5
    memory = 0.5
  }

  boot_disk {
    initialize_params {
      image_id = var.app_disk_image
    }
  }

  network_interface {
    subnet_id = var.subnet_id
    nat = true
  }

  metadata = {
  ssh-keys = "ubuntu:${file(var.public_key_path)}"
  }

  connection {
    type        = "ssh"
    host        = self.network_interface.0.nat_ip_address
    user        = "ubuntu"
    agent       = false
    private_key = file(var.private_key_path)
  }

  provisioner "file" {
    content     = templatefile("${path.module}/files/puma.service", { DB_NAT_IP_ADDRESS = var.db_nat_ip_address})
    destination = "/tmp/puma.service"
  }

  provisioner "remote-exec" {
    script = "${path.module}/files/deploy.sh"
  }


}
