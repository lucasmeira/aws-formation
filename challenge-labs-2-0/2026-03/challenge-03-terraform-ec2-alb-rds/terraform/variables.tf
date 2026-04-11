variable "instance_name" {
    description = "The name of the EC2 instance"
    type        = string
    default     = "bia-dev-tf"
}

variable "db_password" {
    description = "The password for the RDS instance"
    type        = string
    sensitive   = true
}
