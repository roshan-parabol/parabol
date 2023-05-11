provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_compute_disk" "rethinkdb_storage" {
  name  = "rethinkdb-storage"
  type  = "pd-ssd" 
  size  = var.disk_size
  zone  = var.zone

  lifecycle {
    prevent_destroy = true
  }
}

// Static IP Address
resource "google_compute_address" "rethinkdb_static_ip" {
  name         = "rethinkdb-static-ip"
  project      = var.project_id
  region       = var.region
}

// VM Instance
resource "google_compute_instance" "rethinkdb_instance" {
  name         = "rethinkdb-vm"
  machine_type = "n1-standard-2" // TODO
  zone         = var.zone
  project      = var.project_id

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 20
    }
  }

  attached_disk {
    source = google_compute_disk.rethinkdb_storage.self_link
    mode   = "READ_WRITE"
  }

  network_interface {
    network = "default"
    
    access_config {
      nat_ip = google_compute_address.rethinkdb_static_ip.address
    }
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

resource "google_service_account" "rethinkdb_service_account" {
  account_id   = "rethinkdb-admin"
  display_name = "RethinkDB Storage Admin Service Account"
  project      = var.project_id
}

resource "google_storage_bucket_iam_binding" "rethinkdb_bucket_iam_binding" {
  bucket = google_storage_bucket.rethinkdb_backup_bucket.name
  role   = "roles/storage.objectAdmin"

  members = [
    "serviceAccount:${google_service_account.rethinkdb_service_account.email}",
  ]
}