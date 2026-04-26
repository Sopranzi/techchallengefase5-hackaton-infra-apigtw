output "api_gateway_endpoint" {
  description = "URL base do API Gateway"
  value       = aws_apigatewayv2_api.main_gateway.api_endpoint
}

output "api_gateway_id" {
  description = "ID do API Gateway para uso em outros módulos"
  value       = aws_apigatewayv2_api.main_gateway.id
}
