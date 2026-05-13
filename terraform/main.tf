provider "aws" {
  region = "eu-north-1"
}

data "aws_availability_zones" "available" {}

locals {
  cluster_name = "pulse-eks"
}

# 1. VPC Module (Industry Standard)
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "pulse-vpc"
  cidr = "10.0.0.0/16"

  azs             = slice(data.aws_availability_zones.available.names, 0, 3)
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true
  
  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }
}

# 2. EKS Module
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = local.cluster_name
  cluster_version = "1.30"

  cluster_endpoint_public_access = true
  enable_cluster_creator_admin_permissions = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    pulse_nodes = {
      min_size     = 1
      max_size     = 3
      desired_size = 2

      instance_types = ["t3.small"] # Cheaper than medium, but enough for our app
      capacity_type  = "ON_DEMAND"
    }
  }
}

# 3. RDS Security Group (Allow traffic from EKS nodes)
resource "aws_security_group" "rds_sg" {
  name   = "pulse-rds-sg"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [module.eks.node_security_group_id]
  }

  # Also allow access from local machine for testing
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }
}

# 4. Create a DB Subnet Group (Required for RDS in a VPC)
resource "aws_db_subnet_group" "pulse_db_subnet" {
  name       = "pulse-db-subnet"
  subnet_ids = module.vpc.public_subnets # Public for now so you can connect from home
}

# 5. RDS Instance
resource "aws_db_instance" "pulse_db" {
  allocated_storage      = 20
  engine                 = "postgres"
  engine_version         = "16.13"
  instance_class         = "db.t3.micro"
  db_name                = "pulse_db"
  username               = "postgres"
  password               = var.db_password
  parameter_group_name   = "default.postgres16"
  skip_final_snapshot    = true
  publicly_accessible    = true
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.pulse_db_subnet.name
}
