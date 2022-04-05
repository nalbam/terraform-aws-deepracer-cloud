# output

output "public_ip" {
  value = aws_eip.worker.public_ip
}
