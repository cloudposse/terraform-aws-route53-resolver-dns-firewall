provider "aws" {
  region = var.region
}

module "vpc" {
  source  = "cloudposse/vpc/aws"
  version = "2.0.0"

  ipv4_primary_cidr_block = "172.19.0.0/16"

  context = module.this.context
}

module "s3_log_storage" {
  source  = "cloudposse/s3-log-storage/aws"
  version = "1.0.0"

  enabled       = var.query_log_enabled
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

  domain_lists = var.domain_lists
  rule_groups  = var.rule_groups

  context = module.this.context
}
