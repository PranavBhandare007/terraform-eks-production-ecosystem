module "vpc" {
  source = "../../modules/vpc"

  project_name = var.project_name
  cluster_name = var.cluster_name
  vpc_cidr = var.vpc_cidr
  public_subnet_cidrs = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones = var.availability_zones
  single_nat_gateway = var.single_nat_gateway
}

module "iam" {
  source = "../../modules/iam"

  cluster_name = var.cluster_name
}

module "eks" {
  source = "../../modules/eks"

  cluster_name = var.cluster_name
  cluster_role_arn = module.iam.cluster_role_arn
  node_role_arn = module.iam.node_role_arn
  private_subnet_ids = module.vpc.private_subnet_ids
}