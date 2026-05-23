resource "google_sql_database_instance" "main" {
  database_version = var.database_version
  name             = var.cloud_sql_instance_name
  project          = var.project_id
  region           = var.region

  settings {
    user_labels = var.instance_labels
    tier        = var.instance_tier

    ip_configuration {
      ipv4_enabled       = false
      private_network    = var.vpc_self_link
      allocated_ip_range = var.psa_name
    }

    backup_configuration {
      enabled            = true
      binary_log_enabled = false
      start_time         = "23:00"
    }

    disk_autoresize = true
    disk_size       = 20
    disk_type       = "PD_SSD"
  }

  deletion_protection = false

  lifecycle {
    ignore_changes = [
      settings[0].maintenance_window,
      settings[0].disk_size
    ]
  }
}

resource "google_sql_database" "database" {
  project         = var.project_id
  name            = var.database_name
  instance        = google_sql_database_instance.main.name
  deletion_policy = "ABANDON"
}

resource "google_sql_user" "iam_user" {
  name     = var.username
  instance = google_sql_database_instance.main.name
  project  = var.project_id
  password = var.password.secret_data

  deletion_policy = "ABANDON"
}
