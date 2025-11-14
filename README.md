# Terraform EKS Infrastructure - pic-kabu Project

## 📋 Overview

This repository contains Terraform configurations for deploying and managing AWS EKS (Elastic Kubernetes Service) infrastructure for the **pic-kabu** project. The infrastructure is organized into two environments: **Development (dev)** and **Production (prod)**, each with specific configurations optimized for their respective purposes.

## 🏗️ Architecture

### Common Components (Both Environments)

Both dev and prod environments share the following architectural components:

1. **VPC**: Custom Virtual Private Cloud with public and private subnets across multiple availability zones
2. **EKS Cluster**: Managed Kubernetes cluster with version 1.34
3. **Node Groups**: EC2 instances (ARM-based t4g.large) for running workloads
4. **ECR Repositories**: Container image registries for application services
5. **Identity Providers**: GitHub OIDC integration for CI/CD pipelines
6. **Security Groups**: Network access controls for cluster and nodes
7. **IAM Roles & Policies**: Service accounts with IRSA (IAM Roles for Service Accounts)

---

## 🔧 Development Environment Architecture

### Network Architecture (Dev)

```
┌─────────────────────────────────────────────────────────────┐
│                    VPC: 10.0.0.0/16                         │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────────┐          ┌──────────────────┐        │
│  │   AZ-1           │          │   AZ-2           │        │
│  │                  │          │                  │        │
│  │  Public Subnet   │          │  Public Subnet   │        │
│  │  10.0.0.0/24     │          │  10.0.1.0/24     │        │
│  │  ┌────────────┐  │          │  ┌────────────┐  │        │
│  │  │ EKS Nodes  │  │          │  │ EKS Nodes  │  │        │
│  │  │ (t4g.large)│  │          │  │ (t4g.large)│  │        │
│  │  └────────────┘  │          │  └────────────┘  │        │
│  └──────────────────┘          └──────────────────┘        │
│                                                              │
│  ┌──────────────────┐          ┌──────────────────┐        │
│  │  Private Subnet  │          │  Private Subnet  │        │
│  │  10.0.3.0/24     │          │  10.0.4.0/24     │        │
│  │  ┌────────────┐  │          │  ┌────────────┐  │        │
│  │  │ PostgreSQL │  │          │  │            │  │        │
│  │  │   (RDS)    │  │          │  │            │  │        │
│  │  └────────────┘  │          │  └────────────┘  │        │
│  └──────────────────┘          └──────────────────┘        │
│                                                              │
│  Note: NAT Gateway is DISABLED for cost savings             │
└─────────────────────────────────────────────────────────────┘
```

### Key Features (Dev)

- **VPC CIDR**: `10.0.0.0/16`
- **NAT Gateway**: Disabled (cost optimization)
- **Node Groups**: 
  - **On-Demand**: 1-3 nodes (t4g.large ARM instances)
  - **Spot**: 1-4 nodes (t4g.large ARM instances, cost-optimized)
- **Nodes Deployed In**: Public subnets (direct internet access)
- **Database**: 
  - Single RDS PostgreSQL instance (db.t3.micro)
  - Database: `kabu_dev`, User: `kabudev`
  - SSL disabled for development convenience
  - Backup retention: 3 days
  - No deletion protection
- **Redis**: 
  - Standalone deployment via Helm
  - No authentication
  - No persistence (memory only)
  - Namespace: `pic-kabu-dev`
- **Additional Components**:
  - AWS Load Balancer Controller (Helm)
  - ArgoCD (GitOps tool for continuous delivery)
  - EBS CSI Driver with IRSA
  - Metrics Server addon
  
### EKS Addons (Dev)

- CoreDNS (latest)
- EKS Pod Identity Agent (latest)
- Kube-proxy (latest)
- VPC CNI (v1.20.4)
- AWS EBS CSI Driver (latest, with IRSA)
- Metrics Server (latest)

### Access Configuration (Dev)

- **Cluster Access**: 
  - IAM user: `cong.tv@human-brain.ai` with Admin policy
  - Public endpoint: Enabled (accessible from anywhere)
  - Private endpoint: Enabled

---

## 🚀 Production Environment Architecture

### Network Architecture (Prod)

