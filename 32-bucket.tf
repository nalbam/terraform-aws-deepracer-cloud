# bucket

resource "aws_s3_bucket" "local" {
  bucket = format("%s-%s-local", var.name, local.account_id)
}

resource "aws_s3_bucket" "upload" {
  bucket = format("%s-%s-upload", var.name, local.account_id)
}

# output

output "bucket_local" {
  value = aws_s3_bucket.local.id
}

output "bucket_upload" {
  value = aws_s3_bucket.upload.id
}
