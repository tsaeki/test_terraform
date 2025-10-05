resource "aws_iam_role" "test_lambda_role" {
  name = "${local.name_prefix}-test-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "test_lambda_logs" {
  name = "${local.name_prefix}-test-lambda-logs-policy"
  role = aws_iam_role.test_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_lambda_function" "test_function" {
  filename      = "${path.module}/src/lambda/test-handler.zip"
  function_name = "${local.name_prefix}-test-function"
  role          = aws_iam_role.test_lambda_role.arn
  handler       = "test-handler.handler"
  runtime       = "nodejs20.x"
  timeout       = 30
  memory_size   = 128

  source_code_hash = filebase64sha256("${path.module}/src/lambda/test-handler.zip")

  environment {
    variables = {
      LOG_LEVEL = "INFO"
    }
  }

  tags = local.common_tags
}

resource "aws_lambda_permission" "api_gateway_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.test_function.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.test_api.execution_arn}/*/*"
}
