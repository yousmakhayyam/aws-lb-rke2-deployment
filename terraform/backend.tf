terraform {
  backend "s3" {
    bucket         = "terraform-state-yousma-rke2"
    key            = "rke2-cluster/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-locks"
  }
}
