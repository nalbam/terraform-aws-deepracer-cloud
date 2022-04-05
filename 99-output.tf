# output

output "bucket_local" {
  value = aws_s3_bucket.local.id
}

output "bucket_upload" {
  value = aws_s3_bucket.upload.id
}

output "public_ip" {
  value = aws_eip.worker.public_ip
}
