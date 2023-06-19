resource "aws_ssm_parameter" "dr_ssm_parameter_name_prefix" {
  name  = "dr_ssm_parameter_name_prefix"
  type  = "String"
  value = var.ssm_parameter_name_prefix
}

resource "aws_ssm_parameter" "dr_s3_bucket_name_prefix" {
  name  = format("%s/%s", var.ssm_parameter_name_prefix, "s3_bucket_name_prefix")
  type  = "String"
  value = var.bucket_name_prefix
}

resource "aws_ssm_parameter" "dr_world_name" {
  name  = format("%s/%s", var.ssm_parameter_name_prefix, "world_name")
  type  = "String"
  value = var.dr_world_name
}

resource "aws_ssm_parameter" "dr_model_base_name" {
  name  = format("%s/%s", var.ssm_parameter_name_prefix, "model_base")
  type  = "String"
  value = var.dr_model_base_name
}

resource "aws_ssm_parameter" "dr_track_direction" {
  name  = format("%s/%s", var.ssm_parameter_name_prefix, "direction")
  type  = "String"
  value = var.dr_track_direction
}

