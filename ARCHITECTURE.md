# Architecture Documentation - pic-kabu EKS Infrastructure

## 📐 Architecture Overview

This document provides detailed architecture information for the pic-kabu EKS infrastructure, covering both development and production environments.

---

## 🌐 High-Level Architecture

### System Components Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│                          GitHub Repository                          │
│                     (Application Source Code)                       │
└────────────────┬────────────────────────────────────────────────────┘
                 │
                 │ GitHub Actions (CI/CD)
                 │ via OIDC Authentication
                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│                       Amazon ECR (Container Registry)               │
│  ┌─────────────────────┐  ┌─────────────────────┐                  │
│  │ analysis-agent-fe   │  │ bff-service         │                  │
│  └─────────────────────┘  └─────────────────────┘                  │
│  ┌─────────────────────┐  ┌─────────────────────┐                  │
│  │ ta-service          │  │ ai-graph-service    │                  │
│  └─────────────────────┘  └─────────────────────┘                  │
└────────────────┬────────────────────────────────────────────────────┘
                 │
                 │ Image Pull
                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│                         Amazon EKS Cluster                          │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                     Control Plane (Managed)                   │  │
│  │  • API Server  • Scheduler  • Controller Manager  • etcd     │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                      Worker Nodes (EC2)                       │  │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐     │  │
│  │  │   Pod    │  │   Pod    │  │   Pod    │  │   Pod    │     │  │
│  │  │ Service  │  │ Service  │  │ Service  │  │ Service  │     │  │
│  │  └──────────┘  └──────────┘  └──────────┘  └──────────┘     │  │
│  │  ┌──────────┐  ┌──────────┐                                  │  │
│  │  │  Redis   │  │  ArgoCD  │   (Dev only)                     │  │
│  │  └──────────┘  └──────────┘                                  │  │
│  └──────────────────────────────────────────────────────────────┘  │
└────────────────┬────────────────────────────────────────────────────┘
                 │
                 │ Database Connection
                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        Database Layer                               │
│  Dev:  RDS PostgreSQL (Single Instance)                            │
│  Prod: Aurora PostgreSQL (Writer + Reader Replica)                 │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 🏗️ Development Environment - Detailed Architecture

### Network Topology (Dev)

```
Region: ap-northeast-1 (Tokyo)
┌────────────────────────────────────────────────────────────────────────┐
│ VPC: pic-kabu-dev-vpc (10.0.0.0/16)                                   │
├────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌─────────────────────────────┐  ┌─────────────────────────────┐    │
│  │ Availability Zone 1          │  │ Availability Zone 2          │    │
│  │                              │  │                              │    │
│  │ ┌─────────────────────────┐ │  │ ┌─────────────────────────┐ │    │
│  │ │ Public Subnet           │ │  │ │ Public Subnet           │ │    │
│  │ │ 10.0.0.0/24             │ │  │ │ 10.0.1.0/24             │ │    │
│  │ │                         │ │  │ │                         │ │    │
│  │ │ ┌─────────────────────┐ │ │  │ │ ┌─────────────────────┐ │ │    │
│  │ │ │ EKS Node Group      │ │ │  │ │ │ EKS Node Group      │ │ │    │
│  │ │ │ (On-Demand)         │ │ │  │ │ │ (Spot)              │ │ │    │
│  │ │ │                     │ │ │  │ │ │                     │ │ │    │
│  │ │ │ • t4g.large (ARM)   │ │ │  │ │ │ • t4g.large (ARM)   │ │ │    │
│  │ │ │ • Min: 1, Max: 3    │ │ │  │ │ │ • Min: 1, Max: 4    │ │ │    │
│  │ │ │ • Public IP         │ │ │  │ │ │ • Public IP         │ │ │    │
│  │ │ └─────────────────────┘ │ │  │ │ └─────────────────────┘ │ │    │
│  │ │                         │ │  │ │                         │ │    │
│  │ │ Internet Gateway ←──────┼─┼──┼─┼─────────────────────────┼─┼──► │
│  │ └─────────────────────────┘ │  │ └─────────────────────────┘ │ Internet
│  │                              │  │                              │    │
│  │ ┌─────────────────────────┐ │  │ ┌─────────────────────────┐ │    │
│  │ │ Private Subnet          │ │  │ │ Private Subnet          │ │    │
│  │ │ 10.0.3.0/24             │ │  │ │ 10.0.4.0/24             │ │    │
│  │ │                         │ │  │ │                         │ │    │
│  │ │ ┌─────────────────────┐ │ │  │ │                         │ │    │
│  │ │ │ RDS PostgreSQL      │ │ │  │ │   (Available for      │ │    │
│  │ │ │ db.t3.micro         │ │ │  │ │    future resources)  │ │    │
│  │ │ │ kabu_dev DB         │ │ │  │ │                         │ │    │
│  │ │ │ SSL: Disabled       │ │ │  │ │                         │ │    │
│  │ │ └─────────────────────┘ │ │  │ │                         │ │    │
│  │ └─────────────────────────┘ │  │ └─────────────────────────┘ │    │
│  └─────────────────────────────┘  └─────────────────────────────┘    │
│                                                                         │
│  Note: NAT Gateway NOT provisioned (cost saving measure)              │
└────────────────────────────────────────────────────────────────────────┘
```

