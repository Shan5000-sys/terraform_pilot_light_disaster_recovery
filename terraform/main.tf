provider "aws" {
  alias  = "primary"
  region = var.primary_region
}

provider "aws" {
  alias  = "secondary"
  region = var.secondary_region
}

# ================================
# IAM Role for Lambda Execution
# ================================
resource "aws_iam_role" "lambda_exec" {
  name = "dr-failover-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_ec2_access" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

resource "aws_iam_role_policy_attachment" "lambda_sns_access" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSNSFullAccess"
}

resource "aws_iam_role_policy_attachment" "lambda_ga_access" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonVPCFullAccess"
}

# ================================
# Lambda Function
# ================================
resource "aws_lambda_function" "dr_failover" {
  function_name = "dr-failover-lambda"
  filename      = "${path.module}/../lambda_function_payload.zip"
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  role          = aws_iam_role.lambda_exec.arn

  environment {
    variables = {
      SECONDARY_INSTANCE_ID = var.secondary_instance_id
      ENDPOINT_GROUP_ARN    = var.endpoint_group_arn
      SNS_TOPIC_ARN         = var.sns_topic_arn
    }
  }

  source_code_hash = filebase64sha256("${path.module}/../lambda_function_payload.zip")
}

# ================================
# CloudWatch Alarm (Route 53 HealthCheck)
# ================================
resource "aws_cloudwatch_metric_alarm" "primary_down_alarm" {
  alarm_name          = "primary-instance-unhealthy"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HealthCheckStatus"
  namespace           = "AWS/Route53"
  period              = 60
  statistic           = "Minimum"
  threshold           = 1
  alarm_description   = "Triggers Lambda when primary instance becomes unhealthy"

  dimensions = {
    HealthCheckId = aws_route53_health_check.primary.id
  }

  alarm_actions = [aws_lambda_function.dr_failover.arn]
}

resource "aws_route53_health_check" "primary" {
  ip_address        = "35.183.150.199"  # Or use aws_eip.primary_eip.public_ip if you created it in Terraform
  port              = var.health_check_port
  type              = "HTTP"
  resource_path     = var.health_check_path
  failure_threshold = 3
  request_interval  = 30

  tags = {
    Name = "Primary Web Server Health Check"
  }
}

# ================================
# Allow CloudWatch to invoke Lambda
# ================================
resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.dr_failover.function_name
  principal     = "cloudwatch.amazonaws.com"
  source_arn    = aws_cloudwatch_metric_alarm.primary_down_alarm.arn
}

