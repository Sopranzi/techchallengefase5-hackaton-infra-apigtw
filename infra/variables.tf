variable "aws_region" {
  description = "Região da AWS"
  default     = "us-east-1"
}

variable "lambda_auth_arn" {
  description = "ARN da função Lambda que fará a geração do Token (será usada na integração)"
  type        = string
  # Esse valor virá do output do Terraform do repositório da Lambda
}

variable "project_name" {
  default = "soat-tech-challenge"
}

variable "kong_nlb_dns" {
  type        = string
  description = "DNS do NLB criado pelo Service kong-proxy (ex.: k8s-kong-kongproxy-xxxx.elb.amazonaws.com)"
  default     = "a3b26e82eb34a458eaf7262cc1a31ff3-577bf52bfd470062.elb.us-east-1.amazonaws.com"
}

variable "vpc_id" {
  type    = string
  default = "vpc-0e72efaa7f76a42f6"
}

variable "subnets" {
  type        = list(string)
  description = "Subnets do VPC Link (mesmas do cluster/NLB)"
  default     = [
     "subnet-0131253332b374d8c",
     "subnet-0e962260342810875"
  ]
}
