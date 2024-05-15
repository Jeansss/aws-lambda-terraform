data "archive_file" "lambda_package" {
  type = "zip"
  source_file = "index.js"
  output_path = "index.zip"
}

data "archive_file" "lambda_layer_package" {
  type = "zip"
  source_dir = "layers/aws-sdk/nodejs"
  output_path = "lambda_layer_payload.zip"
}