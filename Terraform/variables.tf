variable "project_id" {
  default = "parabol-bp-roshan-rathod"
}

variable "region" {
  default = "us-central1" // TODO 
}

variable "zone" {
  default = "us-central1-a" // TODO 
}

variable "disk_size" {
  default = "10"
}

variable "create_load_balancer" {
  description = "Flag to indicate whether to create the load balancer"
  default     = true
}