
provider "google" {
  project = var.project_id
  region  = var.region
}

// VM Instance
resource "google_compute_instance_template" "rethinkdb_instance_template" {
  name         = "rethinkdb-instance-template"
  machine_type = "e2-standard-2" // TODO: decide on machine_type
  project      = var.project_id


  disk {
    source_image = "ubuntu-os-cloud/ubuntu-2204-lts"
    boot         = true
  }

  disk {
    source = google_compute_disk.rethinkdb_storage.name
    mode   = "READ_WRITE"
  }

  network_interface {
    network    = google_compute_network.rethinkdb_network.self_link
    subnetwork = google_compute_subnetwork.rethinkdb_subnet.self_link
  }

}

resource "google_compute_instance_group_manager" "rethinkdb_instance_group" {
  name               = "rethinkdb-instance-group"
  base_instance_name = "rethinkdb-vm"
  zone               = var.zone

  named_port {
    name = "http"
    port = 8080
  }

  version {
    instance_template = google_compute_instance_template.rethinkdb_instance_template.id
    name              = "primary"
  }

  target_size = 1
}
