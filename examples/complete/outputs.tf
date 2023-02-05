output "query_log_config" {
  value       = module.route53_resolver_firewall.query_log_config
  description = "Route 53 Resolver query logging configuration"
}

output "domain_lists" {
  value       = module.route53_resolver_firewall.domain_lists
  description = "Route 53 Resolver DNS Firewall domain lists"
}

output "rule_groups" {
  value       = module.route53_resolver_firewall.rule_groups
  description = "Route 53 Resolver DNS Firewall rule groups"
}

output "rule_group_associations" {
  value       = module.route53_resolver_firewall.rule_group_associations
  description = "Route 53 Resolver DNS Firewall rule group associations"
}

output "rules" {
  value       = module.route53_resolver_firewall.rules
  description = "Route 53 Resolver DNS Firewall rules"
}
