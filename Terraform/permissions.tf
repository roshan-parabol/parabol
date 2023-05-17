

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
