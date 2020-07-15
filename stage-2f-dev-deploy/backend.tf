terraform {
  backend "s3" {
    key            = "networking/dev-vpc/terraform.tfstate"
    region         = "us-east-1"
  }
}

# terraform init --backend-config="profile=default" --backend-config="dynamodb_table=DYNAMODB_TABLE" --backend-config="bucket=S3_BUCKET" --backend-config="region=us-east-1"

# terraform init --backend-config="dynamodb_table=ops2dev-tfstatelock-23050" --backend-config="bucket=ops2dev-tfstatebucket-23050" --backend-config="region=us-east-1"