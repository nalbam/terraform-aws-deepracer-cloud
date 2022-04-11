# bucket

resource "aws_s3_bucket" "local" {
  bucket = format("aws-deepracer-%s-local", local.account_id)
}

resource "aws_s3_bucket" "upload" {
  bucket = format("aws-deepracer-%s-upload", local.account_id)
}

# output

output "bucket_local" {
  value = aws_s3_bucket.local.id
}

output "bucket_upload" {
  value = aws_s3_bucket.upload.id
}
