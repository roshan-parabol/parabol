provider "google" {
  project = var.project_id
  region  = var.region
}

// TODO: decide on disk type and size
resource "google_compute_disk" "rethinkdb_storage" {
  name  = "rethinkdb-storage"
  type  = "pd-ssd" 
  size  = 10
  zone  = var.zone  
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
  }

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