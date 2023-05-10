provider "google" {
  project = var.project_id
  region  = var.region
}

// VM Instance
resource "google_compute_instance" "rethinkdb_instance" {
  name         = "rethinkdb-vm"
  machine_type = "n1-standard-2" // TODO
  zone         = var.zone
  project      = var.project_id

  boot_disk {
    initialize_params {
      size = 10
    }
  }

  network_interface {
    network = "default"
  }

}

// load balancer - set create_load_balancer to True to setup load balancer
resource "google_compute_backend_service" "rethinkdb_backend_service" {
  count                           = var.create_load_balancer ? 1 : 0
  name                            = "rethinkdb-backend-service"
  project                         = var.project_id
  protocol                        = "TCP"
  timeout_sec                     = 10
  port_name                       = "rethinkdb"
  enable_cdn                      = false
  connection_draining_timeout_sec = 300

  backend {
    group = google_compute_instance.rethinkdb_instance.self_link
  }
}

resource "google_compute_health_check" "rethinkdb_health_check" {
  count              = var.create_load_balancer ? 1 : 0
  name               = "rethinkdb-health-check"
  check_interval_sec = 5
  timeout_sec        = 5
  tcp_health_check {
    port = 8080
  }
}

resource "google_compute_target_pool" "rethinkdb_target_pool" {
  count         = var.create_load_balancer ? 1 : 0
  name          = "rethinkdb-target-pool"
  region        = var.region
  project       = var.project_id
  instances     = [google_compute_instance.rethinkdb_instance.self_link]
  health_checks = [google_compute_health_check.rethinkdb_health_check[count.index].self_link]
}

resource "google_compute_forwarding_rule" "rethinkdb_forwarding_rule" {
  count      = var.create_load_balancer ? 1 : 0
  name       = "rethinkdb-forwarding-rule"
  region     = var.region
  project    = var.project_id
  target     = google_compute_target_pool.rethinkdb_target_pool[count.index].self_link
  port_range = "8080"
}

// storage bucket
resource "google_storage_bucket" "rethinkdb_backup_bucket" {
  name                        = "rethinkdb-backups"
  project                     = var.project_id
  location                    = var.region
  uniform_bucket_level_access = true
}

resource "google_service_account" "rethinkdb_service_account" {
  account_id   = "rethinkdb-admin"
  display_name = "RethinkDB Service Account"
  project      = var.project_id
}

resource "google_project_iam_member" "rethinkdb_service_account_permissions" {
  project = var.project_id
  role    = "roles/storage.objectAdmin"
  member  = "serviceAccount:${google_service_account.rethinkdb_service_account.email}"
}