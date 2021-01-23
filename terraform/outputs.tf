output "external_ip_address_app" {
  value = yandex_compute_instance.app.*.network_interface.0.nat_ip_address
}
output "external_ip_address_lb" {
  value = yandex_lb_network_load_balancer.lb-reddit.listener.*.external_address_spec[0][0].address
}
output "lb_external_port" {
  value = yandex_lb_network_load_balancer.lb-reddit.listener.*.port
}
