# API Gateway
resource "aws_api_gateway_rest_api" "test_api" {
  name        = "test-api"
  description = "Test API Gateway for Error Endpoints"
}

# /error_01 endpoint
resource "aws_api_gateway_resource" "error_01" {
  rest_api_id = aws_api_gateway_rest_api.test_api.id
  parent_id   = aws_api_gateway_rest_api.test_api.root_resource_id
  path_part   = "error_01"
}

resource "aws_api_gateway_method" "error_01_get" {
  rest_api_id   = aws_api_gateway_rest_api.test_api.id
  resource_id   = aws_api_gateway_resource.error_01.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "error_01_500" {
  rest_api_id = aws_api_gateway_rest_api.test_api.id
  resource_id = aws_api_gateway_resource.error_01.id
  http_method = aws_api_gateway_method.error_01_get.http_method
  status_code = "500"
}

resource "aws_api_gateway_integration" "error_01_get" {
  rest_api_id = aws_api_gateway_rest_api.test_api.id
  resource_id = aws_api_gateway_resource.error_01.id
  http_method = aws_api_gateway_method.error_01_get.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 500}"
  }
}

resource "aws_api_gateway_integration_response" "error_01_500" {
  rest_api_id = aws_api_gateway_rest_api.test_api.id
  resource_id = aws_api_gateway_resource.error_01.id
  http_method = aws_api_gateway_method.error_01_get.http_method
  status_code = aws_api_gateway_method_response.error_01_500.status_code

  response_templates = {
    "application/json" = jsonencode({
      message = "Error 01: Internal Server Error"
    })
  }
}

# /error_02 endpoint
resource "aws_api_gateway_resource" "error_02" {
  rest_api_id = aws_api_gateway_rest_api.test_api.id
  parent_id   = aws_api_gateway_rest_api.test_api.root_resource_id
  path_part   = "error_02"
}

resource "aws_api_gateway_method" "error_02_get" {
  rest_api_id   = aws_api_gateway_rest_api.test_api.id
  resource_id   = aws_api_gateway_resource.error_02.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "error_02_500" {
  rest_api_id = aws_api_gateway_rest_api.test_api.id
  resource_id = aws_api_gateway_resource.error_02.id
  http_method = aws_api_gateway_method.error_02_get.http_method
  status_code = "500"
}

resource "aws_api_gateway_integration" "error_02_get" {
  rest_api_id = aws_api_gateway_rest_api.test_api.id
  resource_id = aws_api_gateway_resource.error_02.id
  http_method = aws_api_gateway_method.error_02_get.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 500}"
  }
}

resource "aws_api_gateway_integration_response" "error_02_500" {
  rest_api_id = aws_api_gateway_rest_api.test_api.id
  resource_id = aws_api_gateway_resource.error_02.id
  http_method = aws_api_gateway_method.error_02_get.http_method
  status_code = aws_api_gateway_method_response.error_02_500.status_code

  response_templates = {
    "application/json" = jsonencode({
      message = "Error 02: Internal Server Error"
    })
  }
}

# /error_03 endpoint
resource "aws_api_gateway_resource" "error_03" {
  rest_api_id = aws_api_gateway_rest_api.test_api.id
  parent_id   = aws_api_gateway_rest_api.test_api.root_resource_id
  path_part   = "error_03"
}

resource "aws_api_gateway_method" "error_03_get" {
  rest_api_id   = aws_api_gateway_rest_api.test_api.id
  resource_id   = aws_api_gateway_resource.error_03.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "error_03_500" {
  rest_api_id = aws_api_gateway_rest_api.test_api.id
  resource_id = aws_api_gateway_resource.error_03.id
  http_method = aws_api_gateway_method.error_03_get.http_method
  status_code = "500"
}

resource "aws_api_gateway_integration" "error_03_get" {
  rest_api_id = aws_api_gateway_rest_api.test_api.id
  resource_id = aws_api_gateway_resource.error_03.id
  http_method = aws_api_gateway_method.error_03_get.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 500}"
  }
}

resource "aws_api_gateway_integration_response" "error_03_500" {
  rest_api_id = aws_api_gateway_rest_api.test_api.id
  resource_id = aws_api_gateway_resource.error_03.id
  http_method = aws_api_gateway_method.error_03_get.http_method
  status_code = aws_api_gateway_method_response.error_03_500.status_code

  response_templates = {
    "application/json" = jsonencode({
      message = "Error 03: Internal Server Error"
    })
  }
}

# Deployment
resource "aws_api_gateway_deployment" "test" {
  rest_api_id = aws_api_gateway_rest_api.test_api.id
  
  depends_on = [
    aws_api_gateway_integration.error_01_get,
    aws_api_gateway_integration.error_02_get,
    aws_api_gateway_integration.error_03_get,
    aws_api_gateway_integration_response.error_01_500,
    aws_api_gateway_integration_response.error_02_500,
    aws_api_gateway_integration_response.error_03_500
  ]

  lifecycle {
    create_before_destroy = true
  }
}

# Stage
resource "aws_api_gateway_stage" "test" {
  deployment_id = aws_api_gateway_deployment.test.id
  rest_api_id   = aws_api_gateway_rest_api.test_api.id
  stage_name    = "test"
}

# Outputs
output "api_url" {
  value = "${aws_api_gateway_stage.test.invoke_url}"
}

output "error_01_url" {
  value = "${aws_api_gateway_stage.test.invoke_url}/error_01"
}

output "error_02_url" {
  value = "${aws_api_gateway_stage.test.invoke_url}/error_02"
}

output "error_03_url" {
  value = "${aws_api_gateway_stage.test.invoke_url}/error_03"
}