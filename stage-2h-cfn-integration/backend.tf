terraform {
    backend "s3" {
        key = "lambda/terraform.tfstate"
    }
}

# terraform init -backend-config="bucket=_BUCKET_NAME" -backend-config="dynamodb_table=DYNAMODB_TABLE" -backend-config="region=REGION_NAME"