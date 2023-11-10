output "bucket" {
  value = aws_s3_bucket.terraform_state.id
}

output "key" {
  value = aws_s3_bucket.terraform_state.id
 
}

output "dynamodb_table" {
  value = aws_dynamodb_table.dynamodb-terraform-state-lock.name
  }
