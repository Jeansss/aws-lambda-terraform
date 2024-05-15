resource "aws_lambda_function" "html_lambda" {
  filename = "index.zip"
  function_name = "myLambdaFunction"
  role = aws_iam_role.lambda_role.arn
  handler = "index.handler"
  runtime = "nodejs20.x"
  source_code_hash = data.archive_file.lambda_package.output_base64sha256
  layers = [aws_lambda_layer_version.lambda_layer.arn]
}

resource "aws_iam_role" "lambda_role" {
  name = "lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
    {
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }
  ]
})
}

resource "aws_iam_role" "cognito_role" {
  name = "cognito-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
    {
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "cognito-idp.amazonaws.com"
      }
    }
  ]
})
}

resource "aws_iam_policy_attachment" "cognito-admin" {
  name = "cognito-admin"
  policy_arn = "arn:aws:iam::aws:policy/AmazonCognitoPowerUser"
  roles = [aws_iam_role.lambda_role.name]
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role = aws_iam_role.lambda_role.name
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id = "AllowExecutionFromAPIGateway"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.html_lambda.function_name
  principal = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.my_api.execution_arn}/*/*/*"
}

resource "aws_lambda_layer_version" "lambda_layer" {
  filename   = "lambda_layer_payload.zip"
  layer_name = "lambda_layer"
  compatible_runtimes = ["nodejs20.x"]
  source_code_hash = data.archive_file.lambda_layer_package.output_base64sha256
}