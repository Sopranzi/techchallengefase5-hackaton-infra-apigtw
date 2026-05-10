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
  default     = "a1c6ff06614d644eca19a9bb6d4cebbc-48fc6bd584af2188.elb.us-east-1.amazonaws.com"
}

variable "vpc_id" {
  type    = string
  default = "vpc-0195a03ae31790e54"
}

variable "subnets" {
  type        = list(string)
  description = "Subnets do VPC Link (mesmas do cluster/NLB)"
  default     = [
     "subnet-0fd52db26c85db5a2",
     "subnet-013405edfa54bd9f4"
  ]
}
