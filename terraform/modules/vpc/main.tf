# ── VPC ───────────────────────────────────────────────────────────────────────
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.cluster_name}-vpc"
  }
}

# ── Internet gateway ──────────────────────────────────────────────────────────
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.cluster_name}-igw"
  }
}

# ── Public subnets ────────────────────────────────────────────────────────────
resource "aws_subnet" "public" {
  count                   = length(var.azs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name                                        = "${var.cluster_name}-public-${var.azs[count.index]}"
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

# ── Private subnets ───────────────────────────────────────────────────────────
resource "aws_subnet" "private" {
  count             = length(var.azs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index]

  tags = {
    Name                                        = "${var.cluster_name}-private-${var.azs[count.index]}"
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

# ── NAT gateway (one per public subnet for HA) ────────────────────────────────
resource "aws_eip" "nat" {
  count  = length(var.azs)
  domain = "vpc"

  tags = {
    Name = "${var.cluster_name}-nat-eip-${var.azs[count.index]}"
  }
}

resource "aws_nat_gateway" "main" {
  count         = length(var.azs)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "${var.cluster_name}-nat-${var.azs[count.index]}"
  }

  depends_on = [aws_internet_gateway.main]
}

# ── Public route table ────────────────────────────────────────────────────────
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.cluster_name}-rt-public"
  }
}

resource "aws_route_table_association" "public" {
  count          = length(var.azs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ── Private route tables (one per AZ → its NAT gateway) ──────────────────────
resource "aws_route_table" "private" {
  count  = length(var.azs)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  tags = {
    Name = "${var.cluster_name}-rt-private-${var.azs[count.index]}"
  }
}

resource "aws_route_table_association" "private" {
  count          = length(var.azs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# ── VPC endpoints ─────────────────────────────────────────────────────────────
# Uncomment in Phase 6 once observability is in place to verify traffic routing.
# These keep AWS API traffic off the NAT gateway — reducing cost and latency.

# S3 gateway endpoint (free — no hourly charge)
# resource "aws_vpc_endpoint" "s3" {
#   vpc_id            = aws_vpc.main.id
#   service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
#   vpc_endpoint_type = "Gateway"
#   route_table_ids   = aws_route_table.private[*].id
#
#   tags = {
#     Name = "${var.cluster_name}-endpoint-s3"
#   }
# }

# ECR API interface endpoint (~$0.01/hr per AZ)
# resource "aws_vpc_endpoint" "ecr_api" {
#   vpc_id              = aws_vpc.main.id
#   service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.api"
#   vpc_endpoint_type   = "Interface"
#   subnet_ids          = aws_subnet.private[*].id
#   security_group_ids  = [aws_security_group.vpc_endpoints.id]
#   private_dns_enabled = true
#
#   tags = {
#     Name = "${var.cluster_name}-endpoint-ecr-api"
#   }
# }

# ECR DKR interface endpoint (~$0.01/hr per AZ)
# resource "aws_vpc_endpoint" "ecr_dkr" {
#   vpc_id              = aws_vpc.main.id
#   service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.dkr"
#   vpc_endpoint_type   = "Interface"
#   subnet_ids          = aws_subnet.private[*].id
#   security_group_ids  = [aws_security_group.vpc_endpoints.id]
#   private_dns_enabled = true
#
#   tags = {
#     Name = "${var.cluster_name}-endpoint-ecr-dkr"
#   }
# }

# CloudWatch Logs interface endpoint (~$0.01/hr per AZ)
# resource "aws_vpc_endpoint" "logs" {
#   vpc_id              = aws_vpc.main.id
#   service_name        = "com.amazonaws.${data.aws_region.current.name}.logs"
#   vpc_endpoint_type   = "Interface"
#   subnet_ids          = aws_subnet.private[*].id
#   security_group_ids  = [aws_security_group.vpc_endpoints.id]
#   private_dns_enabled = true
#
#   tags = {
#     Name = "${var.cluster_name}-endpoint-logs"
#   }
# }

# STS interface endpoint — required for IRSA (Phase 4)
# resource "aws_vpc_endpoint" "sts" {
#   vpc_id              = aws_vpc.main.id
#   service_name        = "com.amazonaws.${data.aws_region.current.name}.sts"
#   vpc_endpoint_type   = "Interface"
#   subnet_ids          = aws_subnet.private[*].id
#   security_group_ids  = [aws_security_group.vpc_endpoints.id]
#   private_dns_enabled = true
#
#   tags = {
#     Name = "${var.cluster_name}-endpoint-sts"
#   }
# }

# EC2 interface endpoint (~$0.01/hr per AZ)
# resource "aws_vpc_endpoint" "ec2" {
#   vpc_id              = aws_vpc.main.id
#   service_name        = "com.amazonaws.${data.aws_region.current.name}.ec2"
#   vpc_endpoint_type   = "Interface"
#   subnet_ids          = aws_subnet.private[*].id
#   security_group_ids  = [aws_security_group.vpc_endpoints.id]
#   private_dns_enabled = true
#
#   tags = {
#     Name = "${var.cluster_name}-endpoint-ec2"
#   }
# }

# Security group for interface endpoints — uncomment alongside the endpoints above
# resource "aws_security_group" "vpc_endpoints" {
#   name        = "${var.cluster_name}-vpc-endpoints"
#   description = "Allow HTTPS from within the VPC to interface endpoints"
#   vpc_id      = aws_vpc.main.id
#
#   ingress {
#     from_port   = 443
#     to_port     = 443
#     protocol    = "tcp"
#     cidr_blocks = [var.vpc_cidr]
#   }
#
#   tags = {
#     Name = "${var.cluster_name}-sg-vpc-endpoints"
#   }
# }

# Data source needed by endpoint service names — uncomment alongside endpoints
# data "aws_region" "current" {}