### EKS Cluster Components (Dev)

```
┌────────────────────────────────────────────────────────────────────┐
│              EKS Cluster: pic-kabu-dev-eks (v1.34)                │
├────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  Control Plane (AWS Managed)                                       │
│  ┌──────────────────────────────────────────────────────────────┐ │
│  │ • API Server (Public + Private endpoints)                    │ │
│  │ • Scheduler                                                   │ │
│  │ • Controller Manager                                          │ │
│  │ • etcd (Multi-AZ, encrypted)                                 │ │
│  └──────────────────────────────────────────────────────────────┘ │
│                                                                     │
│  Add-ons                                                            │
│  ┌──────────────────────────────────────────────────────────────┐ │
│  │ • CoreDNS (latest)                                           │ │
│  │ • kube-proxy (latest)                                        │ │
│  │ • VPC CNI (v1.20.4-eksbuild.2)                              │ │
│  │ • EBS CSI Driver (latest, with IRSA)                        │ │
│  │ • Pod Identity Agent (latest)                                │ │
│  │ • Metrics Server (latest)                                    │ │
│  └──────────────────────────────────────────────────────────────┘ │
│                                                                     │
│  Data Plane (Worker Nodes)                                         │
│  ┌──────────────────────────────────────────────────────────────┐ │
│  │ Node Group: on_demand                                        │ │
│  │ • Instance Type: t4g.large (2 vCPU, 8 GB RAM, ARM64)        │ │
│  │ • AMI: AL2023_ARM_64_STANDARD                                │ │
│  │ • Capacity: ON_DEMAND                                        │ │
│  │ • Min: 1, Desired: 1, Max: 3                                │ │
│  │ • Labels: lifecycle=on-demand, workload=general              │ │
│  │ • IAM Policies: EBS CSI Driver, SSM Managed Instance         │ │
│  └──────────────────────────────────────────────────────────────┘ │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐ │
│  │ Node Group: spot                                             │ │
│  │ • Instance Type: t4g.large (2 vCPU, 8 GB RAM, ARM64)        │ │
│  │ • AMI: AL2023_ARM_64_STANDARD                                │ │
│  │ • Capacity: SPOT (cost-optimized, can be interrupted)        │ │
│  │ • Min: 1, Desired: 1, Max: 4                                │ │
│  │ • Labels: lifecycle=spot, workload=general                   │ │
│  │ • IAM Policies: EBS CSI Driver, SSM Managed Instance         │ │
│  └──────────────────────────────────────────────────────────────┘ │
│                                                                     │
│  Helm Releases                                                      │
│  ┌──────────────────────────────────────────────────────────────┐ │
│  │ • AWS Load Balancer Controller (kube-system namespace)       │ │
│  │   - Manages ALB/NLB for Ingress resources                    │ │
│  │   - IRSA role for AWS API access                             │ │
│  │                                                               │ │
│  │ • ArgoCD (argocd namespace)                                  │ │
│  │   - GitOps continuous delivery tool                          │ │
│  │   - Access: kubectl port-forward                             │ │
│  │                                                               │ │
│  │ • Redis (pic-kabu-dev namespace)                             │ │
│  │   - Standalone, no auth, no persistence                      │ │
│  │   - Bitnami Helm chart v23.2.12                              │ │
│  └──────────────────────────────────────────────────────────────┘ │
│                                                                     │
│  Security Groups                                                    │
│  ┌──────────────────────────────────────────────────────────────┐ │
│  │ • pic-kabu-dev-cluster-sg (EKS Control Plane)                │ │
│  │ • pic-kabu-dev-node-sg (Worker Nodes)                        │ │
│  │   - Allows inbound from control plane                        │ │
│  │   - Allows node-to-node communication                        │ │
│  │   - Allows outbound to internet                              │ │
│  └──────────────────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────────────────┘
```