```
┌─────────────────────────────────────────────────────────────┐
│                    VPC: 10.1.0.0/16                         │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────────┐          ┌──────────────────┐        │
│  │   AZ-1           │          │   AZ-2           │        │
│  │                  │          │                  │        │
│  │  Public Subnet   │          │  Public Subnet   │        │
│  │  10.1.0.0/24     │          │  10.1.1.0/24     │        │
│  │  ┌────────────┐  │          │  ┌────────────┐  │        │
│  │  │ NAT Gateway│  │          │  │            │  │        │
│  │  └────────────┘  │          │  └────────────┘  │        │
│  └──────────────────┘          └──────────────────┘        │
│         │                              │                    │
│  ┌──────────────────┐          ┌──────────────────┐        │
│  │  Private Subnet  │          │  Private Subnet  │        │
│  │  10.1.3.0/24     │          │  10.1.4.0/24     │        │
│  │  ┌────────────┐  │          │  ┌────────────┐  │        │
│  │  │ EKS Nodes  │  │          │  │ EKS Nodes  │  │        │
│  │  │ (t4g.large)│  │          │  │ (t4g.large)│  │        │
│  │  └────────────┘  │          │  └────────────┘  │        │
│  │  ┌────────────┐  │          │  ┌────────────┐  │        │
│  │  │   Aurora   │  │          │  │   Aurora   │  │        │
│  │  │  Primary   │  │          │  │   Replica  │  │        │
│  │  └────────────┘  │          │  └────────────┘  │        │
│  └──────────────────┘          └──────────────────┘        │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Key Features (Prod)

- **VPC CIDR**: `10.1.0.0/16`
- **NAT Gateway**: Enabled (single NAT for cost optimization, all private subnets route through AZ-1)
- **Node Groups**: 
  - **On-Demand Only**: 2-5 nodes (t4g.large ARM instances)
  - No Spot instances (production stability)
- **Nodes Deployed In**: Private subnets (enhanced security)
- **Database**: 
  - Aurora PostgreSQL Cluster (db.t3.medium)
  - Database: `kabuai`, User: `app`
  - 1 Writer + 1 Read Replica
  - Backup retention: 7 days
  - Deletion protection: Enabled
  - SSL/TLS enabled by default
- **Additional Components**:
  - EBS CSI Driver addon (managed by AWS)
  - No ArgoCD (production deployments via separate process)
  - No AWS Load Balancer Controller in current config
  - Metrics Server addon

### EKS Addons (Prod)

- CoreDNS (latest)
- EKS Pod Identity Agent (latest)
- Kube-proxy (latest)
- VPC CNI (latest)
- AWS EBS CSI Driver (latest managed version)
- Metrics Server (latest)

### Access Configuration (Prod)

- **Cluster Access**: 
  - Public endpoint: Enabled with IP whitelist restrictions
    - `14.243.87.5/32`
    - `117.3.39.192/32`
    - `14.252.145.82/32`
  - Private endpoint: Enabled

---

## 📊 Environment Comparison Table

| Feature | Development (dev) | Production (prod) |
|---------|------------------|-------------------|
| **VPC CIDR** | 10.0.0.0/16 | 10.1.0.0/16 |
| **NAT Gateway** | ❌ Disabled | ✅ Enabled (Single) |
| **Node Placement** | Public Subnets | Private Subnets |
| **Node Groups** | On-Demand + Spot | On-Demand Only |
| **Min Nodes** | 1 (On-Demand) + 1 (Spot) | 2 |
| **Max Nodes** | 3 (On-Demand) + 4 (Spot) | 5 |
| **Database** | RDS Single Instance | Aurora Cluster (HA) |
| **DB Instance** | db.t3.micro | db.t3.medium |
| **DB Replicas** | 0 | 1 Read Replica |
| **DB Backup** | 3 days | 7 days |
| **Deletion Protection** | ❌ No | ✅ Yes |
| **Redis** | ✅ Helm (Standalone) | ❌ Not Deployed |
| **ArgoCD** | ✅ Installed | ❌ Not Deployed |
| **AWS LB Controller** | ✅ Installed | ❌ Not Deployed |
| **Public Access** | ✅ Open (0.0.0.0/0) | 🔒 IP Whitelisted |
| **SSL Enforcement** | ❌ Disabled | ✅ Enabled |
| **Cost Profile** | 💰 Low (Optimized) | 💰💰 Medium (Production) |

---

## 📦 Modules Description

### 1. `modules/vpc`
- Creates AWS VPC with public and private subnets
- Configures subnet tags for EKS load balancer discovery
- Optional NAT Gateway for private subnet internet access
- Enables DNS hostnames for EKS integration

**Key Outputs**: `vpc_id`, `public_subnets`, `private_subnets`

### 2. `modules/eks`
- Provisions EKS cluster with specified Kubernetes version
- Configures managed node groups (on-demand and/or spot)
- Sets up IRSA (IAM Roles for Service Accounts)
- Installs essential EKS addons
- Configures cluster access entries

**Key Outputs**: `cluster_name`, `cluster_endpoint`, `oidc_provider_arn`, `node_security_group_id`

### 3. `modules/aws_lb_controller`
- Deploys AWS Load Balancer Controller via Helm
- Creates IRSA role for the controller
- Enables automatic ALB/NLB provisioning from Kubernetes Ingress resources

**Key Outputs**: `irsa_role_arn`

### 4. `modules/argocd`
- Installs ArgoCD via Helm chart
- Creates dedicated namespace
- Enables GitOps-based application deployment
- Access via port-forward: `kubectl port-forward -n argocd svc/argo-cd-argocd-server 8080:443`

**Key Outputs**: None (Helm release resource)

### 5. `modules/ecr_repos`
- Creates ECR repositories for application container images
- Configures lifecycle policies (retains last N images)
- Optional image scanning on push

**Key Outputs**: `repository_arns`, `repository_urls`

### 6. `modules/identity_providers`
- Sets up GitHub OIDC provider
- Creates IAM role for GitHub Actions
- Grants ECR push/pull permissions
- Enables secure CI/CD pipelines without long-lived credentials

**Key Outputs**: `github_actions_role_arn`, `oidc_provider_arn`

### 7. `modules/postgres_single`
- Deploys single-instance RDS PostgreSQL (dev only)
- Creates security group and subnet group
- Generates random password stored in AWS Secrets Manager
- Configurable parameter group for custom settings

**Key Outputs**: `db_endpoint`, `db_name`, `db_username`, `secret_arn`

### 8. `modules/aurora_postgres`
- Deploys Aurora PostgreSQL cluster (prod only)
- Creates writer and reader instances
- High availability with automatic failover
- Encrypted credentials in AWS Secrets Manager

**Key Outputs**: `cluster_endpoint`, `reader_endpoint`, `db_name`, `master_username`, `secret_arn`

---

## 🛠️ Prerequisites

Before deploying this infrastructure, ensure you have:

1. **AWS CLI** installed and configured
   ```bash
   aws --version
   aws configure --profile stock
   ```

2. **Terraform** version >= 1.3.0
   ```bash
   terraform --version
   ```

3. **kubectl** for Kubernetes management
   ```bash
   kubectl version --client
   ```

4. **Helm** version >= 3.0 (for chart deployments)
   ```bash
   helm version
   ```

5. **AWS Profile** named `stock` configured with appropriate credentials
   - Profile should have permissions to create VPC, EKS, RDS, IAM, ECR, etc.

6. **Backend Infrastructure** (S3 bucket and DynamoDB table)
   - Run `./script_backend.sh` to create backend resources

---

## 🚀 Deployment Instructions

### Initial Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd terraform-eks
   ```

