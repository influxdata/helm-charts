resource "github_repository" "helm_charts" {
  name        = "helm-charts"
  description = "Official Helm Chart Repository for InfluxData Applications"

  allow_merge_commit = false
  allow_squash_merge = false
  allow_rebase_merge = true

  has_downloads = true
  has_issues    = true
  has_projects  = true
  has_wiki      = true

  topics = [
    "helm",
    "kubernetes"
  ]

  private = false
}

variable "colour_dark_blue" {
  type    = string
  default = "779ecb"
}

resource "github_issue_label" "types" {
  for_each = {
    bug     = "Is something not working as expected?"
    feature = "Would you like to see some new functionality?"
  }

  name        = "type/${each.key}"
  description = each.value
  repository  = github_repository.helm_charts.name
  color       = var.colour_dark_blue
}
