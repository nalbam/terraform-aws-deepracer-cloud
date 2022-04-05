# bucket

resource "aws_s3_bucket" "local" {
  bucket = format("aws-deepracer-%s-local", local.account_id)
}

resource "aws_s3_bucket" "upload" {
  bucket = format("aws-deepracer-%s-upload", local.account_id)
}
