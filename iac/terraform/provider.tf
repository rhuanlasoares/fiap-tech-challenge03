terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.15.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 7.15.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.5.0"
    }
  }
  backend "gcs" {
    bucket = "gcs-terraform-image-process"
    prefix = "terraform/state"
  }
}

provider "aws" {
  region = "us-east-1"
}
