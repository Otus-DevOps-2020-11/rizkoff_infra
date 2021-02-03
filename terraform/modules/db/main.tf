resource "yandex_compute_instance" "db" {
  name = "reddit-db"
  platform_id = "standard-v2"
  labels = {
    tags = "reddit-db"
  }

  resources {
    cores  = 2
    core_fraction = 5
    memory = 0.5
  }

  boot_disk {
    initialize_params {
      image_id = var.db_disk_image
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

  provisioner "remote-exec" {
    inline = [
      "sudo sed -i -r 's/bindIp: [0-9\\.]+/bindIp: ${self.network_interface.0.ip_address}/' /etc/mongod.conf",
      "sudo systemctl restart mongod"
    ]
  }


}
