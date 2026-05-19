package test

import (
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	testStructure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/assert"
	"strings"
	"testing"
)

// Test the Terraform module in examples/complete using Terratest.
func TestExamplesComplete(t *testing.T) {
	t.Parallel()
	randID := strings.ToLower(random.UniqueId())
	attributes := []string{randID}

	rootFolder := "../../"
	terraformFolderRelativeToRoot := "examples/complete"
	varFiles := []string{"fixtures.us-east-2.tfvars"}

	tempTestFolder := testStructure.CopyTerraformFolderToTemp(t, rootFolder, terraformFolderRelativeToRoot)

	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: tempTestFolder,
		Upgrade:      true,
		// Variables to pass to our Terraform code using -var-file options
		VarFiles: varFiles,
		Vars: map[string]interface{}{
			"attributes": attributes,
			"enabled":    true,
		},
	}

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer cleanup(t, terraformOptions, tempTestFolder)

	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	terraform.InitAndApply(t, terraformOptions)

	// Run `terraform output` to get the value of an output variable
	vpcCidr := terraform.Output(t, terraformOptions, "vpc_cidr")
	// Verify we're getting back the outputs we expect
	assert.Equal(t, "172.19.0.0/16", vpcCidr)

	// Run `terraform output` to get the value of an output variable
	domains := terraform.OutputMap(t, terraformOptions, "domains")
	// Verify we're getting back the outputs we expect (created from `domains_config`,
	// the externally-created list is not part of the module's `domains` output).
	assert.Equal(t, 3, len(domains))

	// Run `terraform output` to get the value of an output variable
	ruleGroups := terraform.OutputMap(t, terraformOptions, "rule_groups")
	// Verify we're getting back the outputs we expect (2 from the var-file + 1
	// added in main.tf to exercise `firewall_domain_list_id`).
	assert.Equal(t, 3, len(ruleGroups))

	// Run `terraform output` to get the value of an output variable
	rules := terraform.OutputJson(t, terraformOptions, "rules")
	// Verify we're getting back the outputs we expect (3 from the var-file + 1
	// added in main.tf that references the pre-existing list by ID).
	assert.Equal(t, 4, strings.Count(rules, "\"firewall_rule_group_id\""))

	// Verify the new rule's `firewall_domain_list_id` matches the external list's ID,
	// proving the `coalesce(rule.firewall_domain_list_id, try(...))` lookup path works.
	externalDomainListID := terraform.Output(t, terraformOptions, "external_domain_list_id")
	assert.NotEmpty(t, externalDomainListID)
	assert.Contains(t, rules, externalDomainListID)
}

func TestExamplesCompleteDisabled(t *testing.T) {
	t.Parallel()
	randID := strings.ToLower(random.UniqueId())
	attributes := []string{randID}

	rootFolder := "../../"
	terraformFolderRelativeToRoot := "examples/complete"
	varFiles := []string{"fixtures.us-east-2.tfvars"}

	tempTestFolder := testStructure.CopyTerraformFolderToTemp(t, rootFolder, terraformFolderRelativeToRoot)

	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: tempTestFolder,
		Upgrade:      true,
		// Variables to pass to our Terraform code using -var-file options
		VarFiles: varFiles,
		Vars: map[string]interface{}{
			"attributes": attributes,
			"enabled":    false,
		},
	}

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer cleanup(t, terraformOptions, tempTestFolder)

	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	results := terraform.InitAndApply(t, terraformOptions)

	// Should complete successfully without creating or changing any resources
	assert.Contains(t, results, "Resources: 0 added, 0 changed, 0 destroyed.")
}
