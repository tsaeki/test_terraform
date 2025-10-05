# API Gateway
resource "aws_api_gateway_rest_api" "test_api" {
  name        = "test-api"
  description = "Test API Gateway for Error Endpoints"
}

resource "aws_cloudwatch_log_group" "api_gateway_access_logs" {
  name              = "/aws/apigateway/${aws_api_gateway_rest_api.test_api.name}"
  retention_in_days = var.log_retention_in_days

  tags = local.common_tags
}

resource "aws_iam_role" "api_gateway_cloudwatch" {
  name = "${local.name_prefix}-api-gateway-cloudwatch-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "api_gateway_cloudwatch" {
  name = "${local.name_prefix}-api-gateway-cloudwatch-policy"
  role = aws_iam_role.api_gateway_cloudwatch.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:PutLogEvents",
          "logs:GetLogEvents",
          "logs:FilterLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

# API Gateway Account Settings
resource "aws_api_gateway_account" "main" {
  cloudwatch_role_arn = aws_iam_role.api_gateway_cloudwatch.arn
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

resource "aws_api_gateway_resource" "test" {
  rest_api_id = aws_api_gateway_rest_api.test_api.id
  parent_id   = aws_api_gateway_rest_api.test_api.root_resource_id
  path_part   = "test"
}

resource "aws_api_gateway_method" "test_get" {
  rest_api_id   = aws_api_gateway_rest_api.test_api.id
  resource_id   = aws_api_gateway_resource.test.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "test_get" {
  rest_api_id             = aws_api_gateway_rest_api.test_api.id
  resource_id             = aws_api_gateway_resource.test.id
  http_method             = aws_api_gateway_method.test_get.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.test_function.invoke_arn
}

# Deployment
resource "aws_api_gateway_deployment" "test" {
  rest_api_id = aws_api_gateway_rest_api.test_api.id
  
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.error_01.id,
      aws_api_gateway_resource.error_02.id,
      aws_api_gateway_resource.error_03.id,
      aws_api_gateway_resource.test.id,
      aws_api_gateway_method.error_01_get.id,
      aws_api_gateway_method.error_02_get.id,
      aws_api_gateway_method.error_03_get.id,
      aws_api_gateway_method.test_get.id,
      aws_api_gateway_integration.error_01_get.id,
      aws_api_gateway_integration.error_02_get.id,
      aws_api_gateway_integration.error_03_get.id,
      aws_api_gateway_integration.test_get.id,
    ]))
  }
  
  depends_on = [
    aws_api_gateway_integration.error_01_get,
    aws_api_gateway_integration.error_02_get,
    aws_api_gateway_integration.error_03_get,
    aws_api_gateway_integration.test_get,
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

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_access_logs.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      caller         = "$context.identity.caller"
      user           = "$context.identity.user"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      resourcePath   = "$context.resourcePath"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }

  depends_on = [aws_api_gateway_account.main]
}

resource "aws_api_gateway_method_settings" "all" {
  rest_api_id = aws_api_gateway_rest_api.test_api.id
  stage_name  = aws_api_gateway_stage.test.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled    = false
    logging_level      = "INFO"
    data_trace_enabled = false
  }

  depends_on = [aws_api_gateway_account.main]
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

output "test_url" {
  value = "${aws_api_gateway_stage.test.invoke_url}/test"
}
