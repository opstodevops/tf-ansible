terraform {
    backend "s3" {
        bucket = "ops2dev-tfstatebucket-13740"
        dynamodb_table = "ops2dev-tfstatelock-13740"
        key = "networking/dev-vpc/terraform.tfstate"
        region = "us-east-1"
    }
}

# terraform init --backend-config="profile=nonprod" --backend-config="dynamodb_table=ops2dev-tfstatelock-96173" --backend-config="bucket=ops2dev-tfstatebucket-96173"