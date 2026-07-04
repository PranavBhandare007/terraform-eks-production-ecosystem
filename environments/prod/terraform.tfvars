aws_region = "us-west-2"
project_name = "eks-ecosystem"
cluster_name = "eks-ecosystem-cluster"
vpc_cidr = "10.0.0.0/16"
public_subnet_cidrs = [ "10.0.1.0/24", "10.0.2.0/24" ]
private_subnet_cidrs = [ "10.0.11.0/24", "10.0.12.0/24" ]
availability_zones = [ "us-west-2a", "us-west-2b" ]
single_nat_gateway = false