### Data Layer (Dev)

```
┌────────────────────────────────────────────────────────────────────┐
│                    Database: RDS PostgreSQL                        │
├────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  Instance Details                                                   │
│  ┌──────────────────────────────────────────────────────────────┐ │
│  │ • Identifier: pic-kabu-dev-postgres                          │ │
│  │ • Engine: postgres (PostgreSQL 17)                           │ │
│  │ • Instance Class: db.t3.micro                                │ │
│  │ • Storage: 20 GB (gp2)                                       │ │
│  │ • Multi-AZ: No (Single instance)                             │ │
│  └──────────────────────────────────────────────────────────────┘ │
│                                                                     │
│  Configuration                                                      │
│  ┌──────────────────────────────────────────────────────────────┐ │
│  │ • Database Name: kabu_dev                                    │ │
│  │ • Master Username: kabudev                                   │ │
│  │ • Password: Stored in Secrets Manager                        │ │
│  │ • Port: 5432                                                 │ │
│  │ • Parameter Group: postgres17                                │ │
│  │ • SSL/TLS: Disabled (rds.force_ssl = 0)                     │ │
│  └──────────────────────────────────────────────────────────────┘ │
│                                                                     │
│  Backup & Recovery                                                  │
│  ┌──────────────────────────────────────────────────────────────┐ │
│  │ • Backup Retention: 3 days                                   │ │
│  │ • Automated Backups: Enabled                                 │ │
│  │ • Deletion Protection: Disabled                              │ │
│  │ • Skip Final Snapshot: true                                  │ │
│  └──────────────────────────────────────────────────────────────┘ │
│                                                                     │
│  Network & Security                                                 │
│  ┌──────────────────────────────────────────────────────────────┐ │
│  │ • Subnet Group: pic-kabu-dev-rds-subnets                     │ │
│  │ • Subnets: Private subnets (10.0.3.0/24, 10.0.4.0/24)       │ │
│  │ • Security Group: pic-kabu-dev-rds-sg                        │ │
│  │ • Publicly Accessible: No                                    │ │
│  │ • Access: Only from pic-kabu-dev-node-sg                     │ │
│  └──────────────────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────────┐
│                      Cache: Redis (Helm)                           │
├────────────────────────────────────────────────────────────────────┤
│  • Architecture: Standalone                                         │
│  • Authentication: Disabled                                         │
│  • Persistence: Disabled (ephemeral)                               │
│  • Namespace: pic-kabu-dev                                          │
│  • Chart: bitnami/redis v23.2.12                                   │
└────────────────────────────────────────────────────────────────────┘
```

---

## 🚀 Production Environment - Detailed Architecture

### Network Topology (Prod)

