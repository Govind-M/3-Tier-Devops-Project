output "cluster_id" {
  value = aws_eks_cluster.devops.id
}

output "node_group_id" {
  value = aws_eks_node_group.devops.id
}

output "vpc_id" {
  value = data.aws_vpc.default.id
}

output "subnet_ids" {
  value = aws_subnet.devops_subnet[*].id
}
