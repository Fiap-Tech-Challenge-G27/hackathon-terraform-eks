data "aws_vpc" "selected" {
  id = "vpc-0c9f3f1383a787786"
}

data "aws_subnet" "subnet1" {
  id = "subnet-0b298a2372a3b3439"
}

data "aws_subnet" "subnet2" {
  id = "subnet-049335028e498c087"
}

data "terraform_remote_state" "rds" {
  backend = "s3"
  config = {
    bucket = "techchallengestate-g27"
    key    = "terraform-rds/terraform.tfstate"
    region = var.aws-region
  }
}

# data "terraform_remote_state" "documentdb" {
#   backend = "s3"
#   config = {
#     bucket = "techchallengestate-g27"
#     key    = "-hackathon-terraform-documentdb/terraform.tfstate"
#     region = var.aws-region
#   }
# }