```
Region: ap-northeast-1 (Tokyo)
┌────────────────────────────────────────────────────────────────────────┐
│ VPC: pic-kabu-prod-vpc (10.1.0.0/16)                                  │
├────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌─────────────────────────────┐  ┌─────────────────────────────┐    │
│  │ Availability Zone 1          │  │ Availability Zone 2          │    │
│  │                              │  │                              │    │
│  │ ┌─────────────────────────┐ │  │ ┌─────────────────────────┐ │    │
│  │ │ Public Subnet           │ │  │ │ Public Subnet           │ │    │
│  │ │ 10.1.0.0/24             │ │  │ │ 10.1.1.0/24             │ │    │
│  │ │                         │ │  │ │                         │ │    │
│  │ │ ┌─────────────────────┐ │ │  │ │                         │ │    │
│  │ │ │   NAT Gateway       │ │ │  │ │  (No NAT - cost opt)   │ │    │
│  │ │ │   (Elastic IP)      │ │ │  │ │                         │ │    │
│  │ │ └─────────────────────┘ │ │  │ │                         │ │    │
│  │ │           │             │ │  │ │                         │ │    │
│  │ │           │             │ │  │ │                         │ │    │
│  │ │ Internet Gateway ←──────┼─┼──┼─┼─────────────────────────┼─┼──► │
│  │ └───────────┬─────────────┘ │  │ └─────────────────────────┘ │ Internet
│  │             │                │  │             │                │    │
│  │             ▼                │  │             ▼                │    │
│  │ ┌─────────────────────────┐ │  │ ┌─────────────────────────┐ │    │
│  │ │ Private Subnet          │ │  │ │ Private Subnet          │ │    │
│  │ │ 10.1.3.0/24             │ │  │ │ 10.1.4.0/24             │ │    │
│  │ │                         │ │  │ │                         │ │    │
│  │ │ ┌─────────────────────┐ │ │  │ │ ┌─────────────────────┐ │ │    │
│  │ │ │ EKS Node Group      │ │ │  │ │ │ EKS Node Group      │ │ │    │
│  │ │ │ (On-Demand)         │ │ │  │ │ │ (On-Demand)         │ │ │    │
│  │ │ │                     │ │ │  │ │ │                     │ │ │    │
│  │ │ │ • t4g.large (ARM)   │ │ │  │ │ │ • t4g.large (ARM)   │ │ │    │
│  │ │ │ • Min: 2, Max: 5    │ │ │  │ │ │ • Private IP only   │ │ │    │
│  │ │ │ • Private IP only   │ │ │  │ │ │                     │ │ │    │
│  │ │ └─────────────────────┘ │ │  │ │ └─────────────────────┘ │ │    │
│  │ │                         │ │  │ │                         │ │    │
│  │ │ ┌─────────────────────┐ │ │  │ │ ┌─────────────────────┐ │ │    │
│  │ │ │ Aurora Primary      │ │ │  │ │ │ Aurora Replica      │ │ │    │
│  │ │ │ (Writer Endpoint)   │ │ │  │ │ │ (Reader Endpoint)   │ │ │    │
│  │ │ │ db.t3.medium        │ │ │  │ │ │ db.t3.medium        │ │ │    │
│  │ │ │ PostgreSQL          │ │ │  │ │ │ PostgreSQL          │ │ │    │
│  │ │ └─────────────────────┘ │ │  │ │ └─────────────────────┘ │ │    │
│  │ └─────────────────────────┘ │  │ └─────────────────────────┘ │    │
│  └─────────────────────────────┘  └─────────────────────────────┘    │
│                                                                         │
│  Note: Single NAT Gateway in AZ-1 serves both private subnets         │
└────────────────────────────────────────────────────────────────────────┘
```

### EKS Cluster Components (Prod)

```
┌────────────────────────────────────────────────────────────────────┐
│             EKS Cluster: pic-kabu-prod-eks (v1.34)                │
├────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  Control Plane (AWS Managed)                                       │
│  ┌──────────────────────────────────────────────────────────────┐ │
│  │ • API Server (Public + Private endpoints)                    │ │
│  │   - Public access restricted to whitelisted IPs              │ │
│  │   - 14.243.87.5/32, 117.3.39.192/32, 14.252.145.82/32       │ │
│  │ • Scheduler                                                   │ │
│  │ • Controller Manager                                          │ │
│  │ • etcd (Multi-AZ, encrypted)                                 │ │
│  └──────────────────────────────────────────────────────────────┘ │
│                                                                     │
│  Add-ons                                                            │
│  ┌──────────────────────────────────────────────────────────────┐ │
│  │ • CoreDNS (latest)                                           │ │
│  │ • kube-proxy (latest)                                        │ │
│  │ • VPC CNI (latest)                                           │ │
│  │ • EBS CSI Driver (latest managed addon)                      │ │
│  │ • Pod Identity Agent (latest)                                │ │
│  │ • Metrics Server (latest)                                    │ │
│  └──────────────────────────────────────────────────────────────┘ │
│                                                                     │
│  Data Plane (Worker Nodes)                                         │
│  ┌──────────────────────────────────────────────────────────────┐ │
│  │ Node Group: on_demand (Production-grade)                     │ │
│  │ • Instance Type: t4g.large (2 vCPU, 8 GB RAM, ARM64)        │ │
│  │ • AMI: AL2023_ARM_64_STANDARD                                │ │
│  │ • Capacity: ON_DEMAND (no spot for stability)                │ │
│  │ • Min: 2, Desired: 3, Max: 5                                │ │
│  │ • Labels: lifecycle=on-demand, workload=general              │ │
│  │ • IAM Policies: EBS CSI Driver                               │ │
│  │ • Deployment: Private subnets only                           │ │
│  └──────────────────────────────────────────────────────────────┘ │
│                                                                     │
│  Security Groups                                                    │
│  ┌──────────────────────────────────────────────────────────────┐ │
│  │ • pic-kabu-prod-cluster-sg (EKS Control Plane)               │ │
│  │   - Inbound: Restricted to whitelisted IPs                   │ │
│  │ • pic-kabu-prod-node-sg (Worker Nodes)                       │ │
│  │   - Inbound from control plane and peer nodes                │ │
│  │   - Outbound via NAT Gateway                                 │ │
│  └──────────────────────────────────────────────────────────────┘ │
│                                                                     │
│  Note: No Helm releases (ArgoCD, Redis) deployed in prod           │
└────────────────────────────────────────────────────────────────────┘
```

