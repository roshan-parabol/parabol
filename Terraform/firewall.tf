
// Firewall Rule
// TODO rquired to connect locally, might not need it when we switch to pipelines deploy strategy
resource "google_compute_firewall" "iap_firewall" {
  name    = "iap-tcp-ingress"
  network = google_compute_network.rethinkdb_network.self_link

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"] //TODO update as required
}


// Firewall Rule for Load Balancer
resource "google_compute_firewall" "rethinkdb_firewall_health_check" {
  name          = "rethinkdb-firewall-health-check"
  direction     = "INGRESS"
  network       = google_compute_network.rethinkdb_network.self_link
  priority      = 1000
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]

  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }
}
