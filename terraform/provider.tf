terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.4"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }

  # NOTE: local state for now (terraform.tfstate file right here in this
  # folder). Yousma - is baar is poore "terraform" folder ko turant
  # GitHub par push kar dena (private repo mein), taake dobara laptop
  # crash ho to state aur code dono safe rahein.
}

provider "aws" {
  region = var.aws_region
}
