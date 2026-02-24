resource "null_resource" "eks_create" {
  triggers = {
    cluster_name = var.cluster_name
    region       = var.aws_region
    node_type    = var.node_instance_type
    nodes        = tostring(var.node_desired_capacity)
  }

  provisioner "local-exec" {
    command = <<EOC
if ! command -v eksctl >/dev/null 2>&1; then
  echo "eksctl not found. Install eksctl first: https://eksctl.io/"
  exit 1
fi

eksctl create cluster \
  --name ${var.cluster_name} \
  --version ${var.cluster_version} \
  --region ${var.aws_region} \
  --nodes ${var.node_desired_capacity} \
  --node-type ${var.node_instance_type} \
  --nodes-min ${var.node_min_capacity} \
  --nodes-max ${var.node_max_capacity} \
  ${var.key_name != "" ? "--node-ssh-access --ssh-public-key ${var.key_name}" : ""}

EOC
  }
}
