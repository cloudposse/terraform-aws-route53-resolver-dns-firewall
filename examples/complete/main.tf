provider "aws" {
  region = var.region
}

module "vpc" {
  source  = "cloudposse/vpc/aws"
  version = "2.1.0"

  ipv4_primary_cidr_block                   = "172.19.0.0/16"
  dns_hostnames_enabled                     = true
  dns_support_enabled                       = true
  internet_gateway_enabled                  = false
  ipv6_egress_only_internet_gateway_enabled = false
  assign_generated_ipv6_cidr_block          = false

  context = module.this.context
}

module "s3_log_storage" {
  source  = "cloudposse/s3-log-storage/aws"
  version = "1.4.1"

  enabled       = module.this.enabled && var.query_log_enabled
  force_destroy = true
  attributes    = ["logs"]

  context = module.this.context
}

# Pre-existing domain list created outside the module, used to exercise the
# `firewall_domain_list_id` code path. In production this would typically be an
# AWS Managed Domain List (e.g. `AWSManagedDomainsMalwareDomainList`), which is
# referenced by its account-and-region-specific `rslvr-fdl-...` ID.
resource "aws_route53_resolver_firewall_domain_list" "external" {
  count = module.this.enabled ? 1 : 0

  name = format("%s-external", module.this.id)
  domains = [
    "external-domain-1.com.",
    "external-domain-2.com.",
  ]
  tags = module.this.tags
}

locals {
  # Merge the rule groups from the var-file with an additional group whose rule
  # references the pre-existing domain list above by ID. This proves the new
  # `firewall_domain_list_id` lookup path works end-to-end.
  rule_groups_config = merge(var.rule_groups_config, module.this.enabled ? {
    "external-list-rule-group" = {
      priority = 300
      rules = {
        "block-external-by-id" = {
          priority                = 110
          firewall_domain_list_id = aws_route53_resolver_firewall_domain_list.external[0].id
          action                  = "BLOCK"
          block_response          = "NODATA"
        }
      }
    }
  } : {})
}

module "route53_resolver_firewall" {
  source = "../../"

  vpc_id = module.vpc.vpc_id

  firewall_fail_open        = var.firewall_fail_open
  query_log_enabled         = var.query_log_enabled
  query_log_config_name     = var.query_log_config_name
  query_log_destination_arn = module.s3_log_storage.bucket_arn

  domains_config     = var.domains_config
  rule_groups_config = local.rule_groups_config

  context = module.this.context
}
