variable "regionDefault" {
  default = "us-east-1"
}

variable "accessConfig" {
  default = "API_AND_CONFIG_MAP"
}

variable "aws_access_key_id" {
  type = string
  description = "AWS public key"
}


variable "aws_secret_access_key" {
  type = string
  description = "AWS secret key"
}
