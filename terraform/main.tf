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
      Effect    = "Allow",
      Principal = { Service = "lambda.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

# Attach AWS managed policies
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

# Inline policy for Global Accelerator access
resource "aws_iam_role_policy" "lambda_ga_update_policy" {
  name = "AllowGlobalAcceleratorUpdate"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = "globalaccelerator:UpdateEndpointGroup",
        Resource = var.endpoint_group_arn
      }
    ]
  })
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
  timeout       = 30 # <-- Add this line

  environment {
    variables = {
      SECONDARY_INSTANCE_ID = var.secondary_instance_id
      ENDPOINT_GROUP_ARN    = var.endpoint_group_arn
      SNS_TOPIC_ARN         = var.sns_topic_arn
      SECONDARY_ELASTIC_IP  = var.secondary_elastic_ip
    }
  }

  source_code_hash = filebase64sha256("${path.module}/../lambda_function_payload.zip")
}

# ================================
# Route 53 Health Check
# ================================
resource "aws_route53_health_check" "primary" {
  ip_address        = var.primary_instance_ip  # Prefer dynamic reference
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
# CloudWatch Alarm
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

# ================================
# Lambda Invoke Permission
# ================================
resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.dr_failover.function_name
  principal     = "cloudwatch.amazonaws.com"
  source_arn    = aws_cloudwatch_metric_alarm.primary_down_alarm.arn
}