### Data Layer (Prod)

```
┌────────────────────────────────────────────────────────────────────┐
│                Database: Aurora PostgreSQL Cluster                 │
├────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  Cluster Details                                                    │
│  ┌──────────────────────────────────────────────────────────────┐ │
│  │ • Cluster ID: pic-kabu-prod-aurora-pg                        │ │
│  │ • Engine: aurora-postgresql                                  │ │
│  │ • Database Name: kabuai                                      │ │
│  │ • Master Username: app                                       │ │
│  │ • Password: Stored in Secrets Manager                        │ │
│  └──────────────────────────────────────────────────────────────┘ │
│                                                                     │
│  Instances                                                          │
│  ┌──────────────────────────────────────────────────────────────┐ │
│  │ Writer Instance (pic-kabu-prod-aurora-pg-1)                  │ │
│  │ • Instance Class: db.t3.medium                               │ │
│  │ • Availability Zone: ap-northeast-1a                         │ │
│  │ • Endpoint: <cluster>.cluster-xxx.rds.amazonaws.com          │ │
│  │ • Role: Primary (Read/Write)                                 │ │
│  └──────────────────────────────────────────────────────────────┘ │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐ │
│  │ Reader Instance (pic-kabu-prod-aurora-pg-replica-1)          │ │
│  │ • Instance Class: db.t3.medium                               │ │
│  │ • Availability Zone: ap-northeast-1c                         │ │
│  │ • Endpoint: <cluster>.cluster-ro-xxx.rds.amazonaws.com       │ │
│  │ • Role: Read Replica (Read-only)                             │ │
│  └──────────────────────────────────────────────────────────────┘ │
│                                                                     │
│  Backup & Recovery                                                  │
│  ┌──────────────────────────────────────────────────────────────┐ │
│  │ • Backup Retention: 7 days                                   │ │
│  │ • Automated Backups: Enabled                                 │ │
│  │ • Point-in-Time Recovery: Enabled                            │ │
│  │ • Deletion Protection: Enabled                               │ │
│  │ • Skip Final Snapshot: true (configurable)                   │ │
│  └──────────────────────────────────────────────────────────────┘ │
│                                                                     │
│  High Availability                                                  │
│  ┌──────────────────────────────────────────────────────────────┐ │
│  │ • Multi-AZ: Yes (Writer + Reader in different AZs)           │ │
│  │ • Automatic Failover: Yes (<30 seconds typical)              │ │
│  │ • Storage Replication: 6 copies across 3 AZs                 │ │
│  │ • Self-healing: Automatic block-level repair                 │ │
│  └──────────────────────────────────────────────────────────────┘ │
│                                                                     │
│  Network & Security                                                 │
│  ┌──────────────────────────────────────────────────────────────┐ │
│  │ • Subnet Group: pic-kabu-prod-aurora-subnets                 │ │
│  │ • Subnets: Private subnets (10.1.3.0/24, 10.1.4.0/24)       │ │
│  │ • Security Group: pic-kabu-prod-aurora-sg                    │ │
│  │ • Publicly Accessible: No                                    │ │
│  │ • Access: Only from pic-kabu-prod-node-sg                    │ │
│  │ • Encryption: AWS managed keys                               │ │
│  │ • SSL/TLS: Enforced by default                               │ │
│  └──────────────────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────────────────┘
```

