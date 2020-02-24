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

resource "github_branch_protection" "helm_charts_master" {
  repository     = "${github_repository.helm_charts.name}"
  branch         = "master"
  enforce_admins = true

  required_status_checks {
    strict = true
  }

  required_pull_request_reviews {
    dismiss_stale_reviews           = true
    require_code_owner_reviews      = true
    required_approving_review_count = 2
  }

  restrictions {
  }
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
