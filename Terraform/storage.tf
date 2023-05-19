// persistent disk
resource "google_compute_disk" "rethinkdb_storage" {
  name = "rethinkdb-storage"
  type = "pd-ssd"
  size = var.disk_size
  zone = var.zone

  lifecycle {
    prevent_destroy = true
  }
}

// storage bucket
resource "google_storage_bucket" "rethinkdb_backup_bucket" {
  name                        = "rethinkdb-backups"
  project                     = var.project_id
  location                    = var.region
  uniform_bucket_level_access = true
}
