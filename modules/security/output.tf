output "master-sg" {
  value = aws_security_group.sg["master"]
}

output "worker-sg" {
  value = aws_security_group.sg["worker"]
}

output "ansible-sg" {
  value = aws_security_group.sg["ansible"]
}

output "efs-sg" {
  value = aws_security_group.sg["efs"]
}
