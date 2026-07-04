# Terraform EKS Production Ecosystem

![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-FF9900?style=for-the-badge&logo=amazonaws&logoColor=white)
![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)
![EKS](https://img.shields.io/badge/Amazon%20EKS-FF9900?style=for-the-badge&logo=amazoneks&logoColor=white)
![IAM](https://img.shields.io/badge/AWS%20IAM-DD344C?style=for-the-badge&logo=amazoniam&logoColor=white)

A modular, production-style AWS infrastructure setup built with Terraform — provisioning a complete networking layer, IAM roles, and an EKS (Elastic Kubernetes Service) cluster with a managed node group.

This project was built to practice real-world DevOps/Cloud Engineering patterns: remote state management, modular Terraform design, and running production-grade Kubernetes infrastructure on AWS.

---

## Architecture Overview

```
                          ┌─────────────────────────────┐
                          │           AWS VPC            │
                          │        (10.0.0.0/16)         │
                          │                               │
        ┌─────────────────┼───────────────┐               │
        │                 │               │               │
  ┌─────▼─────┐     ┌─────▼─────┐   ┌─────▼─────┐   ┌─────▼─────┐
  │  Public   │     │  Public   │   │  Private  │   │  Private  │
  │ Subnet-1  │     │ Subnet-2  │   │ Subnet-1  │   │ Subnet-2  │
  │  (AZ-a)   │     │  (AZ-b)   │   │  (AZ-a)   │   │  (AZ-b)   │
  └─────┬─────┘     └───────────┘   └─────┬─────┘   └─────┬─────┘
        │                                  │               │
   ┌────▼────┐                       ┌─────▼───────────────▼─────┐
   │   NAT    │                      │      EKS Node Group        │
   │ Gateway  │◄─────────────────────┤   (t3.small, 2 nodes)      │
   └────┬────┘                       └────────────────────────────┘
        │
   ┌────▼────┐
   │Internet │
   │ Gateway │
   └─────────┘

   EKS Cluster (control plane) — managed by AWS, spans both AZs
   IAM Roles — separate roles for cluster control plane and worker nodes
```

---

## Project Structure

```
terraform-eks-production-ecosystem/
├── bootstrap/                     # One-time setup — creates the remote state S3 bucket
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
│
├── environments/
│   └── prod/
│       ├── backend.tf             # Remote state config (S3 + native state locking)
│       ├── provider.tf
│       ├── main.tf                # Calls all modules
│       ├── variables.tf
│       └── terraform.tfvars       # gitignored — personal values
│
├── modules/
│   ├── vpc/                       # VPC, public/private subnets, NAT gateway, route tables
│   ├── iam/                       # IAM roles for EKS cluster & worker nodes
│   └── eks/                       # EKS cluster + managed node group
│
├── .gitignore
└── README.md
```

---

## What This Builds

| Component | Details |
|---|---|
| **VPC** | Custom VPC with 2 public + 2 private subnets across 2 Availability Zones |
| **NAT Gateway** | Single NAT gateway (cost-optimized) for private subnet outbound internet access |
| **IAM** | Dedicated IAM roles for the EKS cluster (control plane) and worker nodes, using AWS managed policies via `aws_iam_policy` data sources |
| **EKS Cluster** | Managed Kubernetes control plane (AWS-managed) |
| **Node Group** | Managed EC2 node group (t3.small, autoscaling 1–3 nodes) running in private subnets |
| **Remote State** | S3 backend with native Terraform state locking (`use_lockfile`) — no DynamoDB required |

---

## Key Design Decisions

- **Modular structure** — VPC, IAM, and EKS are separate reusable modules, called from a single `environments/prod` root. Makes it easy to add a second environment (e.g., `staging`) later without duplicating logic.
- **Bootstrap separation** — The S3 state bucket is created in a standalone `bootstrap/` configuration using local state, solving the chicken-and-egg problem of needing a backend before the backend exists.
- **Native S3 state locking** — Used Terraform's built-in `use_lockfile` (Terraform 1.10+) instead of a DynamoDB lock table, reducing the number of managed resources.
- **AWS managed policies via data sources** — IAM policies are looked up using `aws_iam_policy` data sources instead of hardcoded ARNs, avoiding typos and keeping the code portable across AWS partitions.
- **Single NAT Gateway** — Chosen over per-AZ NAT gateways to optimize cost for a learning/portfolio project. In a real production environment, this would be a per-AZ NAT setup for high availability (documented as a trade-off below).
- **Worker nodes in private subnets** — Nodes are not directly internet-facing; outbound traffic routes through the NAT gateway, following the principle of least exposure.

---

## How to Deploy

```bash
# 1. One-time bootstrap — creates the S3 backend
cd bootstrap
terraform init
terraform apply

# 2. Deploy the actual infrastructure
cd ../environments/prod
terraform init
terraform plan
terraform apply

# 3. Connect kubectl to the new cluster
aws eks update-kubeconfig --name eks-ecosystem-cluster --region <your-region>
kubectl get nodes
```

---

## Verified Working

- `kubectl get nodes` shows both worker nodes in `Ready` state
- Deployed a sample `nginx` application and exposed it via a Kubernetes `LoadBalancer` service
- Confirmed end-to-end traffic flow: **Internet → AWS Load Balancer → EKS Node → Pod**
- Observed that Kubernetes automatically provisions its own security group for `LoadBalancer`-type services (via the AWS Cloud Controller Manager) — this was not manually configured in Terraform

---

## Trade-offs & What I'd Change for True Production

| Decision made | Production alternative |
|---|---|
| Single NAT Gateway | One NAT Gateway per AZ, for full high availability |
| Public EKS API endpoint open to `0.0.0.0/0` | Restrict `public_access_cidrs` to office/VPN IPs only |
| Manual `kubectl expose --type=LoadBalancer` for testing | ALB Ingress Controller for host/path-based routing and centralized ALB management |
| No OIDC provider configured | OIDC provider + IRSA required for IAM-integrated addons like ALB Ingress Controller |

---

## How to Destroy

Tear down in the **reverse order** of creation — infrastructure first, then the state backend.

```bash
# 1. Destroy the main infrastructure (VPC, IAM, EKS)
cd environments/prod
terraform destroy

# 2. (Optional) Destroy the bootstrap S3 backend — only if you're done with the project entirely
cd ../../bootstrap
terraform destroy
```

⚠️ **Notes before destroying:**
- If you deployed any `LoadBalancer`-type Kubernetes services (like the nginx demo), delete them with `kubectl delete service <name>` **before** running `terraform destroy`. Terraform doesn't know about the security group and ELB that Kubernetes created on its own, so it won't clean those up — leaving orphaned AWS resources that keep costing money.
- Destroying the bootstrap (S3 bucket) will delete your Terraform state history. Only do this once you no longer need the project.
- EKS cluster + node group deletion can take 10-15 minutes, similar to creation time.

---

## Issues Faced & Fixes

**Confusion — app worked on port 80 despite no security group rule allowing it**
- **Root cause:** Kubernetes' AWS Cloud Controller Manager automatically creates its own security group (and attaches it to the new ELB) whenever a `LoadBalancer`-type service is created — this happens outside of Terraform and isn't tracked in Terraform state.
- **Fix:** No fix needed — this is expected behavior, but it's important to know so these auto-created resources aren't mistaken for manually configured ones during a security review.
- **Prevention:** For production use cases, prefer the ALB Ingress Controller, which uses a Terraform-managed IAM policy for more controlled, auditable resource creation instead of implicit auto-provisioning.

---

## Tech Stack

- **IaC:** Terraform (~> 5.0 AWS provider)
- **Cloud:** AWS (VPC, EKS, IAM, EC2, S3)
- **Orchestration:** Kubernetes (via EKS)
- **State Management:** S3 remote backend with native locking