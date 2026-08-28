# ============================================================
# Availability Zones
# ============================================================

data "aws_availability_zones" "available" {
  state = "available"
}


# ============================================================
# VPC
# ============================================================

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "${var.project_name}-vpc"
    Environment = var.environment
  }
}


# ============================================================
# Internet Gateway
# ============================================================

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.project_name}-igw"
    Environment = var.environment
  }
}


# ============================================================
# Public Subnets
# ============================================================

resource "aws_subnet" "public" {
  count = 2

  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.${count.index + 1}.0/24"
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-public-${count.index + 1}"
    Environment = var.environment
    Tier        = "public"
  }
}


# ============================================================
# Private Subnets
# ============================================================

resource "aws_subnet" "private" {
  count = 2

  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 10}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name        = "${var.project_name}-private-${count.index + 1}"
    Environment = var.environment
    Tier        = "private"
  }
}


# ============================================================
# Public Route Table
# ============================================================

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "${var.project_name}-public-rt"
    Environment = var.environment
  }
}


# ============================================================
# Public Route Table Associations
# ============================================================

resource "aws_route_table_association" "public" {
  count = 2

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}


# ============================================================
# NAT Gateway Elastic IP
# ============================================================

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name        = "${var.project_name}-nat-eip"
    Environment = var.environment
  }
}


# ============================================================
# NAT Gateway
# ============================================================

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  depends_on = [
    aws_internet_gateway.main
  ]

  tags = {
    Name        = "${var.project_name}-nat"
    Environment = var.environment
  }
}


# ============================================================
# Private Route Table
# ============================================================

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.project_name}-private-rt"
    Environment = var.environment
  }
}


# ============================================================
# Private Route Table - NAT Route
# ============================================================

resource "aws_route" "private_nat" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main.id
}


# ============================================================
# Private Route Table Associations
# ============================================================

resource "aws_route_table_association" "private" {
  count = 2

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}


# ============================================================
# Security Group - Application Load Balancer
# ============================================================

resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow HTTP from Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-alb-sg"
    Environment = var.environment
  }
}


# ============================================================
# Security Group - Application / EC2
# ============================================================

resource "aws_security_group" "app" {
  name        = "${var.project_name}-app-sg"
  description = "Security group for application EC2"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Allow application traffic from ALB"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-app-sg"
    Environment = var.environment
  }
}


# ============================================================
# Security Group - PostgreSQL / RDS
# ============================================================

resource "aws_security_group" "database" {
  name        = "${var.project_name}-db-sg"
  description = "Security group for PostgreSQL RDS"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Allow PostgreSQL from application"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-db-sg"
    Environment = var.environment
  }
}


# ============================================================
# RDS Subnet Group
# ============================================================

resource "aws_db_subnet_group" "postgres" {
  name = "${var.project_name}-postgres-subnet-group"

  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name        = "${var.project_name}-postgres-subnet-group"
    Environment = var.environment
  }
}


# ============================================================
# PostgreSQL RDS
# ============================================================

resource "aws_db_instance" "postgres" {
  identifier = "${var.project_name}-postgres"

  engine         = "postgres"
  engine_version = "16"

  instance_class = "db.t4g.micro"

  allocated_storage     = 20
  max_allocated_storage = 50
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  port = 5432

  db_subnet_group_name   = aws_db_subnet_group.postgres.name
  vpc_security_group_ids = [aws_security_group.database.id]

  publicly_accessible = false

  backup_retention_period = 1
  skip_final_snapshot     = true

  deletion_protection = false

  tags = {
    Name        = "${var.project_name}-postgres"
    Environment = var.environment
  }
}   