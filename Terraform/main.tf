provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_compute_disk" "rethinkdb_storage" {
  name = "rethinkdb-storage"
  type = "pd-ssd"
  size = var.disk_size
  zone = var.zone

  lifecycle {
    prevent_destroy = true
  }
}

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

// Static IP Address
resource "google_compute_address" "rethinkdb_static_ip" {
  name         = "rethinkdb-static-ip"
  project      = var.project_id
  region       = var.region
  address_type = "INTERNAL"
  subnetwork   = google_compute_subnetwork.rethinkdb_subnet.self_link
}


// VM Instance
resource "google_compute_instance" "rethinkdb_instance" {
  name         = "rethinkdb-vm"
  machine_type = "e2-standard-2" // TODO: decide on machine_type
  zone         = var.zone
  project      = var.project_id

  boot_disk {
    initialize_params {
      image = "cos-cloud/cos-stable"
      size  = var.boot_disk_size
    }
  }

  attached_disk {
    source = google_compute_disk.rethinkdb_storage.self_link
    mode   = "READ_WRITE"
  }

  network_interface {
    network    = google_compute_network.rethinkdb_network.self_link
    subnetwork = google_compute_subnetwork.rethinkdb_subnet.self_link
  }

  depends_on = [google_compute_address.rethinkdb_static_ip]

}

// storage bucket
resource "google_storage_bucket" "rethinkdb_backup_bucket" {
  name                        = "rethinkdb-backups"
  project                     = var.project_id
  location                    = var.region
  uniform_bucket_level_access = true
}

resource "google_service_account" "rethinkdb_admin_service_account" {
  account_id   = "rethinkdb-admin"
  display_name = "RethinkDB Storage Admin Service Account"
  project      = var.project_id
}

resource "google_storage_bucket_iam_binding" "rethinkdb_bucket_iam_binding" {
  bucket = google_storage_bucket.rethinkdb_backup_bucket.name
  role   = "roles/storage.objectAdmin"

  members = [
    "serviceAccount:${google_service_account.rethinkdb_admin_service_account.email}",
  ]
}

resource "google_service_account" "rethink_vm_service_account" {
  account_id   = "rethinkdb-vm-admin"
  display_name = "RethinkDB VM Service Account"
  project      = var.project_id
}

resource "google_project_iam_member" "compute_admin" {
  project = var.project_id
  role    = "roles/compute.admin"
  member  = "serviceAccount:${google_service_account.rethink_vm_service_account.email}"
}