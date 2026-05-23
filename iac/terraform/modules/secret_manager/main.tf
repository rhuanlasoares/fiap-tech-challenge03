resource "google_secret_manager_secret" "aws_access_key_id" {
  project   = var.project_id
  secret_id = var.aws_access_key_id["secret_id"]

  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }

  deletion_protection = false
}

resource "google_secret_manager_secret_version" "aws_access_key_id_version" {
  secret      = google_secret_manager_secret.aws_access_key_id.id
  secret_data = var.aws_access_key_id["secret_data"]
}

resource "google_secret_manager_secret" "aws_secret_access_key" {
  project   = var.project_id
  secret_id = var.aws_secret_access_key["secret_id"]

  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }

  deletion_protection = false
}

resource "google_secret_manager_secret_version" "aws_secret_access_key_version" {
  secret      = google_secret_manager_secret.aws_secret_access_key.id
  secret_data = var.aws_secret_access_key["secret_data"]
}

resource "google_secret_manager_secret" "aws_session_token" {
  project   = var.project_id
  secret_id = var.aws_session_token["secret_id"]

  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }

  deletion_protection = false
}

resource "google_secret_manager_secret_version" "aws_session_token_version" {
  secret      = google_secret_manager_secret.aws_session_token.id
  secret_data = var.aws_session_token["secret_data"]
}

resource "google_secret_manager_secret" "auth_password" {
  project   = var.project_id
  secret_id = var.auth_db_secret["secret_id"]

  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }

  deletion_protection = false
}

resource "google_secret_manager_secret_version" "auth_password_version" {
  secret      = google_secret_manager_secret.auth_password.id
  secret_data = var.auth_db_secret["secret_data"]
}

resource "google_secret_manager_secret" "flag_password" {
  project   = var.project_id
  secret_id = var.flag_db_secret["secret_id"]

  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }

  deletion_protection = false
}

resource "google_secret_manager_secret_version" "flag_password_version" {
  secret      = google_secret_manager_secret.flag_password.id
  secret_data = var.flag_db_secret["secret_data"]
}

resource "google_secret_manager_secret" "targeting_password" {
  project   = var.project_id
  secret_id = var.targeting_db_secret["secret_id"]

  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }

  deletion_protection = false
}

resource "google_secret_manager_secret_version" "targeting_password_version" {
  secret      = google_secret_manager_secret.targeting_password.id
  secret_data = var.targeting_db_secret["secret_data"]
}

resource "google_secret_manager_secret" "sm_personal_access_token_gh" {
  project   = var.project_id
  secret_id = var.sm_personal_access_token_gh["secret_id"]

  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }

  deletion_protection = false
}

resource "google_secret_manager_secret_version" "sm_personal_access_token_gh_version" {
  secret      = google_secret_manager_secret.sm_personal_access_token_gh.id
  secret_data = var.sm_personal_access_token_gh["secret_data"]
}

resource "google_secret_manager_secret" "sm_sqs_queue_url" {
  project   = var.project_id
  secret_id = var.sm_sqs_queue_url["secret_id"]

  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }

  deletion_protection = false
}

resource "google_secret_manager_secret_version" "sm_sqs_queue_url_version" {
  secret      = google_secret_manager_secret.sm_sqs_queue_url.id
  secret_data = var.sm_sqs_queue_url["secret_data"]
}