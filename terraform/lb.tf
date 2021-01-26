resource "yandex_lb_target_group" "tgtgrp-reddit" {
  name      = "tgtgrp-reddit"
  region_id = var.lb_target_group_region_id

  dynamic target {
    for_each = yandex_compute_instance.app.*.network_interface.0.ip_address
    content {
      subnet_id = var.subnet_id
      address   = target.value
    }
  }
}

resource "yandex_lb_network_load_balancer" "lb-reddit" {
  name = "my-network-load-balancer"

  listener {
    name        = "my-listener"
    port        = var.lb_external_port
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
