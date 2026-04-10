# Challenge 02: Terraform + EC2 (IaC on AWS)

## Objective
Provision a work machine (`bia-dev`) on AWS using Terraform with remote state, applying Infrastructure as Code principles for reproducibility and security.

## Key constraint
Understand the difference between IaC (Terraform) and imperative operations (AWS CLI):
- AWS CLI: manual, command-by-command execution
- Terraform: declarative, versioned, repeatable infrastructure

## Scope
- Terraform project setup and validation
- AWS resource provisioning (EC2, IAM, Security Groups, RDS)
- Existing network usage (VPC/subnets referenced from locals)
- State management (local to remote)
- Importing existing infrastructure into Terraform state

## Approach
This challenge follows a progression from manual to declarative infrastructure:
1. Start from an AWS CLI mindset (manual operations)
2. Move to Terraform (definition-based infrastructure)
3. Introduce state management practices
4. Integrate existing resources (real-world scenario)
5. Evolve toward production-ready patterns

## Prerequisites
- Terraform installed
- AWS CLI configured with a named profile
- IAM permissions to manage EC2, IAM, Security Groups, RDS, and S3 backend state
- Optional: VS Code HashiCorp Terraform extension

## Working directory
Run all Terraform commands from:

```bash
cd formation-aws/challenge-labs-2-0/2026-03/challenge-02-terraform-ec2/terraform
```

---

## Phase 1: Install and initialize Terraform project

### Goal
Prepare Terraform locally and initialize provider/backend dependencies.

### Files involved
- `provider.tf`
- `state_config.tf`
- `variables.tf`
- `locals.tf`
- `terraform.tfvars.example`

### Commands
```bash
terraform version
terraform init
terraform validate
terraform plan
```

Required runtime input for RDS password (`db_password` has no default):

```bash
# Option 1: local tfvars file (recommended)
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars and set a real password
terraform apply -var-file='terraform.tfvars'

# Option 2: CLI variable
terraform apply -var 'db_password=<secure-password>'

# Option 3: environment variable
TF_VAR_db_password='<secure-password>' terraform apply
```

### Expected result
- Terraform is available locally.
- AWS provider plugins are installed.
- Configuration is valid and plan is generated.
- `db_password` must be supplied at runtime by one of the supported input methods.

> Warning: placeholder values from `terraform.tfvars.example` are not runnable until replaced with real values.

---

## Phase 2: Provision first EC2 resource

### Goal
Create the first EC2 instance and verify basic lifecycle.

### Files involved
- `aws_instance.tf`
- `variables.tf`
- `locals.tf`

### Commands
```bash
terraform apply
terraform show
terraform output
```

Optional custom instance name:
```bash
terraform apply -var 'instance_name=bia-dev-tf-2'
```

### Expected result
- `aws_instance.bia_dev` is created.
- Output values include instance metadata (ID, public IP, DNS, private IP).

---

## Phase 3: Inspect and destroy infrastructure safely

### Goal
Inspect current state and destroy resources when cleanup is required.

### Files involved
- State files and all resource definitions under `terraform/`

### Commands
```bash
terraform show
terraform destroy
```

Targeted destroy (advanced):
```bash
terraform destroy -target='aws_instance.bia_dev'
```

### Expected result
- Full or targeted resource destruction as requested.
- State is updated after deletion.

> Warning: `destroy` is destructive. Confirm the plan output before approval.

---

## Phase 4: Variables, outputs, security groups, IAM, and userdata

### Goal
Connect resources and improve parametrization for repeatability.

### Files involved
- `aws_security_groups.tf`
- `aws_iam.tf`
- `aws_instance.tf`
- `aws_db_instance.tf`
- `variables.tf`
- `output.tf`
- `userdata_bia_dev.sh`

### Commands
```bash
terraform plan
terraform apply
terraform output
```

Refresh state data (recommended modern approach):
```bash
terraform apply -refresh-only
```

### Expected result
- Security groups and IAM profile are associated with EC2.
- User data script is applied to EC2.
- Output values expose key infrastructure endpoints.

> Note: Changing some immutable arguments (for example AMI in `aws_instance`) forces resource replacement.

---

## Phase 5: State operations and local recovery

### Goal
Understand and operate Terraform state safely.

### Files involved
- `terraform.tfstate`
- `terraform.tfstate.backup`
- `.gitignore`

### Commands
Inspect and operate state:
```bash
terraform state show aws_security_group.bia_dev
terraform state list
terraform state rm aws_security_group.bia_dev
```