---

## 🔒 Security Architecture

### IAM Roles & Service Accounts

```
┌────────────────────────────────────────────────────────────────────┐
│                    IAM Roles for Service Accounts (IRSA)           │
├────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐ │
│  │ EBS CSI Driver IRSA (Dev)                                    │ │
│  │ • Role Name: pic-kabu-dev-irsa-ebs-csi                       │ │
│  │ • Service Account: kube-system:ebs-csi-controller-sa         │ │
│  │ • Policy: AmazonEBSCSIDriverPolicy                           │ │
│  │ • Purpose: Manage EBS volumes for persistent storage         │ │
│  └──────────────────────────────────────────────────────────────┘ │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐ │
│  │ AWS Load Balancer Controller IRSA (Dev)                      │ │
│  │ • Role Name: pic-kabu-dev-irsa-aws-lb-controller             │ │
│  │ • Service Account: kube-system:aws-load-balancer-controller  │ │
│  │ • Policy: AWSLoadBalancerControllerIAMPolicy                 │ │
│  │ • Purpose: Manage ALB/NLB for Ingress resources              │ │
│  └──────────────────────────────────────────────────────────────┘ │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐ │
│  │ GitHub Actions OIDC Role                                     │ │
│  │ • Role Name: pic-kabu-dev-gh-actions-role                    │ │
│  │ • Provider: token.actions.githubusercontent.com              │ │
│  │ • Trusted Org: co-pic                                        │ │
│  │ • Permissions: ECR push/pull, describe repositories          │ │
│  │ • Purpose: CI/CD pipeline authentication without secrets     │ │
│  └──────────────────────────────────────────────────────────────┘ │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐ │
│  │ Node IAM Role                                                │ │
│  │ • Policies:                                                  │ │
│  │   - AmazonEKSWorkerNodePolicy                                │ │
│  │   - AmazonEKS_CNI_Policy                                     │ │
│  │   - AmazonEC2ContainerRegistryReadOnly                       │ │
│  │   - AmazonEBSCSIDriverPolicy                                 │ │
│  │   - AmazonSSMManagedInstanceCore (Dev)                       │ │
│  └──────────────────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────────────────┘
```

### Security Group Rules

**Development Environment:**
```
┌─────────────────────────────────────────────────────────────┐
│ pic-kabu-dev-cluster-sg (Control Plane)                     │
├─────────────────────────────────────────────────────────────┤
│ Inbound:                                                     │
│ • 443 from 0.0.0.0/0 (Public API access)                    │
│ • 443 from pic-kabu-dev-node-sg (Node to Control Plane)     │
│ Outbound:                                                    │
│ • All traffic to pic-kabu-dev-node-sg                       │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ pic-kabu-dev-node-sg (Worker Nodes)                         │
├─────────────────────────────────────────────────────────────┤
│ Inbound:                                                     │
│ • All traffic from pic-kabu-dev-node-sg (Node-to-node)      │
│ • 443 from pic-kabu-dev-cluster-sg (Control Plane)          │
│ • Ephemeral ports from pic-kabu-dev-cluster-sg              │
│ Outbound:                                                    │
│ • All traffic to 0.0.0.0/0 (Internet via IGW)               │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ pic-kabu-dev-rds-sg (PostgreSQL)                            │
├─────────────────────────────────────────────────────────────┤
│ Inbound:                                                     │
│ • 5432 from pic-kabu-dev-node-sg only                       │
│ Outbound:                                                    │
│ • All traffic to 0.0.0.0/0                                  │
└─────────────────────────────────────────────────────────────┘
```