2. **Create Backend Infrastructure** (first-time only)
   ```bash
   chmod +x script_backend.sh
   ./script_backend.sh
   ```
   This creates:
   - S3 bucket: `pic-kabu-terraform-state`
   - DynamoDB table: `pic-kabu-terraform-lock`

### Deploy Development Environment

```bash
cd envs/dev
export AWS_PROFILE=stock
terraform init
terraform plan
terraform apply
```

After successful deployment:

```bash
# Configure kubectl
aws eks update-kubeconfig --region ap-northeast-1 --name pic-kabu-dev-eks --profile stock

# Verify cluster access
kubectl get nodes

# Get ArgoCD admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d; echo

# Access ArgoCD UI
kubectl port-forward -n argocd svc/argo-cd-argocd-server 8080:443
# Open browser: https://localhost:8080
# Username: admin
# Password: <from previous command>
```

### Deploy Production Environment

```bash
cd envs/prod
export AWS_PROFILE=stock
terraform init
terraform plan
terraform apply
```

After successful deployment:

```bash
# Configure kubectl
aws eks update-kubeconfig --region ap-northeast-1 --name pic-kabu-prod-eks --profile stock

# Verify cluster access (only from whitelisted IPs)
kubectl get nodes
```

---

## 🔐 Security Considerations

