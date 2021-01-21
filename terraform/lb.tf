resource "yandex_lb_target_group" "tgtgrp-reddit" {
  name      = "tgtgrp-reddit"
  region_id = "ru-central1"

  target {
    subnet_id = yandex_compute_instance.app.network_interface.0.subnet_id
    address   = yandex_compute_instance.app.network_interface.0.ip_address
  }
  target {
    subnet_id = yandex_compute_instance.app2.network_interface.0.subnet_id
    address   = yandex_compute_instance.app2.network_interface.0.ip_address
  }

}

resource "yandex_lb_network_load_balancer" "lb-reddit" {
  name = "my-network-load-balancer"

  listener {
    name = "my-listener"
    port = 2929
    target_port = 9292
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_lb_target_group.tgtgrp-reddit.id

    healthcheck {
      name = "http"
      http_options {
        port = 9292
        path = "/"
      }
    }
  }
}
