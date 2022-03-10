output "server_ip" {
  value = aws_instance.my_jenkins_server.public_ip
}