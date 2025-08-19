provider "aws" {
  region = "ap-south-1"
}

data "aws_vpc" "default"{
    default = true
}

resource "aws_subnet" "devops_subnet" {
  count = 2
  vpc_id                  = data.aws_vpc.default.id
  cidr_block              = cidrsubnet(data.aws_vpc.default.cidr_block, 8, count.index+64)
  availability_zone       = element(["ap-south-1a", "ap-south-1b"], count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "devops-subnet-${count.index}"
  }
}

data "aws_internet_gateway" "default_igw" {
  filter {
    name   = "attachment.vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_route_table" "devops_route_table" {
  vpc_id = data.aws_vpc.default.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = data.aws_internet_gateway.default_igw.id
  }

  tags = {
    Name = "devops-route-table"
  }
}

resource "aws_route_table_association" "devops_association" {
  count          = 2
  subnet_id      = aws_subnet.devops_subnet[count.index].id
  route_table_id = aws_route_table.devops_route_table.id
}

resource "aws_security_group" "devops_cluster_sg" {
  vpc_id = data.aws_vpc.default.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "devops-cluster-sg"
  }
}

resource "aws_security_group" "devops_node_sg" {
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "devops-node-sg"
  }
}

resource "aws_eks_cluster" "devops" {
  name     = "devops-cluster"
  role_arn = aws_iam_role.devops_cluster_role.arn

  vpc_config {
    subnet_ids         = aws_subnet.devops_subnet[*].id
    security_group_ids = [aws_security_group.devops_cluster_sg.id]
  }
}


resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name    = aws_eks_cluster.devops.name
  addon_name      = "aws-ebs-csi-driver"
  
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
}


resource "aws_eks_node_group" "devops" {
  cluster_name    = aws_eks_cluster.devops.name
  node_group_name = "devops-node-group"
  node_role_arn   = aws_iam_role.devops_node_group_role.arn
  subnet_ids      = aws_subnet.devops_subnet[*].id

  scaling_config {
    desired_size = 3
    max_size     = 3
    min_size     = 3
  }

  instance_types = ["t2.medium"]

  remote_access {
    ec2_ssh_key = var.ssh_key_name
    source_security_group_ids = [aws_security_group.devops_node_sg.id]
  }
}

resource "aws_iam_role" "devops_cluster_role" {
  name = "devops-cluster-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "devops_cluster_role_policy" {
  role       = aws_iam_role.devops_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role" "devops_node_group_role" {
  name = "devops-node-group-role"

  assume_role_policy = <<EOF
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
EOF
}

resource "aws_iam_role_policy_attachment" "devops_node_group_role_policy" {
  role       = aws_iam_role.devops_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "devops_node_group_cni_policy" {
  role       = aws_iam_role.devops_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "devops_node_group_registry_policy" {
  role       = aws_iam_role.devops_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "devops_node_group_ebs_policy" {
  role       = aws_iam_role.devops_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}
