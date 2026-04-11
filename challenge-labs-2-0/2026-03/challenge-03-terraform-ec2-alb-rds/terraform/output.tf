output "instance_id" {
    description = "The ID of the EC2 instance"
    value = aws_instance.bia_dev.id
}

output "instance_type" {
    description = "The type of the EC2 instance"
    value = aws_instance.bia_dev.instance_type
}

output "instance_security_groups" {
    description = "The security groups associated with the EC2 instance"
    value = aws_instance.bia_dev.security_groups
}

output "instance_public_ip" {
    description = "The public IP address of the EC2 instance"
    value = aws_instance.bia_dev.public_ip
}

output "instance_public_dns" {
    description = "The public DNS name of the EC2 instance"
    value = aws_instance.bia_dev.public_dns
}

output "instance_private_ip" {
    description = "The private IP address of the EC2 instance"
    value = aws_instance.bia_dev.private_ip
}

output "rds_endpoint" {
    description = "The endpoint of the RDS instance"
    value = aws_db_instance.bia.endpoint
}