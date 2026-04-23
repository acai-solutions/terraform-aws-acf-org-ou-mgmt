package test

import (
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestExampleComplete(t *testing.T) {
	// retryable errors in terraform testing.
	t.Log("Starting Sample Module test")

	terraformDir := "../../examples/complete"
	stateKey := "terratest/terraform-aws-acf-org-ou-mgmt.tfstate"
	backendConfig := loadBackendConfig(t, stateKey)

	// Create IAM Role
	terraformPreparation := &terraform.Options{
		TerraformBinary: getHclBinary(),
		TerraformDir:    terraformDir,
		NoColor:         false,
		Lock:            true,
		BackendConfig:   backendConfig,
		Targets: []string{
			"module.create_provisioner",
			"aws_organizations_policy.scp_example",
		},
	}
	terraform.InitAndApply(t, terraformPreparation)

	// Wait for IAM role propagation (eventual consistency)
	t.Log("Waiting 10 seconds for IAM role propagation...")
	time.Sleep(10 * time.Second)

	terraformModule := &terraform.Options{
		TerraformBinary: getHclBinary(),
		TerraformDir:    terraformDir,
		NoColor:         false,
		Lock:            true,
		BackendConfig:   backendConfig,
		Targets: []string{
			"module.example_complete",
		},
	}
	terraform.InitAndApply(t, terraformModule)

	terraformReport := &terraform.Options{
		TerraformBinary: getHclBinary(),
		TerraformDir:    terraformDir,
		NoColor:         false,
		Lock:            true,
		BackendConfig:   backendConfig,
	}
	terraform.InitAndApply(t, terraformReport)

	// Retrieve the 'test_success' outputs
	testSuccess1Output := terraform.Output(t, terraformModule, "test_success1")
	testSuccess2Output := terraform.Output(t, terraformModule, "test_success2")
	testSuccess3Output := terraform.Output(t, terraformReport, "test_success3")
	t.Logf("testSuccess1Output: %s", testSuccess1Output)
	t.Logf("testSuccess2Output: %s", testSuccess2Output)
	t.Logf("testSuccess3Output: %s", testSuccess3Output)

	// Assert that 'test_success' equals "true"
	assert.Equal(t, "true", testSuccess1Output, "The test_success1 output is not true")
	assert.Equal(t, "true", testSuccess2Output, "The test_success2 output is not true")
	assert.Equal(t, "true", testSuccess3Output, "The test_success3 output is not true")

	terraform.Destroy(t, terraformModule)
	terraform.Destroy(t, terraformReport)
	terraform.Destroy(t, terraformPreparation)
}
