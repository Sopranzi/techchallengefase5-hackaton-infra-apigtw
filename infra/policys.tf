# infra/policys.tf

# 1. Busca a LabRole existente (para não tentar criar uma nova)
data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

# 2. Permissão para o Gateway invocar a Lambda (CRÍTICO)
resource "aws_lambda_permission" "allow_apigateway_invoke" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_auth_arn 
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main_gateway.execution_arn}/*/*"
}

# Permissão para o Gateway invocar a Lambda de Authorizer
resource "aws_lambda_permission" "allow_apigateway_invoke_authorizer" {
  statement_id  = "AllowExecutionFromAPIGatewayAuthorizer"
  action        = "lambda:InvokeFunction"
  function_name = data.aws_lambda_function.authorizer.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main_gateway.execution_arn}/*/*"
}

# 3. Configuração Global para Logs do API Gateway
# Usamos a LabRole em vez de criar uma role nova
resource "aws_api_gateway_account" "main" {
  cloudwatch_role_arn = data.aws_iam_role.lab_role.arn
}
