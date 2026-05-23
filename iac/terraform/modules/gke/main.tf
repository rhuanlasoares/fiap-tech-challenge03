resource "google_container_cluster" "gke_actions" {
  name     = var.gke_cluster_name
  location = var.region
  project  = var.project_id

  resource_labels = var.gke_resource_labels

  initial_node_count = 2

  cluster_autoscaling {
    enabled = true
    resource_limits {
      resource_type = "cpu"
      maximum       = 20
    }
    resource_limits {
      resource_type = "memory"
      maximum       = 40
    }
    auto_provisioning_defaults {
      oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]
      service_account = var.sa_gke_member
      disk_size       = 30
      image_type      = "COS_CONTAINERD"
    }
    autoscaling_profile = "OPTIMIZE_UTILIZATION"
  }

  gateway_api_config {
    channel = "CHANNEL_STANDARD"
  }

  remove_default_node_pool = true
  deletion_protection      = false

  default_max_pods_per_node = 30

  network = var.vpc_self_link

  # master_authorized_networks_config {
  #   cidr_blocks {
  #     cidr_block = "128.201.0.177/32"
  #   }
  # }

  private_cluster_config {
    enable_private_nodes = true
    # enable_private_endpoint     = false
    private_endpoint_subnetwork = var.subnet_self_link
  }

  addons_config {
    horizontal_pod_autoscaling {
      disabled = false
    }
    http_load_balancing {
      disabled = false
    }
    gcp_filestore_csi_driver_config {
      enabled = false
    }
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = var.range_name_pods
    services_secondary_range_name = var.range_name_services
  }

  subnetwork = var.subnet_self_link

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  secret_manager_config {
    enabled = true
  }

  node_pool_defaults {
    node_config_defaults {
      gcfs_config {
        enabled = true
      }
    }
  }
}
