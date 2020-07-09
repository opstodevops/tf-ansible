terraform {
    backend "s3" {
        bucket = "ops2dev-tfstatebucket-79483"
        dynamodb_table = "ops2dev-tfstatelock-79483"
        key = "networking/dev-vpc/terraform.tfstate"
        region = "us-east-1"
    }
}

# terraform init -backend-config="bucket=BUCKET_NAME" -backend-config="region=REGION_NAME" -backend-config="dynamodb_table=DYNAMODB_TABLE"