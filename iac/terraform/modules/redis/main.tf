resource "google_redis_instance" "instance" {
  project = var.project_id

  name               = var.name_redis
  region             = var.region
  tier               = var.tier_redis
  memory_size_gb     = var.memory_size_gb_redis
  authorized_network = var.vpc_self_link
  reserved_ip_range  = var.psa_name
  location_id        = var.zone
  connect_mode       = var.connect_mode_redis
}
