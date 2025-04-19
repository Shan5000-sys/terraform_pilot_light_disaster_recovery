# Primary and Secondary AWS regions
primary_region   = "ca-central-1"
secondary_region = "us-east-1"

# VPC and subnet CIDRs
primary_vpc_cidr   = "10.0.0.0/16"
secondary_vpc_cidr = "10.1.0.0/16"
public_subnet_cidr = "10.0.1.0/24"
admin_subnet_cidr  = "10.0.2.0/24"

# EC2 configuration
ami_id              = "ami-02cd5b9bfb2512340"
instance_type       = "t2.micro"
primary_key_name    = "pilot-light-key"
secondary_key_name  = "pilot-light-key-2"
key_pair_name       = "pilot-light-key"  # Optional if not used directly
primary_ami         = "ami-02cd5b9bfb2512340"
secondary_ami       = "ami-00a929b66ed6e0de6"
primary_instance_name   = "web-primary"
secondary_instance_name = "web-secondary"

# Global Accelerator
global_accelerator_name = "dr-global-accelerator"
endpoint_group_arn       = "arn:aws:globalaccelerator:us-east-1:123456789012:endpoint-group/abcd1234efgh5678"

# Route 53
health_check_port     = 80
health_check_path     = "/"
primary_health_check_id = "69a95a11-566c-4c07-bbaa-65394da48ee1"

# SNS notifications
sns_topic_name = "dr-failover-alerts"
sns_topic_arn  = "arn:aws:sns:ca-central-1:050752626387:dr-failover-alerts"

# Lambda configuration
lambda_function_name   = "dr-failover-handler"
secondary_instance_id  = "i-0123456789abcdef0"