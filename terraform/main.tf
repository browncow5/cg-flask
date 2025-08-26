###############################################################################
# main.tf - Example of Cloudsmith resources with Geo/IP rules via Terraform
#           Updated to remove IP-based allow/deny and only allow specific countries
###############################################################################
terraform {
  required_version = ">= 0.13"
  required_providers {
    cloudsmith = {
      source  = "cloudsmith-io/cloudsmith"
      version = "0.0.60"  # Ensure this is the latest supported version
    }
  }
}
provider "cloudsmith" {
  api_key = var.cloudsmith_api_key
}
# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------
variable "cloudsmith_org_slug" {
  description = "Slug for your Cloudsmith organization"
  type        = string
}
variable "cloudsmith_dev_slug" {
  description = "Slug for your Cloudsmith Dev Repo"
  type        = string
}
variable "cloudsmith_prod_slug" {
  description = "Slug for your Cloudsmith Prod Repo"
  type        = string
}
variable "country_allow_list" {
  type    = list(string)
  default = ["IE", "GB", "US"]
}
variable "country_deny_list" {
  type    = list(string)
  default = []
}
# -----------------------------------------------------------------------------
# Repositories
# -----------------------------------------------------------------------------
resource "cloudsmith_repository" "dev" {
  description = "Dev repository"
  name        = var.cloudsmith_dev_slug
  namespace   = var.cloudsmith_org_slug
  slug        = var.cloudsmith_dev_slug
}
resource "cloudsmith_repository" "prod" {
  description    = "Production repository"
  name           = var.cloudsmith_prod_slug
  namespace      = var.cloudsmith_org_slug
  slug           = var.cloudsmith_prod_slug
  storage_region = "us-ohio"
}
# -----------------------------------------------------------------------------
# Retention Policy for Dev Repository
# -----------------------------------------------------------------------------
resource "cloudsmith_repository_retention_rule" "dev_retention" {
  namespace                        = var.cloudsmith_org_slug
  repository                       = cloudsmith_repository.dev.slug
  retention_enabled                = true
  retention_count_limit            = 50          # Keep max 50 packages
  retention_days_limit             = 30          # Or keep for 30 days, whichever is hit first
  retention_size_limit             = 10737418240 # 10 GB (in bytes)
  retention_group_by_name          = true
  retention_group_by_format        = true
  retention_group_by_package_type  = false
}
# -----------------------------------------------------------------------------
# Retention Policy for Prod Repository
# -----------------------------------------------------------------------------
resource "cloudsmith_repository_retention_rule" "prod_retention" {
  namespace                        = var.cloudsmith_org_slug
  repository                       = cloudsmith_repository.prod.slug
  retention_enabled                = true
  retention_count_limit            = 200         # Keep max 200 packages
  retention_days_limit             = 90          # Or keep for 90 days, whichever is hit first
  retention_size_limit             = 10737418240 # 10 GB (in bytes)
  retention_group_by_name          = true
  retention_group_by_format        = true
  retention_group_by_package_type  = false
}
# -----------------------------------------------------------------------------
# Privileges
# -----------------------------------------------------------------------------
resource "cloudsmith_repository_privileges" "dev_privileges" {
  organization = var.cloudsmith_org_slug
  repository   = cloudsmith_repository.dev.slug
  service {
    privilege = "Admin"
    slug      = "terraform-8z2v"
  }
  service {
    privilege = "Write"
    slug      = "gh-actions-3vjo"
  }
  service {
    privilege = "Write"
    slug      = "az-devops-hh48"
  }
  team {
    privilege = "Read"
    slug      = "dev"
  }
  team {
    privilege = "Admin"
    slug      = "owners"
  }
  user {
    privilege = "Admin"
    slug      = "ryan-donat"
  }
}
resource "cloudsmith_repository_privileges" "prod_privileges" {
  organization = var.cloudsmith_org_slug
  repository   = cloudsmith_repository.prod.slug
  service {
    privilege = "Admin"
    slug      = "terraform-8z2v"
  }
  service {
    privilege = "Write"
    slug      = "gh-actions-3vjo"
  }
  service {
    privilege = "Write"
    slug      = "az-devops-hh48"
  }
  team {
    privilege = "Read"
    slug      = "dev"
  }
  team {
    privilege = "Admin"
    slug      = "owners"
  }
  team {
    privilege = "Read"
    slug      = "ops-team"
  }
  user {
    privilege = "Admin"
    slug      = "ryan-donat"
  }
}
# -----------------------------------------------------------------------------
# Dev Repository Upstreams
# -----------------------------------------------------------------------------
resource "cloudsmith_repository_upstream" "pypi_upstream" {
  name          = "Python Package Index"
  namespace     = var.cloudsmith_org_slug
  repository    = cloudsmith_repository.dev.slug_perm
  upstream_type = "python"
  upstream_url  = "https://pypi.org"
  mode          = "Cache and Proxy"
}
resource "cloudsmith_repository_upstream" "maven_central" {
  name          = "Maven Central"
  namespace     = var.cloudsmith_org_slug
  repository    = cloudsmith_repository.dev.slug_perm
  upstream_type = "maven"
  upstream_url  = "https://repo1.maven.org/maven2"
  mode          = "Cache and Proxy"
}
resource "cloudsmith_repository_upstream" "chainguard_images" {
  name          = "Chainguard Images"
  namespace     = var.cloudsmith_org_slug
  repository    = cloudsmith_repository.dev.slug_perm
  upstream_type = "docker"
  upstream_url  = "https://cgr.dev"
  mode          = "Cache and Proxy"
  is_active     = "true"
}
# -----------------------------------------------------------------------------
# Prod Repository Upstreams
# -----------------------------------------------------------------------------
resource "cloudsmith_repository_upstream" "pypi_upstream_prod" {
  name          = "Python Package Index"
  namespace     = var.cloudsmith_org_slug
  repository    = cloudsmith_repository.prod.slug_perm
  upstream_type = "python"
  upstream_url  = "https://pypi.org"
  mode          = "Cache and Proxy"
}
resource "cloudsmith_repository_upstream" "chainguard_images_prod" {
  name          = "Chainguard Images"
  namespace     = var.cloudsmith_org_slug
  repository    = cloudsmith_repository.prod.slug_perm
  upstream_type = "docker"
  upstream_url  = "https://cgr.dev"
  mode          = "Cache and Proxy"
  is_active     = "true"
}
# -----------------------------------------------------------------------------
# Geo/IP Rules (Countries Only)
#
# We create a single resource that applies the same country-allow and country-deny
# to each repository via `for_each`. IP-based rules are removed for simplicity.
# -----------------------------------------------------------------------------
resource "cloudsmith_repository_geo_ip_rules" "geoip_for_each_repo" {
  for_each = {
    "dev"     = cloudsmith_repository.dev
    "prod"    = cloudsmith_repository.prod
  }
  namespace  = each.value.namespace
  repository = each.value.slug_perm
  # No IP-based allow/deny lists
  # Only country-based rules
  country_code_allow = var.country_allow_list
  country_code_deny  = var.country_deny_list
}
