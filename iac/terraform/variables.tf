### General Variables
variable "project_id" {
  type        = string
  description = "The Project ID of the project where the resource will be created."
}

variable "project_number" {
  type        = string
  description = "The Project number of the project where the resource will be created."
}

variable "region" {
  type        = string
  description = "The region where the Subnetwork will be created."
}

variable "range_name_pods" {
  type        = string
  description = "The name of the secondary IP range for Pods."
}

variable "range_name_services" {
  type        = string
  description = "The name of the secondary IP range for Services."
}

variable "zone" {
  type = string
}

### APIs Module Variables
variable "services_apis_list" {
  type        = set(string)
  description = "List of services to be enabled in this project before creating resources"
}

### Service Account Module Variables
variable "service_accounts" {
  type        = map(string)
  description = "The Account ID and the Display Name of the Service Accounts."
}

variable "sa_wifederation_email" {
  type        = string
  description = "Email of the Service Account used for Workload Identity Federation."
}

### VPC Module Variables

variable "vpc_name" {
  type        = string
  description = "The name of the VPC Network."
}

variable "subnet_name" {
  type        = string
  description = "The name of the Subnetwork."
}

variable "ip_cidr_range_subnet_gke" {
  type        = string
  description = "The IP CIDR range for the GKE Subnetwork."
}

variable "ip_cidr_range_pods" {
  type        = string
  description = "The IP CIDR range for the Pods secondary IP range."
}

variable "ip_cidr_range_services" {
  type        = string
  description = "The IP CIDR range for the Services secondary IP range."
}

variable "router_name" {
  type        = string
  description = "The name of the Cloud Router."
}

variable "nat_name" {
  type        = string
  description = "The name of the Cloud NAT."
}

variable "psa_name" {
  type        = string
  description = "The name of the PSA IP Range."
}


### Cloud SQL Module Variables
variable "cloud_sql" {
  type = map(object({
    database_version        = string
    instance_tier           = string
    instance_labels         = map(string)
    cloud_sql_instance_name = string
    database_name           = string
    username                = string
    password = object({
      secret_id   = string
      secret_data = string
    })
  }))
}

# variable "auth_db_secret" {
#   type = object({
#     secret_id   = string
#     secret_data = string
#   })
#   sensitive = true
# }

# variable "flag_db_secret" {
#   type = object({
#     secret_id   = string
#     secret_data = string
#   })
#   sensitive = true
# }

# variable "targeting_db_secret" {
#   type = object({
#     secret_id   = string
#     secret_data = string
#   })
#   sensitive = true
# }

variable "database_version" {
  type        = string
  description = "Version of the Database Instance."
  default     = "POSTGRES_14"
}

variable "cloud_sql_instance_name" {
  type        = string
  description = "The name of the Cloud SQL Instance."
}

variable "instance_tier" {
  type        = string
  description = "The machine type to use for the Cloud SQL Instance."
}

variable "instance_labels" {
  type        = map(string)
  description = "A map of labels to assign to the Cloud SQL Instance."
  default     = {}
}

### GKE Module Variables
variable "gke_cluster_name" {
  type        = string
  description = "The name of the GKE Cluster."
}

variable "gke_resource_labels" {
  type        = map(string)
  description = "A set of key/value label pairs to assign to the GKE Cluster."
}

variable "artreg" {
  type = map(object({
    name_artreg = string
    description = string
  }))
}

variable "sa_inside_gke" {
  type = string
}


variable "memory_size_gb_redis" {
  type = number
}

variable "tier_redis" {
  type = string
}

variable "name_redis" {
  type = string
}

variable "connect_mode_redis" {
  type = string
}

variable "aws_access_key_id" {
  type = object({
    secret_id   = string
    secret_data = string
  })
  sensitive = true
}

variable "aws_secret_access_key" {
  type = object({
    secret_id   = string
    secret_data = string
  })
  sensitive = true
}

variable "aws_session_token" {
  type = object({
    secret_id   = string
    secret_data = string
  })
  sensitive = true
}

variable "sm_personal_access_token_gh" {
  type = object({
    secret_id   = string
    secret_data = string
  })
  sensitive = true
}

variable "workload_identity_pool_id" {
  type        = string
  description = "The ID used for the pool, which is the final component of the pool resource name"
}

variable "display_name_wip" {
  type        = string
  description = "Display name of the Workload Identity Pool"
}

variable "workload_identity_pool_provider_id" {
  type        = string
  description = "The ID used for the provider, which is the final component of the pool resource name"
}

variable "display_name_wip_provider" {
  type        = string
  description = "Display name of the Workload Identity Provider"
}

variable "owner_and_repository" {
  type        = string
  description = "Owner and the name of the repository. Example: owner/repository."
}
