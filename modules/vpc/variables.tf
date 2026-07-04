variable "project_name"{
    type = string
    description = "Project name used in resource naming/tags"
}

variable "cluster_name"{
    type = string
    description = "EKS cluster name used for kubernetes.io subnet tags"
}

variable "vpc_cidr" {
    type = string
    description = "CIDR block for the VPC"
}

variable "public_subnet_cidrs" {
    type = list(string)
    description = "CIDR blocks for public subnets (minimun 2 for EKS)"
}

variable "private_subnet_cidrs" {
    type = list(string)
    description = "CIDR blocks for private subnets (minimus 2 for EKS)"
}

variable "availability_zones" {
    type = list(string)
    description = "AZs matching subnet CIDR list order"
}

variable "single_nat_gateway" {
   type = bool
   default = false
   description = "true = 1 NAT gateway (cost-saving), false = 1 per AZ (production HA)"
}