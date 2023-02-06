output "query_log_config" {
  value       = aws_route53_resolver_query_log_config.default
  description = "Route 53 Resolver query logging configuration"
}

output "domains" {
  value       = aws_route53_resolver_firewall_domain_list.default
  description = "Route 53 Resolver DNS Firewall domain configurations"
}

output "rule_groups" {
  value       = aws_route53_resolver_firewall_rule_group.default
  description = "Route 53 Resolver DNS Firewall rule groups"
}

output "rule_group_associations" {
  value       = aws_route53_resolver_firewall_rule_group_association.default
  description = "Route 53 Resolver DNS Firewall rule group associations"
}

output "rules" {
  value       = aws_route53_resolver_firewall_rule.default
  description = "Route 53 Resolver DNS Firewall rules"
}
