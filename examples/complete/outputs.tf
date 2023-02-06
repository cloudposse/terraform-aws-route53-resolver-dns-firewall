output "vpc_cidr" {
  value       = module.vpc.vpc_cidr_block
  description = "VPC ID"
}

output "query_log_config" {
  value       = module.route53_resolver_firewall.query_log_config
  description = "Route 53 Resolver query logging configuration"
}

output "domains" {
  value       = module.route53_resolver_firewall.domains
  description = "Route 53 Resolver DNS Firewall domain configurations"
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
