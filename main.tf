locals {
  enabled           = module.this.enabled
  query_log_enabled = local.enabled && var.query_log_enabled

  rules_map = merge([
    for rule_group_name, rule_group in var.rule_groups_config : {
      for rule_name, rule in rule_group.rules : format("%s-%s", rule_group_name, rule_name) => (
        merge(rule,
          {
            rule_name      = rule_name
            rule_group_id  = aws_route53_resolver_firewall_rule_group.default[rule_group_name].id
            domain_list_id = aws_route53_resolver_firewall_domain_list.default[rule.firewall_domain_list_name].id
          }
        )
      ) if local.enabled
    }
  ]...)
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_resolver_firewall_config
resource "aws_route53_resolver_firewall_config" "default" {
  count = local.enabled ? 1 : 0

  resource_id        = var.vpc_id
  firewall_fail_open = var.firewall_fail_open
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_resolver_firewall_domain_list
resource "aws_route53_resolver_firewall_domain_list" "default" {
  for_each = local.enabled ? var.domains_config : {}

  name = format("%s-%s", each.key, var.vpc_id)

  # Concat the lists of domains passed in the `domains` field and loaded from the file `domains_file`
  domains = distinct(compact(concat(
    lookup(each.value, "domains", null) != null ? each.value.domains : [],
    (lookup(each.value, "domains_file", "") != "" && lookup(each.value, "domains_file", null) != null) ? split("\n", file(each.value.domains_file)) : []
  )))

  tags = module.this.tags
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_resolver_firewall_rule_group
resource "aws_route53_resolver_firewall_rule_group" "default" {
  for_each = local.enabled ? var.rule_groups_config : {}

  name = format("%s-%s", each.key, var.vpc_id)
  tags = module.this.tags
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_resolver_firewall_rule_group_association
resource "aws_route53_resolver_firewall_rule_group_association" "default" {
  for_each = local.enabled ? var.rule_groups_config : {}

  name                   = format("%s-%s", each.key, var.vpc_id)
  priority               = each.value.priority
  firewall_rule_group_id = aws_route53_resolver_firewall_rule_group.default[each.key].id
  vpc_id                 = var.vpc_id
  tags                   = module.this.tags
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_resolver_firewall_rule
resource "aws_route53_resolver_firewall_rule" "default" {
  for_each = local.rules_map

  name                    = format("%s-%s", each.value.rule_name, var.vpc_id)
  action                  = each.value.action
  priority                = each.value.priority
  firewall_rule_group_id  = each.value.rule_group_id
  firewall_domain_list_id = each.value.domain_list_id

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
