resource "google_compute_global_address" "rethinkdb_lb_ipv4_1" {
  name       = "rethinkdb-lb-ipv4-1"
  ip_version = "IPV4"
}

resource "google_compute_health_check" "rethinkdb_health_check" {
  name               = "rethinkdb-lb-health-check"
  check_interval_sec = 10
  healthy_threshold  = 2
  http_health_check {
    port               = 8080
    port_specification = "USE_FIXED_PORT"
    proxy_header       = "NONE"
    request_path       = "/"
  }
  timeout_sec         = 5
  unhealthy_threshold = 2
}

resource "google_compute_backend_service" "rethinkdb_backend_service" {
  name             = "rethinkdb-backend-service"
  health_checks    = [google_compute_health_check.rethinkdb_health_check.id]
  protocol         = "HTTP"
  session_affinity = "NONE"
  timeout_sec      = 30
  backend {
    group = google_compute_instance_group_manager.rethinkdb_instance_group.instance_group
  }

}

resource "google_compute_url_map" "rethinkdb_compute_url_map" {
  name            = "rethinkdb-map-http"
  default_service = google_compute_backend_service.rethinkdb_backend_service.id
}

resource "google_compute_target_http_proxy" "rethinkdb_http_lb_proxy" {
  name    = "rethinkdb-https-lb-proxy"
  url_map = google_compute_url_map.rethinkdb_compute_url_map.id
}

resource "google_compute_global_forwarding_rule" "rethinkdb_forwarding_rule" {
  name       = "rethinkdb-forwarding-rule"
  target     = google_compute_target_http_proxy.rethinkdb_http_lb_proxy.id
  port_range = "8080"
  ip_address = google_compute_global_address.rethinkdb_lb_ipv4_1.id
}
