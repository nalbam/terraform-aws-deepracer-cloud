resource "aws_s3_bucket_object" "custom_files_s3_upload" {
  for_each = fileset("custom_files/", "*")
  bucket   = aws_s3_bucket.local.id
  key      = format("%s/%s", var.dr_world_name, each.value)
  source   = "custom_files/${each.value}"
  etag     = filemd5("custom_files/${each.value}")
}
