
// VPC Network
resource "google_compute_network" "rethinkdb_network" {
  project                 = var.project_id
  name                    = "rethinkdb-network"
  auto_create_subnetworks = false
}

// Sub network
resource "google_compute_subnetwork" "rethinkdb_subnet" {
  name          = "rethinkdb-subnet"
  ip_cidr_range = "10.0.0.0/24"
  region        = var.region
  network       = google_compute_network.rethinkdb_network.self_link
}


// Create Cloud Router
resource "google_compute_router" "rethinkdb_router" {
  name    = "rethinkdb-router"
  network = google_compute_network.rethinkdb_network.self_link
  region  = var.region
}

// Create Cloud NAT
resource "google_compute_router_nat" "rethinkdb_nat" {
  name                               = "rethinkdb-nat"
  router                             = google_compute_router.rethinkdb_router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

// Static IP Address
resource "google_compute_address" "rethinkdb_static_ip" {
  name         = "rethinkdb-static-ip"
  project      = var.project_id
  region       = var.region
  address_type = "INTERNAL"
  subnetwork   = google_compute_subnetwork.rethinkdb_subnet.self_link
}
