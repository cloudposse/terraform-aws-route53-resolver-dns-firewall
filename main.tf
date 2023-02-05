locals {
  enabled           = module.this.enabled
  query_log_enabled = local.enabled && var.query_log_enabled

  firewall_rules_list = [
    for rule_group_name, rule_group in var.rule_groups : {
      for rule_name, rule in rule_group.rules : rule_name => merge(rule, { rule_group_id = aws_route53_resolver_firewall_rule_group.default[rule_group_name].id })
    }
  ]

  firewall_rules_map = {
    for rule in local.firewall_rules_list : rule.name => rule
  }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_resolver_firewall_config
resource "aws_route53_resolver_firewall_config" "default" {
  count = local.enabled ? 1 : 0

  resource_id        = var.vpc_id
  firewall_fail_open = var.firewall_fail_open
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_resolver_firewall_domain_list
resource "aws_route53_resolver_firewall_domain_list" "default" {
  for_each = { for k, v in var.domain_lists : k => v if local.enabled }

  name    = each.value.name
  domains = each.value.domains
  tags    = module.this.tags
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_resolver_firewall_rule_group
resource "aws_route53_resolver_firewall_rule_group" "default" {
  for_each = { for k, v in var.rule_groups : k => v if local.enabled }

  name = each.value.name
  tags = module.this.tags
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_resolver_firewall_rule_group_association
resource "aws_route53_resolver_firewall_rule_group_association" "default" {
  for_each = { for k, v in var.rule_groups : k => v if local.enabled }

  name                   = each.value.name
  firewall_rule_group_id = aws_route53_resolver_firewall_rule_group.default[each.key].id
  priority               = each.value.priority
  vpc_id                 = var.vpc_id
  tags                   = module.this.tags
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_resolver_firewall_rule
resource "aws_route53_resolver_firewall_rule" "default" {
  for_each = local.firewall_rules_map

  name     = each.value.name
  action   = each.value.action
  priority = each.value.priority

  firewall_rule_group_id  = each.value.rule_group_id
  firewall_domain_list_id = aws_route53_resolver_firewall_domain_list.default[each.value.firewall_domain_list_name].id

  block_override_dns_type = lookup(each.value, "block_override_dns_type", null)
  block_override_domain   = lookup(each.value, "block_override_domain", null)
  block_override_ttl      = lookup(each.value, "block_override_ttl", null)
  block_response          = lookup(each.value, "block_response", null)
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_resolver_query_log_config
resource "aws_route53_resolver_query_log_config" "default" {
  count = local.query_log_enabled ? 1 : 0

  name            = (var.query_log_config_name != null && var.query_log_config_name != "") ? var.query_log_config_name : format("%s-%s", module.this.id, var.vpc_id)
  destination_arn = var.query_log_destination_arn
  tags            = module.this.tags
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_resolver_query_log_config_association
resource "aws_route53_resolver_query_log_config_association" "default" {
  count = local.query_log_enabled ? 1 : 0

  resolver_query_log_config_id = one(aws_route53_resolver_query_log_config.default[*].id)
  resource_id                  = var.vpc_id
}
