# API Gateway (HTTP API) + CORS
resource "aws_apigatewayv2_api" "main_gateway" {
  name          = "soat-tech-challenge-gateway"
  protocol_type = "HTTP"
  description   = "API Gateway para o Tech Challenge Fase 5"

  cors_configuration {
    allow_methods = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    allow_headers = ["Content-Type", "Authorization", "X-Amz-Date", "X-Api-Key"]
    allow_origins = ["*"]
    max_age       = 300
  }
}

# Logs
resource "aws_cloudwatch_log_group" "api_gateway_logs" {
  name              = "/aws/apigateway/${var.project_name}"
  retention_in_days = 7
}

# Busca dinamicamente os dados da Lambda do Authorizer
data "aws_lambda_function" "authorizer" {
  function_name = "soat-authorizer-function"
}

# Stage
resource "aws_apigatewayv2_stage" "default_stage" {
  api_id      = aws_apigatewayv2_api.main_gateway.id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_logs.arn
    format = <<EOF
{ "requestId":"$context.requestId", "routeKey":"$context.routeKey", "httpMethod":"$context.httpMethod", "status":"$context.status", "integrationStatus":"$context.integrationStatus", "integrationErrorMessage":"$context.integrationErrorMessage", "authorizerError":"$context.authorizer.error", "authorizerStatus":"$context.authorizer.status", "requestTime":"$context.requestTime", "sourceIp":"$context.identity.sourceIp", "protocol":"$context.protocol", "responseLength":"$context.responseLength", "domainName":"$context.domainName", "path":"$context.path", "stage":"$context.stage" }
EOF
  }
}

# Auth Lambda integration (pública /auth)
resource "aws_apigatewayv2_integration" "login_integration" {
  api_id                 = aws_apigatewayv2_api.main_gateway.id
  integration_type       = "AWS_PROXY"
  connection_type        = "INTERNET"
  description            = "Integração com Lambda de Autenticação"
  integration_method     = "POST"
  integration_uri        = var.lambda_auth_arn
  payload_format_version = "2.0"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_apigatewayv2_route" "auth_route" {
  api_id    = aws_apigatewayv2_api.main_gateway.id
  route_key = "POST /auth"
  target    = "integrations/${aws_apigatewayv2_integration.login_integration.id}"
}

# Authorizer Lambda
resource "aws_apigatewayv2_authorizer" "lambda_auth" {
  api_id                            = aws_apigatewayv2_api.main_gateway.id
  authorizer_type                   = "REQUEST"
  identity_sources                  = ["$request.header.Authorization"]
  name                              = "lambda-authorizer"
  # URI de invocação da Lambda para authorizer (função separada do /auth)
  authorizer_uri = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${data.aws_lambda_function.authorizer.arn}/invocations"
  authorizer_payload_format_version = "2.0"
  enable_simple_responses           = true
}

# VPC Link -> Kong NLB
resource "aws_security_group" "apigw_vpc_link" {
  name        = "${var.project_name}-apigw-vpclink"
  description = "API GW Kong NLB"
  vpc_id      = var.vpc_id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_apigatewayv2_vpc_link" "kong" {
  name               = "${var.project_name}-kong-link"
  security_group_ids = [aws_security_group.apigw_vpc_link.id]
  subnet_ids         = var.subnets
}

# Dados do NLB criado pelo Kong (nome vem do DNS até o primeiro ponto)
data "aws_lb" "kong_nlb" {
  # Nome do NLB é o prefixo do DNS antes do primeiro "-"
  name = split("-", var.kong_nlb_dns)[0]
}

data "aws_lb_listener" "kong_http" {
  load_balancer_arn = data.aws_lb.kong_nlb.arn
  port              = 80
}

# Integração backend via VPC Link (Kong/NLB)
resource "aws_apigatewayv2_integration" "eks_backend" {
  api_id                 = aws_apigatewayv2_api.main_gateway.id
  integration_type       = "HTTP_PROXY"
  integration_method     = "ANY"
  # Aponta para o NLB do Kong via Internet (NLB é público)
  integration_uri        = "http://${var.kong_nlb_dns}/{proxy}"
  payload_format_version = "1.0"
  connection_type        = "INTERNET"

  lifecycle {
    create_before_destroy = true
  }
}

# Rota protegida para backend
resource "aws_apigatewayv2_route" "proxy_all" {
  count              = 1
  api_id             = aws_apigatewayv2_api.main_gateway.id
  route_key          = "ANY /{proxy+}"
  target             = "integrations/${aws_apigatewayv2_integration.eks_backend.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.lambda_auth.id
}
