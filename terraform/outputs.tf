# output "primary_web_instance_id" {
#   value = aws_instance.web_primary.id
# }

# output "bastion_instance_id" {
#   value = aws_instance.bastion.id
# }

# output "secondary_web_instance_id" {
#   value = aws_instance.web_secondary.id
# }

# output "primary_vpc_id" {
#   value = aws_vpc.primary.id
# }

# output "secondary_vpc_id" {
#   value = aws_vpc.secondary.id
# }

output "primary_health_check_id" {
  value = aws_route53_health_check.primary.id
}