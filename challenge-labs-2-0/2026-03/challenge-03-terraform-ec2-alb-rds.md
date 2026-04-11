# Challenge 03: Terraform + ECS + ALB + RDS

## Challenge objective
Evolve the infrastructure from the final state of challenge 02 from `2026-03` and launch BIA on AWS using Terraform, covering both the ECS deployment without an ALB and the ECS deployment with ALB, domain, and HTTPS.

### Mandatory constraints
- This challenge starts from the completed Terraform baseline produced in challenge 02 from `2026-03`.
- The previous challenge must already be concluded before starting this stage.
- The work must stay focused on what is new in challenge 03 rather than repeating Terraform bootstrap or the EC2-first flow from challenge 02.
- The ALB path must include a listener on port `443`.
- `ACM` and `Route 53` do not need to be provisioned with Terraform in this challenge.

## Scope
- Continue from the existing Terraform project and state inherited from challenge 02
- Evolve the environment toward running BIA on ECS
- Cover the initial deployment path without ALB
- Extend the architecture to use ALB, domain, and HTTPS
- Keep `RDS` as part of the application architecture
- Preserve Terraform state continuity while extending the stack

## What changes in this challenge
This challenge is a continuation rather than a restart:
- The Terraform project already exists.
- The baseline AWS resources from challenge 02 are already in place.
- The focus now shifts from the foundational EC2-centered setup to the application architecture on ECS.
- The architecture must progress through two target states:
  - ECS without ALB
  - ECS with ALB + domain + HTTPS
- The HTTPS step requires attention to the missing ALB listener on port `443`.

## Prerequisites
- Challenge 02 from `2026-03` completed
- Terraform installed locally
- AWS CLI configured with a named profile
- IAM permissions to manage the infrastructure extended in this stage
- Existing Terraform state and baseline resources available from the previous challenge
- Optional: VS Code HashiCorp Terraform extension

## Working directory
Run all Terraform commands from:

```bash
cd formation-aws/challenge-labs-2-0/2026-03/challenge-03-terraform-ec2-alb-rds/terraform
```

---

## Phase 1: Confirm the inherited baseline from challenge 02

### Goal
Verify that challenge 03 is starting from the final state already established in challenge 02, instead of recreating the previous environment from scratch.

### Files involved
- `provider.tf`
- `state_config.tf`
- `locals.tf`
- `variables.tf`
- `terraform.tfvars.example`
- Existing state files under `terraform/`

### Commands
```bash
terraform version
terraform init
terraform validate
terraform state list
terraform plan
```

### Expected result
- Terraform initializes successfully in the challenge 03 working directory.
- The inherited project structure is available.
- Existing state can be inspected before new resources are introduced.
- The starting point is confirmed as the continuation of challenge 02.

> Warning: this phase is for baseline confirmation, not for redoing challenge 02 tasks.

---

## Phase 2: Review the current Terraform foundation and runtime inputs

### Goal
Inspect the current Terraform inputs, outputs, and foundational resources that will support the ECS evolution.

### Files involved
- `aws_instance.tf`
- `aws_iam.tf`
- `aws_security_groups.tf`
- `aws_db_instance.tf`
- `variables.tf`
- `output.tf`
- `userdata_bia_dev.sh`

### Commands
```bash
terraform plan
terraform show
terraform output
```

Required runtime input for the database password if a new apply requires it:

```bash
# Option 1: local tfvars file
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars and set a real password
terraform apply -var-file='terraform.tfvars'

# Option 2: CLI variable
terraform apply -var 'db_password=<secure-password>'

# Option 3: environment variable
TF_VAR_db_password='<secure-password>' terraform apply
```

### Expected result
- The inherited EC2, IAM, security group, and RDS foundations are understood before extending the stack.
- Terraform inputs and outputs are ready for the next stages.
- The project is ready to evolve without losing state continuity.

---

## References
- Terraform install tutorial: https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli
- Terraform S3 backend docs: https://developer.hashicorp.com/terraform/language/backend/s3
- AWS ECS documentation: https://docs.aws.amazon.com/ecs/
- Elastic Load Balancing documentation: https://docs.aws.amazon.com/elasticloadbalancing/
- Amazon RDS documentation: https://docs.aws.amazon.com/rds/
