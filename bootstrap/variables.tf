variable "aws_region" {
    type = string
    default = "us-west-2"
}

variable "project-name" {
    type = string
    default = "eks-ecosystem"
}

variable "state_bucket_name" {
    type = string
    description = "Globally unique s3 bucket name"
}
