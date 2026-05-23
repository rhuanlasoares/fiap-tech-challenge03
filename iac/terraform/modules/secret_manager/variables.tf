variable "project_id" {
  type        = string
  description = "The Project ID of the project where the resource will be created."
}

variable "region" {
  type        = string
  description = "The region where the Subnetwork will be created."
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

variable "auth_db_secret" {
  type = object({
    secret_id   = string
    secret_data = string
  })
  sensitive = true
}

variable "flag_db_secret" {
  type = object({
    secret_id   = string
    secret_data = string
  })
  sensitive = true
}

variable "targeting_db_secret" {
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

variable "sm_sqs_queue_url" {
  type = object({
    secret_id   = string
    secret_data = string
  })
  sensitive = true
}

