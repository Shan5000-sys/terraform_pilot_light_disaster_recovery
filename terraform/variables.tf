variable "primary_region" {
  default = "ca-central-1"
}

variable "secondary_region" {
  default = "us-east-1"
}

variable "primary_vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "secondary_vpc_cidr" {
  default = "10.1.0.0/16"
}

variable "primary_subnet_cidr" {
  default = "10.0.1.0/24"
}

variable "secondary_subnet_cidr" {
  default = "10.1.1.0/24"
}

variable "primary_az" {
  default = "ca-central-1a"
}

variable "secondary_az" {
  default = "us-east-1a"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "primary_ami" {
  default = "ami-xxxxxxxxxxxxxxxxx" # Replace with correct AMI for ca-central-1
}

variable "secondary_ami" {
  default = "ami-xxxxxxxxxxxxxxxxx" # Replace with correct AMI for us-east-1
}

variable "admin_subnet_cidr" {
  description = "CIDR block for the admin subnet (if using for bastion or internal admin access)"
  default     = "10.0.2.0/24"
}

variable "lambda_function_name" {
  description = "Name of the Lambda function that handles failover"
  default     = "dr-failover-handler"
}

variable "public_subnet_cidr" {
  description = "Optional public subnet CIDR block (unused)"
  type        = string
  default     = "10.0.99.0/24"
}

variable "key_pair_name" {
  description = "Optional duplicate of key_name (not used)"
  type        = string
  default     = "pilot-light-key"
}

variable "primary_key_name" {
  description = "Key pair for in primary region"
  type        = string
}

variable "secondary_key_name" {
  description = "Key pair for in secondary region"
  type        = string
}
variable "health_check_path" {
  description = "Path to use for Route 53 health checks"
  default     = "/"
}

variable "primary_instance_name" {
  description = "Tag name for the primary EC2 instance"
  default     = "web-primary"
}

variable "secondary_instance_name" {
  description = "Tag name for the secondary EC2 instance"
  default     = "web-secondary"
}

variable "sns_topic_name" {
  description = "SNS topic name for alerting"
  default     = "dr-failover-alerts"
}

variable "global_accelerator_name" {
  description = "Name of the Global Accelerator instance"
  default     = "dr-global-accelerator"
}

variable "ami_id" {
  description = "AMI ID for EC2 instance"
  type        = string
}

variable "health_check_port" {
  description = "Port to use for Route 53 health checks"
  type        = number
  default     = 80
}

variable "secondary_instance_id" {
  description = "The EC2 instance ID of the secondary (standby) instance"
  type        = string
}

variable "endpoint_group_arn" {
  description = "The ARN of the Global Accelerator endpoint group"
  type        = string
}

variable "sns_topic_arn" {
  description = "The ARN of the SNS topic for notifications"
  type        = string
}

variable "secondary_elastic_ip" {
  description = "Elastic IP address used by the secondary instance for Global Accelerator"
  type        = string
}

variable "primary_instance_ip" {
  description = "Elastic IP address of the primary EC2 instance for Route 53 health check"
  type        = string
}

variable "primary_health_check_id" {
  description = "Optional manually-created Route 53 health check ID"
  type        = string
  default     = ""
}