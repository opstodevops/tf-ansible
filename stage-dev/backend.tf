terraform {
  backend "s3" {
    # bucket         = "ops2dev-tfstatelock-12493"
    # dynamodb_table = "ops2dev-tfstatelock-12493"
    key            = "networking/innovation-dev-vpc/terraform.tfstate"
    region         = "us-east-1"
  }
}

# terraform init --backend-config="profile=default" --backend-config="dynamodb_table=DYNAMODB_TABLE" --backend-config="bucket=S3_BUCKET" --backend-config="region=us-east-1"