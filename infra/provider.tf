terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  # Recomendo configurar um bucket S3 para guardar o estado (backend)
  backend "s3" {
    bucket = "terraform-state-soat-fase05-hackton-g15" # Altere para o nome do seu bucket
    key    = "apigateway/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = "us-east-1" 
}