terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.8.0"
    }
  }

}
provider "aws" {
  region     = "ap-south-1"
  access_key = "AKIAXSQVA5M2KW4CQQEQ"
  secret_key = "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"
}