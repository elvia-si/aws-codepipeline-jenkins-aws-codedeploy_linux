terraform {
  backend "s3" {
    bucket         = "my-bucket-802713609819-tfstates"
    key            = "training/codepipeline/terraform.tfstates"
    dynamodb_table = "terraform-lock"
  }
}