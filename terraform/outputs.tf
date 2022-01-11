output "clover_server_ip" {
  value = aws_instance.clover.private_ip
}

output "rds_instance_address" {
  value = aws_db_instance.sqlserver.address
}