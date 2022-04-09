# aws_sns_topic

resource "aws_sns_topic" "worker" {
  name = format("%s-worker", var.name)
}

resource "aws_autoscaling_notification" "worker" {
  group_names = [
    aws_autoscaling_group.worker.name,
  ]

  notifications = [
    "autoscaling:EC2_INSTANCE_LAUNCH",
    "autoscaling:EC2_INSTANCE_TERMINATE",
    "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
    "autoscaling:EC2_INSTANCE_TERMINATE_ERROR",
  ]

  topic_arn = aws_sns_topic.worker.arn
}

# resource "aws_sns_topic_subscription" "worker" {
#   topic_arn = aws_sns_topic.worker.arn
#   protocol  = "lambda"
#   endpoint  = module.lambda.arn
# }

# resource "aws_lambda_permission" "worker" {
#   action        = "lambda:invokeFunction"
#   function_name = module.lambda.arn
#   principal     = "sns.amazonaws.com"
#   statement_id  = "AllowExecutionFromSNS"
#   source_arn    = aws_sns_topic.worker.arn
# }
