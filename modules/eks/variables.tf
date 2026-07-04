variable "cluster_name" {
  type = string
}

variable "cluster_role_arn" {
  type        = string
  description = "IAM module se aayega"
}

variable "node_role_arn" {
  type        = string
  description = "IAM module se aayega"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "VPC module se aayega"
}