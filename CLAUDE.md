# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Terraform Infrastructure as Code repository for the Traffic Tacos project, managing AWS infrastructure with a 3-tier architecture including VPC, EKS, and EC2 modules.

## Common Commands

### Terraform Commands
```bash
# Initialize Terraform
terraform init

# Plan infrastructure changes
terraform plan

# Apply infrastructure changes
terraform apply

# Format Terraform code
terraform fmt -recursive

# Validate Terraform configuration
terraform validate

# View outputs
terraform output
```

### AWS Profile Setup
```bash
# Configure AWS profile (required before running Terraform)
aws configure --profile tacos
```

### Workspace Management
```bash
# List workspaces
terraform workspace list

# Select or create workspace
terraform workspace select <workspace> || terraform workspace new <workspace>
```

## Architecture Overview

### Module Dependencies
- **VPC Module** (`modules/vpc/`): Foundation network infrastructure
- **EKS Module** (`modules/eks/`): Kubernetes cluster (depends on VPC)
- **EC2 Module** (`modules/ec2/`): Bastion host and compute instances (depends on VPC)

The modules are connected via data flow:
- VPC outputs (vpc_id, subnet_ids, vpc_cidr) feed into EKS and EC2 modules
- EC2 bastion_host_ip is passed to EKS for security group configuration

### Network Configuration
- **VPC CIDR**: 10.180.0.0/20
- **Region**: ap-northeast-2 (Seoul)
- **Availability Zones**: ap-northeast-2a, ap-northeast-2c
- **3-tier subnet structure**:
  - Public: 10.180.0.0/24, 10.180.1.0/24 (ALB, Bastion)
  - Private App: 10.180.4.0/22, 10.180.8.0/22 (EKS nodes, App servers)
  - Private DB: 10.180.2.0/24, 10.180.3.0/24 (RDS, ElastiCache)

### EKS Configuration
- **Cluster Name**: Defined in EKS module variables
- **Node Groups**:
  - On-demand nodes (t3.large, min/max/desired: 1)
  - Spot nodes (t3.large/medium, min/max: 0/2, desired: 0)
- **Access**: Private endpoint only, API_AND_CONFIG_MAP authentication
- **Addons**: Configurable via eks_addons variable

## Key Configuration Files

### Backend Configuration
- **S3 Backend**: `tfstate-bucket-137406935518`
- **State Key**: `ticketing/terraform.tfstate`
- **AWS Profile**: `tacos`
- **Locking**: Enabled

### Provider Versions
- Terraform: >= 1.5.0
- AWS Provider: ~> 5.0
- Kubernetes Provider: ~> 2.38.0
- Helm Provider: ~> 3.0.2

### Default Variables
- **Region**: ap-northeast-2
- **Profile**: tacos

## Tagging Strategy

All resources are automatically tagged with:
- `Project`: ticket-traffic
- `ManagedBy`: terraform

VPC subnets include Kubernetes-specific tags for ELB discovery:
- Public subnets: `kubernetes.io/role/elb = "1"`
- Private subnets: `kubernetes.io/role/internal-elb = "1"`

## Security Considerations

- EKS cluster uses private endpoint only
- Bastion host IP is configured in EKS security groups
- Private subnets route through NAT gateway for outbound traffic
- Security groups are module-specific (vpc, eks_cluster, eks_node, ec2)

## Codebase Patterns

### Current File Structure
**Root level:**
- `main.tf`: Module declarations and connections
- `var.tf`: Root variables (region, profile)
- `providers.tf`: Provider configurations and versions
- `backend.tf`: S3 backend configuration

**Module structure (as implemented):**
- `modules/vpc/`: `vpc.tf`, `var.tf`, `out.tf`
- `modules/eks/`: `eks.tf`, `iam.tf`, `sg.tf`, `var.tf`
- `modules/ec2/`: `ec2.tf`, `sg.tf`, `var.tf`, `out.tf`

### Naming Patterns (Current Implementation)
- **Resources**: `${var.name}-{resource-type}` (e.g., VPC module uses `${var.name}-vpc`)
- **Files**: Resource-type based (vpc.tf, eks.tf, sg.tf, iam.tf)
- **Variables**: Uses `var.tf` (not `variables.tf`)
- **Outputs**: Uses `out.tf` (not `outputs.tf`)

### Variable Management (Current)
- Default values set directly in `var.tf` files
- No `.tfvars` files in use
- Root variables: `region = "ap-northeast-2"`, `profile = "tacos"`

### Tagging (Current Implementation)
```hcl
default_tags {
  tags = {
    Project = "ticket-traffic"
    ManagedBy = "terraform"
  }
}
```

### Module Dependencies (Actual)
```hcl
# main.tf structure:
module "vpc" {
  source = "./modules/vpc"
}

module "eks" {
  source = "./modules/eks"
  private_subnet_ids = module.vpc.app_subnet
  vpc_id = module.vpc.vpc_id
  vpc_cidr = module.vpc.vpc_cidr
  bastion_host_ip = module.ec2.bastion_host_ip
}

module "ec2" {
  source = "./modules/ec2"
  vpc_id = module.vpc.vpc_id
  public_subnet = module.vpc.public_subnet
}
```

### Coding Standards (Team Rules)
- **Preferred resource naming**: `${var.project_name}-{resource_type}`
- **Sensitive data**: Use SSM Parameter Store
- **File naming**: Function-based separation preferred
- **No hardcoded secrets**: All sensitive values externalized
- **Documentation**: When implementing AWS resources, create spec documents in `docs/` directory with resource specifications, configurations, and usage examples