### Development Environment
- ⚠️ Nodes in public subnets (for development convenience)
- ⚠️ PostgreSQL SSL disabled
- ⚠️ Redis without authentication
- ⚠️ Public EKS endpoint without IP restrictions
- ✅ Secrets stored in AWS Secrets Manager
- ✅ Security groups restrict database access to EKS nodes only

### Production Environment
- ✅ Nodes in private subnets with NAT Gateway
- ✅ PostgreSQL SSL enabled by default
- ✅ EKS endpoint restricted to specific IPs
- ✅ Deletion protection enabled
- ✅ 7-day backup retention
- ✅ High availability with Aurora replicas
- ✅ IAM roles with least privilege principle
- ✅ Encrypted Secrets Manager for credentials

---

## 📝 Managing ECR Repositories

The following ECR repositories are created for application images:

1. `pic-kabu-analysis-agent-fe-dev-service`
2. `pic-kabu-bff-dev-service`
3. `pic-kabu-ta-dev-service`
4. `pic-kabu-ai-graph-dev-service`

### Push Images via GitHub Actions

Use the GitHub OIDC role for authentication:

```yaml
# Example GitHub Actions workflow
- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: arn:aws:iam::<account-id>:role/pic-kabu-dev-gh-actions-role
    aws-region: ap-northeast-1

- name: Login to Amazon ECR
  uses: aws-actions/amazon-ecr-login@v2

- name: Build and push
  run: |
    docker build -t <account-id>.dkr.ecr.ap-northeast-1.amazonaws.com/pic-kabu-bff-dev-service:latest .
    docker push <account-id>.dkr.ecr.ap-northeast-1.amazonaws.com/pic-kabu-bff-dev-service:latest
```

---

## 🔄 Maintenance & Operations

### Updating Terraform Modules

```bash
cd envs/dev  # or envs/prod
terraform get -update
terraform plan
terraform apply
```

### Scaling Node Groups

Edit `envs/<env>/main.tf` and modify node group configuration:

```hcl
node_groups = {
  on_demand = {
    min_size     = 2  # Change as needed
    desired_size = 3
    max_size     = 5
  }
}
```

Then apply:
```bash
terraform apply
```

### Upgrading EKS Cluster Version

1. Update `cluster_version` in `envs/<env>/variables.tf`
2. Plan and apply changes
3. Update node groups (Terraform will handle rolling updates)
4. Verify all addons are compatible

```bash
terraform plan
terraform apply
kubectl get nodes
```

### Database Connection

**Development:**
```bash
# Get database endpoint
terraform output postgres_endpoint

# Get credentials from Secrets Manager
aws secretsmanager get-secret-value \
  --secret-id pic-kabu-dev-postgres-credentials \
  --profile stock \
  --query SecretString --output text | jq -r '.password'
```

**Production:**
```bash
# Get Aurora endpoints
terraform output aurora_cluster_endpoint  # Writer
terraform output aurora_reader_endpoint   # Reader

# Get credentials
aws secretsmanager get-secret-value \
  --secret-id pic-kabu-prod-aurora-master-password \
  --profile stock \
  --query SecretString --output text
```

---

## 🧹 Cleanup

To destroy resources (⚠️ **CAUTION: This will delete all resources**):

```bash
cd envs/dev  # or envs/prod
terraform destroy
```

**Note**: Production environment has deletion protection enabled on the database. You'll need to disable it first or skip final snapshot manually.

---

## 📚 Additional Resources

- [Amazon EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)

---

## 🤝 Contributing

When making changes:

1. Create a feature branch
2. Test changes in dev environment first
3. Document any new variables or outputs
4. Update this README if architecture changes
5. Submit pull request for review

---

## 📧 Support

For questions or issues, contact: `cong.tv@human-brain.ai`

---

## 📄 License

Internal project for pic-kabu. All rights reserved.