Recover local state from backup:
```bash
cp terraform.tfstate.backup terraform.tfstate
terraform init
terraform apply
```

Import existing resources into local state:
```bash
terraform import aws_security_group.bia_dev sg-xxxxxxxxxxxxxxxxx
terraform import aws_instance.bia_dev i-xxxxxxxxxxxxxxxxx
terraform state list
terraform apply
```

Recommended `.gitignore` entries:
```gitignore
**/.terraform*
terraform.tfstate*
**/*.tfvars
**/*.auto.tfvars
!**/*.tfvars.example
```

### Expected result
- State can be inspected, repaired, and reconciled with existing AWS resources.
- State artifacts are excluded from Git.

> Warning: `terraform state rm` removes only from Terraform state; it does not delete the AWS resource.

---

## Phase 6: Migrate state to S3 backend

### Goal
Move from local state to shared remote state.

### Files involved
- `state_config.tf`
- `../s3-bucket-config/policy-terraform-tfstate`

### Commands
```bash
terraform init -migrate-state
```

### Expected result
- State is migrated from local file to S3 backend.
- Team collaboration and state durability are improved.

> Use placeholders for environment-specific values in docs: `<bucket-name>`, `<region>`, `<profile-name>`.

---

## Phase 7: Import existing IAM, Security Groups, and RDS

### Goal
Bring pre-existing AWS resources under Terraform management.

### Files involved
- `aws_iam.tf`
- `aws_security_groups.tf`
- `aws_db_instance.tf`
- `import.tf` (temporary when using import blocks)

### Commands
CLI import examples:
```bash
terraform import aws_iam_role.role_acesso_ssm <iam-role-name>
terraform import aws_iam_instance_profile.role_acesso_ssm <instance-profile-name>
terraform import aws_security_group.bia_db sg-xxxxxxxxxxxxxxxxx
terraform import aws_security_group.bia_web sg-xxxxxxxxxxxxxxxxx
terraform import aws_security_group.bia_ec2 sg-xxxxxxxxxxxxxxxxx
terraform import aws_security_group.bia_alb sg-xxxxxxxxxxxxxxxxx
terraform import aws_db_instance.bia <db-instance-identifier>
```

Import blocks (Terraform 1.5+):
```hcl
import {
  id = "<iam-role-name>"
  to = aws_iam_role.role_acesso_ssm
}

import {
  id = "<instance-profile-name>"
  to = aws_iam_instance_profile.role_acesso_ssm
}
```

Generate candidate config:
```bash
terraform plan -generate-config-out=out_iam.tf
terraform plan -generate-config-out=out_sg.tf
terraform plan -generate-config-out=out_db.tf
terraform apply
terraform state list
```

### Expected result
- Existing resources are represented in Terraform state and configuration.
- Generated `out_*.tf` files are reviewed and merged before cleanup.

---

## Phase 8: Provider upgrade, IPv6 checks, and recovery sequence

### Goal
Update provider version and recover quickly from local environment issues.

### Files involved
- `provider.tf`
- `aws_instance.tf`
- `.terraform/`
- `.terraform.lock.hcl`

### Commands
Provider upgrade:
```bash
terraform init -upgrade
terraform plan
terraform apply
```

Recovery sequence:
```bash
terraform version
rm -rf .terraform .terraform.lock.hcl
terraform init
terraform validate
terraform plan
terraform apply -target=aws_instance.bia_dev
```

### Expected result
- Provider upgrade is applied cleanly.
- IPv6-related settings in EC2 are validated through plan/apply.
- Local Terraform environment can be rebuilt when needed.

> Warning: `-target` is for controlled recovery only; run a full `terraform plan` and `terraform apply` after targeted operations.

---

## Final outcome
- `bia-dev` instance provisioned through Terraform
- Security Groups and IAM integration applied
- RDS managed/imported in Terraform scope
- Remote state configured in S3

## Key learnings
- Declarative infrastructure improves consistency and reproducibility.
- Terraform state is central for collaboration and lifecycle control.
- Import workflows are essential for adopting existing environments.

## References
- Terraform install tutorial: https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli
- Terraform install options: https://developer.hashicorp.com/terraform/install
- S3 backend docs: https://developer.hashicorp.com/terraform/language/backend/s3
- AWS provider releases: https://github.com/hashicorp/terraform-provider-aws/releases
- Security Group resource docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group
