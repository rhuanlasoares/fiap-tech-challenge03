variable "project_id" {
  type        = string
  description = "The Project ID of the project where the resource will be created."
}

variable "zone" {
  type = string
}

variable "region" {
  type        = string
  description = "The region where the Subnetwork will be created."
}

variable "psa_name" {
  type = string
}

variable "vpc_self_link" {
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
