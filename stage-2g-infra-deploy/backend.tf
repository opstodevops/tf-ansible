terraform {
    backend "s3" {
        key = "networking/infra-dev-vpc/terraform.tfstate"
        region = "us-east-1"
    }
}

# terraform init --backend-config="profile=default" --backend-config="dynamodb_table=DYNAMODB_TABLE" --backend-config="bucket=S3_BUCKET" --backend-config="region=us-east-1"

