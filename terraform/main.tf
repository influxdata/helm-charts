terraform {
  required_version = ">= 0.12"
}

provider "google" {
  project = "devrel"
  region  = "us-west2"
}

provider "github" {
  organization = "influxdata"
  anonymous    = false
}

terraform {
  backend "gcs" {
    bucket = "influxdata-devrel-operations"
    prefix = "github.com/helm-charts"
  }
}
