resource "aws_iam_role" "node" {
  name = "eks-node-group"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node.name
}

resource "aws_iam_policy" "worker_policy" {
  name        = "worker-policy"
  description = "Worker policy for the ALB Ingress"
  policy = file("configs/worker-policy.json")
}

resource "aws_iam_role_policy_attachment" "ALBIngressEKSPolicyCustom" {
  policy_arn = aws_iam_policy.worker_policy.arn
  role       = aws_iam_role.node.name
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 18.0"
  cluster_name    = "se-bootcamp-cluster"
  cluster_version = "1.23"
  subnet_ids = ["subnet-0c372435803c847b1", "subnet-02a86967c1401972f", "subnet-04f5b2efc96d6eda5"]
  vpc_id = "vpc-0db46f0dfba87b815"
  cluster_encryption_config = [
    {
        provider_key_arn = aws_kms_key.eks.arn
        resources = ["secrets"]
    }
  ]
}

resource "aws_kms_key" "eks" {
  description             = "EKS Secret Encryption Key"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

resource "aws_eks_node_group" "default-node-pool" {
  cluster_name    = module.eks.cluster_name
  version         = "1.23"
  node_group_name = "bootcamp-se-private-node-pool"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = ["subnet-0c372435803c847b1", "subnet-02a86967c1401972f", "subnet-04f5b2efc96d6eda5"]
  disk_size       = 100
  instance_types  = ["m6i.xlarge"]
  scaling_config {
    desired_size = 6
    max_size     = 30
    min_size     = 6
  }
  update_config {
    max_unavailable = 3
  }
  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.ALBIngressEKSPolicyCustom
  ]
}


module "eks_blueprints_kubernetes_addons" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints//modules/kubernetes-addons"

  eks_cluster_id = module.eks.cluster_id

  # EKS Addons

  enable_amazon_eks_aws_ebs_csi_driver  = true
  enable_amazon_eks_kube_proxy          = true
  enable_amazon_eks_vpc_cni             = true

  #K8s Add-ons
#   enable_aws_for_fluentbit             = true
  # enable_cluster_autoscaler            = true
  # enable_metrics_server                = true


  depends_on = [
    aws_eks_node_group.default-node-pool
  ]
}

resource "helm_release" "ingress" {
  name       = "aws-load-balancer-controller"
  chart      = "./aws-load-balancer-controller"
  namespace = "kube-system"
  values = [file("aws-load-balancer-controller/values.yaml")]
  depends_on = [
    module.eks_blueprints_kubernetes_addons
  ]
}

data "kubectl_file_documents" "aws-auth-cm" {
    content = file("configs/aws-auth-cm.yaml")
}

resource "kubectl_manifest" "aws-auth" {
    for_each  = data.kubectl_file_documents.aws-auth-cm.manifests
    yaml_body = each.value
    depends_on = [
      module.eks,
      aws_eks_node_group.default-node-pool
    ]
}
