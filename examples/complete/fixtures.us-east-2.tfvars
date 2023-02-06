region = "us-east-2"

namespace = "eg"

stage = "test"

name = "route53-resolver-firewall"

query_log_enabled = true

firewall_fail_open = "ENABLED"

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_resolver_firewall_domain_list
domains_config = [
  {
    name = "not-secure-domains"
    domains = [
      "not-secure-domain-1.com",
      "not-secure-domain-2.com",
      "not-secure-domain-3.com"
    ]
  },
  {
    name = "dangerous-domains"
    domains = [
      "dangerous-domain-1.com",
      "dangerous-domain-2.com",
      "dangerous-domain-3.com"
    ]
  }
]

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_resolver_firewall_rule_group
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_resolver_firewall_rule
rule_groups_config = [
  {
    name     = "not-secure-domains-rule-group"
    priority = 1
    rules = [
      {
        name                      = "block-not-secure-domains"
        priority                  = 1
        firewall_domain_list_name = "not-secure-domains"
        action                    = "BLOCK"
        block_response            = "NXDOMAIN"
      }
    ]
  },
  {
    name     = "dangerous-domains-rule-group"
    priority = 2
    rules = [
      {
        name                      = "alert-dangerous-domains"
        priority                  = 1
        firewall_domain_list_name = "dangerous-domains"
        action                    = "ALERT"
      },
      {
        name                      = "block-and-override-dangerous-domains"
        priority                  = 2
        firewall_domain_list_name = "dangerous-domains"
        action                    = "BLOCK"
        block_response            = "OVERRIDE"
        block_override_dns_type   = "CNAME"
        block_override_domain     = "go-here.com"
        block_override_ttl        = 1
      }
    ]
  }
]
