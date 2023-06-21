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

module "route53_resolver_firewall" {
  source = "../../"

  vpc_id = module.vpc.vpc_id

  firewall_fail_open        = var.firewall_fail_open
  query_log_enabled         = var.query_log_enabled
  query_log_config_name     = var.query_log_config_name
  query_log_destination_arn = module.s3_log_storage.bucket_arn

  domains_config     = var.domains_config
  rule_groups_config = var.rule_groups_config

  context = module.this.context
}
