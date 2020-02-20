terraform {
  required_version = ">= 0.12"
}

provider "google" {
  project = "devrel"
  region  = "us-west2"
}

provider "github" {
  token        = var.github_token
  organization = "influxdata"
}

terraform {
  backend "gcs" {
    bucket = "influxdata-devrel-operations"
    prefix = "github.com/helm-charts"
  }
}

variable "github_token" {
  type = string
}
