terraform {
    backend "s3" {
        bucket = "lucas-meira-terraform-state"
        key    = "terraform.tfstate"
        region = "us-east-1"
        profile = "lucas-meira"
    }
}