# Criação do API Gateway
resource "aws_api_gateway_rest_api" "my_api" {
  name        = "my-api"
  description = "API Gateway for fiap project"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# Criação de recursos no API Gateway
resource "aws_api_gateway_resource" "root" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  parent_id   = aws_api_gateway_rest_api.my_api.root_resource_id
  path_part   = "authorization"
}

resource "aws_api_gateway_resource" "order_manager" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  parent_id   = aws_api_gateway_rest_api.my_api.root_resource_id
  path_part   = "{proxy+}"
}

# Criação de métodos para os recursos
resource "aws_api_gateway_method" "proxy" {
  rest_api_id  = aws_api_gateway_rest_api.my_api.id
  resource_id  = aws_api_gateway_resource.root.id
  http_method  = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "order_manager" {
  rest_api_id  = aws_api_gateway_rest_api.my_api.id
  resource_id  = aws_api_gateway_resource.order_manager.id
  http_method  = "ANY"
  # authorization = "NONE"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.demo.id
  request_parameters = {
    "method.request.path.proxy" = true
  }
}

# Integração com o Load Balancer do EKS
resource "aws_api_gateway_integration" "eks_integration" {
  rest_api_id             = aws_api_gateway_rest_api.my_api.id
  resource_id             = aws_api_gateway_resource.order_manager.id
  http_method             = aws_api_gateway_method.order_manager.http_method
  integration_http_method = "ANY"
  type                    = "HTTP_PROXY"
  uri                     = "http://ad0ee343d6f6241fbaa68365bf02077c-838325891.us-east-1.elb.amazonaws.com/{proxy}"
    request_parameters = {
    "integration.request.path.proxy" = "method.request.path.proxy"
  }
}

# Integração com o Lambda
resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.my_api.id
  resource_id             = aws_api_gateway_resource.root.id
  http_method             = aws_api_gateway_method.proxy.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = aws_lambda_function.html_lambda.invoke_arn
}

# Configuração de respostas dos métodos
resource "aws_api_gateway_method_response" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.root.id
  http_method = aws_api_gateway_method.proxy.http_method
  status_code = "200"

  //cors section
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin" = true
  }

  depends_on = [
    aws_api_gateway_integration.lambda_integration
  ]

}

resource "aws_api_gateway_method_response" "order_manager" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.order_manager.id
  http_method = aws_api_gateway_method.order_manager.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

  depends_on = [
    aws_api_gateway_integration.eks_integration
  ]
}

# Configuração de respostas da integração
resource "aws_api_gateway_integration_response" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.root.id
  http_method = aws_api_gateway_method.proxy.http_method
  status_code = aws_api_gateway_method_response.proxy.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [
    aws_api_gateway_method_response.proxy
  ]
}

resource "aws_api_gateway_integration_response" "order_manager" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.order_manager.id
  http_method = aws_api_gateway_method.order_manager.http_method
  status_code = aws_api_gateway_method_response.order_manager.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [
    aws_api_gateway_method_response.order_manager
  ]
}

# Implantação do API Gateway
resource "aws_api_gateway_deployment" "deployment" {
  depends_on = [
    aws_api_gateway_method.proxy,
    aws_api_gateway_method.order_manager,
    aws_api_gateway_integration.lambda_integration,
    aws_api_gateway_integration.eks_integration,
    aws_api_gateway_method_response.proxy,
    aws_api_gateway_method_response.order_manager,
    aws_api_gateway_integration_response.proxy,
    aws_api_gateway_integration_response.order_manager
  ]

  rest_api_id = aws_api_gateway_rest_api.my_api.id
  stage_name  = "dev"
}

# Autorizer para API Gateway
resource "aws_api_gateway_authorizer" "demo" {
  name         = "my_apig_authorizer2"
  rest_api_id  = aws_api_gateway_rest_api.my_api.id
  type         = "COGNITO_USER_POOLS"
  provider_arns = [aws_cognito_user_pool.pool.arn]
}