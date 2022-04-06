# aws_iam_role

resource "aws_iam_role" "worker" {
  name = var.name

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY

}

resource "aws_iam_instance_profile" "worker" {
  name = var.name
  role = aws_iam_role.worker.name
}

resource "aws_iam_role_policy_attachment" "worker_AmazonS3FullAccess" {
  role       = aws_iam_role.worker.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "worker_AmazonSSMManagedInstanceCore" {
  role       = aws_iam_role.worker.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
