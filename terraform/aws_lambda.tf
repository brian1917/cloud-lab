# Create Lambda Function Zip Archive (make sure to create the Python file first)
resource "null_resource" "lambda_archive" {
  for_each = local.aws_config.lambdaFunctions
  provisioner "local-exec" {
    command = "cd lambda-code && zip lambda_function.zip lambda_function.py && cd ../"
  }

  triggers = {
    file_checksum = fileexists(each.value["fileName"]) ? filesha256(each.value["fileName"]) : "missing"
    zip_missing   = !fileexists(each.value["fileName"])
  }
}


# IAM role for Lambda
resource "aws_iam_role" "lambda_exec_role" {
  for_each = local.aws_config.lambdaFunctions
  name = "lambda_exec_role"

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
}

# IAM policy attachment for Lambda to have basic execution permissions
resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  for_each = local.aws_config.lambdaFunctions
  role       = aws_iam_role.lambda_exec_role[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}


# Create Lambda function
resource "aws_lambda_function" "lambda_function" {
  for_each = local.aws_config.lambdaFunctions
  filename         = each.value["fileName"]
  function_name    = each.key
  role             = aws_iam_role.lambda_exec_role[each.key].arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.8"
  timeout          = 10

  vpc_config {
    security_group_ids = [aws_security_group.base[each.value["vpc"]].id]
    subnet_ids         = [aws_subnet.subnets[each.value["subnet"]].id]
  }

  environment {
    variables = {
      TARGET_IP   = "fin-dev-app01.lot48labs.com"
      TARGET_PORT = "8080"
    }
  }
}

# CloudWatch Event Rule to trigger Lambda every minute
resource "aws_cloudwatch_event_rule" "lambda_schedule_rule" {
  for_each = local.aws_config.lambdaFunctions
  name        = "lambda-every-minute-${each.key}"
  description = "Run Lambda every minute"
  schedule_expression = "rate(1 minute)"
}

# Permission to allow CloudWatch Events to invoke the Lambda function
resource "aws_lambda_permission" "allow_cloudwatch" {
  for_each =   local.aws_config.lambdaFunctions
  statement_id  = "AllowExecutionFromCloudWatch-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = each.key
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.lambda_schedule_rule[each.key].arn
}

# CloudWatch Event Target to invoke Lambda
resource "aws_cloudwatch_event_target" "lambda_target" {
  for_each = local.aws_config.lambdaFunctions
  rule      = aws_cloudwatch_event_rule.lambda_schedule_rule[each.key].name
  target_id = "lambda"
  arn       = aws_lambda_function.lambda_function[each.key].arn
}

# Grant necessary permissions to CloudWatch (if needed for logging)
resource "aws_lambda_permission" "lambda_cloudwatch" {
  for_each = local.aws_config.lambdaFunctions
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = each.key
  principal     = "logs.amazonaws.com"
}