provider "aws" {
  region = "eu-north-1"
}

resource "aws_vpc" "pulse_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = { Name = "pulse_vpc" }
}

resource "aws_db_instance" "pulse_db" {
  allocated_storage = 20
  engine = "postgres"
  engine_version = "16.13"
  instance_class = "db.t3.micro"
  db_name = "pulse_db"
  username = "postgres"
  password = var.db_password
  parameter_group_name = "default.postgres16"
  skip_final_snapshot = true
  publicly_accessible = true 
}

output "rds_endpoint" {
  value = aws_db_instance.pulse_db.endpoint
}
