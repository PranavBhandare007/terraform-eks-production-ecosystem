terraform {
    required_providers {
      aws = {
        source = "hashicorp/aws"
        version = "~> 5.0"
      }
    }

    backend "s3" {
      bucket = "pranav-eks-tfstate-2026"
      key = "prod/terraform.tfstate"
      region = "us-west-2"
      encrypt = true   #encrypts the state file at rest
      use_lockfile = true   #prevents two people running apply at same time
    }
}