**Production Environment:**
```
┌─────────────────────────────────────────────────────────────┐
│ pic-kabu-prod-cluster-sg (Control Plane)                    │
├─────────────────────────────────────────────────────────────┤
│ Inbound:                                                     │
│ • 443 from 14.243.87.5/32 (Whitelisted IP 1)                │
│ • 443 from 117.3.39.192/32 (Whitelisted IP 2)               │
│ • 443 from 14.252.145.82/32 (Whitelisted IP 3)              │
│ • 443 from pic-kabu-prod-node-sg (Node to Control Plane)    │
│ Outbound:                                                    │
│ • All traffic to pic-kabu-prod-node-sg                      │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ pic-kabu-prod-node-sg (Worker Nodes)                        │
├─────────────────────────────────────────────────────────────┤
│ Inbound:                                                     │
│ • All traffic from pic-kabu-prod-node-sg (Node-to-node)     │
│ • 443 from pic-kabu-prod-cluster-sg (Control Plane)         │
│ • Ephemeral ports from pic-kabu-prod-cluster-sg             │
│ Outbound:                                                    │
│ • All traffic to 0.0.0.0/0 (Internet via NAT Gateway)       │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ pic-kabu-prod-aurora-sg (Aurora PostgreSQL)                 │
├─────────────────────────────────────────────────────────────┤
│ Inbound:                                                     │
│ • 5432 from pic-kabu-prod-node-sg only                      │
│ Outbound:                                                    │
│ • All traffic to 0.0.0.0/0                                  │
└─────────────────────────────────────────────────────────────┘
```

---

## 📊 Resource Capacity Planning

### Development Environment Resources

| Resource | Type | Quantity | vCPU | Memory | Cost/Month (est.) |
|----------|------|----------|------|--------|-------------------|
| EKS Control Plane | Managed | 1 | N/A | N/A | $73 |
| On-Demand Nodes | t4g.large | 1-3 | 2 | 8 GB | $50-150 |
| Spot Nodes | t4g.large | 1-4 | 2 | 8 GB | $15-60 |
| RDS PostgreSQL | db.t3.micro | 1 | 2 | 1 GB | $15 |
| NAT Gateway | N/A | 0 | N/A | N/A | $0 |
| **Total** | | | | | **~$153-298** |

### Production Environment Resources

| Resource | Type | Quantity | vCPU | Memory | Cost/Month (est.) |
|----------|------|----------|------|--------|-------------------|
| EKS Control Plane | Managed | 1 | N/A | N/A | $73 |
| On-Demand Nodes | t4g.large | 2-5 | 2 | 8 GB | $100-250 |
| Aurora Writer | db.t3.medium | 1 | 2 | 4 GB | $110 |
| Aurora Reader | db.t3.medium | 1 | 2 | 4 GB | $110 |
| NAT Gateway | Single | 1 | N/A | N/A | $32 |
| **Total** | | | | | **~$425-575** |

*Note: Estimates are approximate and exclude data transfer, storage, and backup costs.*

---

