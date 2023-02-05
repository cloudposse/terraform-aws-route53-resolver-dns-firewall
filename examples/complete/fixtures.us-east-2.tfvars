region = "us-east-2"

namespace = "eg"

stage = "test"

name = "route53-resolver-firewall"

query_log_enabled = true

firewall_fail_open = "ENABLED"

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_resolver_firewall_domain_list
domain_lists = [
]

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_resolver_firewall_rule_group
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_resolver_firewall_rule
rule_groups = [
]
