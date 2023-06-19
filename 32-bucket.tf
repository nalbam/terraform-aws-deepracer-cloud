# bucket

resource "aws_s3_bucket" "local" {
  bucket = format("%s-%s-train", var.bucket_name_prefix, local.account_id)
}

resource "aws_s3_bucket" "upload" {
  bucket = format("%s-%s-eval", var.bucket_name_prefix, local.account_id)
}

# output

output "bucket_local" {
  value = aws_s3_bucket.local.id
}

output "bucket_upload" {
  value = aws_s3_bucket.upload.id
}