## 🔄 CI/CD Pipeline Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                   GitHub Repository (co-pic org)                 │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │              GitHub Actions Workflow                        │ │
│  │                                                              │ │
│  │  1. Checkout code                                           │ │
│  │  2. Assume Role via OIDC                                    │ │
│  │     ↓                                                        │ │
│  │  ┌──────────────────────────────────────────────────────┐  │ │
│  │  │ AWS STS AssumeRoleWithWebIdentity                    │  │ │
│  │  │ Role: pic-kabu-dev-gh-actions-role                   │  │ │
│  │  │ No long-lived secrets required!                      │  │ │
│  │  └──────────────────────────────────────────────────────┘  │ │
│  │     ↓                                                        │ │
│  │  3. Login to ECR                                            │ │
│  │  4. Build Docker image                                      │ │
│  │  5. Tag image                                               │ │
│  │  6. Push to ECR repository                                  │ │
│  └────────────────────────────────────────────────────────────┘ │
└────────────────────────┬─────────────────────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────────────────────┐
│                  Amazon ECR (Container Registry)                 │
│                                                                   │
│  • pic-kabu-analysis-agent-fe-dev-service                        │
│  • pic-kabu-bff-dev-service                                      │
│  • pic-kabu-ta-dev-service                                       │
│  • pic-kabu-ai-graph-dev-service                                 │
│                                                                   │
│  Lifecycle Policy: Keep latest 3 images                          │
└────────────────────────┬─────────────────────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────────────────────┐
│                  EKS Cluster (pic-kabu-dev)                      │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                     ArgoCD (GitOps)                         │ │
│  │                                                              │ │
│  │  • Monitors Git repository for Kubernetes manifests        │ │
│  │  • Automatically syncs changes to cluster                   │ │
│  │  • Pulls container images from ECR                          │ │
│  │  • Manages application deployments, services, ingresses     │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                Application Pods                             │ │
│  │  Running containers from ECR images                         │ │
│  └────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────┘
```

---

## 🌟 Best Practices Implemented

### Infrastructure as Code
- ✅ Modular Terraform design for reusability
- ✅ Separate state files per environment
- ✅ Remote state in S3 with locking via DynamoDB
- ✅ Version pinning for providers and modules
- ✅ Consistent naming conventions

### Security
- ✅ IRSA for pod-level IAM permissions (no node-level credentials)
- ✅ OIDC for CI/CD authentication (no long-lived access keys)
- ✅ Security groups with least privilege access
- ✅ Database credentials in AWS Secrets Manager
- ✅ Encryption at rest for state files and databases
- ✅ Private subnet deployment for production workloads
- ✅ IP whitelisting for production API access

### High Availability (Production)
- ✅ Multi-AZ deployment for EKS nodes
- ✅ Aurora PostgreSQL with read replica
- ✅ Automatic failover for database
- ✅ Minimum 2 nodes for redundancy
- ✅ NAT Gateway for private subnet internet access

### Cost Optimization (Development)
- ✅ Spot instances for non-critical workloads
- ✅ No NAT Gateway (nodes in public subnets)
- ✅ Single RDS instance (no replicas)
- ✅ Smaller instance types (db.t3.micro)
- ✅ Reduced backup retention (3 days)
- ✅ ECR lifecycle policies to limit image storage

### Observability
- ✅ Metrics Server addon for resource monitoring
- ✅ CloudWatch integration (EKS control plane logs)
- ✅ SSM Session Manager for secure node access (dev)
- ✅ ArgoCD for GitOps visibility (dev)

---

## 📈 Scaling Considerations

### Horizontal Scaling (Nodes)
- EKS Cluster Autoscaler can be added to automatically scale node groups based on pod resource requests
- Current setup supports manual scaling via Terraform (update min/max/desired sizes)

### Vertical Scaling (Node Size)
- Current: t4g.large (2 vCPU, 8 GB RAM)
- Can upgrade to: t4g.xlarge (4 vCPU, 16 GB RAM) or larger for more resources

### Database Scaling
- **Dev**: Can upgrade RDS instance class or switch to Aurora for HA
- **Prod**: Can add more read replicas (currently 1), upgrade instance class, or enable Aurora Serverless v2

### Storage Scaling
- EBS CSI Driver enables dynamic PV provisioning
- Can use different storage classes (gp3, io1, io2) based on performance needs
- EBS volumes auto-expand if configured

---

## 🔧 Troubleshooting Guide

### Common Issues

**Issue**: Cannot access EKS cluster
```bash
# Solution: Update kubeconfig
aws eks update-kubeconfig --region ap-northeast-1 --name pic-kabu-dev-eks --profile stock

# Verify IAM permissions
aws eks describe-cluster --name pic-kabu-dev-eks --profile stock
```

**Issue**: Pods cannot pull images from ECR
```bash
# Solution: Verify node IAM role has ECR read permissions
kubectl describe pod <pod-name>

# Check if nodes can access ECR
aws ecr describe-repositories --profile stock
```

**Issue**: Database connection timeout (Dev)
```bash
# Solution: Verify security group rules
aws ec2 describe-security-groups --group-ids <rds-sg-id> --profile stock

# Test connectivity from a pod
kubectl run test-pod --image=postgres:17 -it --rm -- psql -h <db-endpoint> -U kabudev -d kabu_dev
```

**Issue**: Node group not scaling
```bash
# Check node group status
aws eks describe-nodegroup --cluster-name pic-kabu-dev-eks --nodegroup-name <ng-name> --profile stock

# Verify ASG limits
aws autoscaling describe-auto-scaling-groups --profile stock
```

---

## 📚 Additional Documentation

- **Terraform AWS EKS Module**: https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest
- **Terraform AWS VPC Module**: https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest
- **AWS EKS Best Practices**: https://aws.github.io/aws-eks-best-practices/
- **EKS Addons Documentation**: https://docs.aws.amazon.com/eks/latest/userguide/eks-add-ons.html
- **IRSA Documentation**: https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html
- **ArgoCD Documentation**: https://argo-cd.readthedocs.io/

---

**Last Updated**: November 14, 2025
**Maintained By**: cong.tv@human-brain.ai

