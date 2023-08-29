provider "aws" {
  region = "us-east-1"
}

# Create a security group for ECS instances
resource "aws_security_group" "ecs_security_group" {
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["186.6.124.0/24"]  # Replace with your IP address
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["186.6.124.0/24"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["186.6.124.0/24"]
  }
}

# Create an ECS cluster
resource "aws_ecs_cluster" "ecs_dev_cluster" {
  name = "app-cluster"
}

# Create an RDS instance
resource "aws_db_instance" "rds_postgres_db" {
  allocated_storage = 10
  storage_type      = "gp2"
  engine            = "postgres"
  engine_version    = "15.3"
  instance_class    = "db.t3.micro"
  username          = var.RDS_USER
  password          = var.RDS_PASSWORD
}

resource "aws_default_vpc" "default_vpc" {
}

# Provide references to your default subnets
resource "aws_default_subnet" "default_subnet_a" {
  availability_zone = "us-east-1a"
}

resource "aws_default_subnet" "default_subnet_b" {
  availability_zone = "us-east-1b"
}

#IAM Role for the ECS task
  resource "aws_iam_role" "ecsTaskRole" {
    name = "ecs-task-role"

    assume_role_policy = jsonencode({
      Version = "2012-10-17",
      Statement = [
        {
          Action = "sts:AssumeRole",
          Effect = "Allow",
          Principal = {
            Service = "ecs-tasks.amazonaws.com"
          }
        }
      ]
    })
  }

# ECS Task definition
resource "aws_ecs_task_definition" "app_task" {
  family                   = "devops-app-task"
  network_mode             = "awsvpc"
  memory                   = 4096
  cpu                      = 2048
  requires_compatibilities = ["FARGATE"]

  execution_role_arn = aws_iam_role.ecsTaskRole.arn

  container_definitions = jsonencode([
    {
      name  = "testdevops"
      image = "public.ecr.aws/l9y1a7c9/jorg3r/challenge_devops:latest"
      environment = [
        {
          name  = "DB_HOST",
          value = aws_db_instance.rds_postgres_db.endpoint
        },
        {
          name  = "RDS_USER",
          value = var.RDS_USER
        },
        {
          name  = "RDS_PASSWORD",
          value = var.RDS_PASSWORD
        }
      ]
      "portMappings": [
        {
          "containerPort": 8080,
          "hostPort": 8080
        },
        {
            "containerPort": 80,
            "hostPort": 80
          }
      ],
    }
  ])
}

# Define ECS service
resource "aws_ecs_service" "ecs_service" {
  name             = "my-ecs-service"
  cluster          = aws_ecs_cluster.ecs_dev_cluster.id
  task_definition  = aws_ecs_task_definition.app_task.arn
  desired_count    = 1
  launch_type      = "FARGATE"

  network_configuration {
    subnets = ["${aws_default_subnet.default_subnet_a.id}", "${aws_default_subnet.default_subnet_b.id}"]
    security_groups = [aws_security_group.ecs_security_group.id]
  }
}
