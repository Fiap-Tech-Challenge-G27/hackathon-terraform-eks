data "aws_iam_policy_document" "policyDocEKS" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "roleEKS" {
  name               = "roleEKSFargate"
  assume_role_policy = data.aws_iam_policy_document.policyDocEKS.json

  inline_policy {
    name = "EKSEC2Policy"

    policy = jsonencode({
      Version = "2012-10-17",
      Statement = [{
        Effect   = "Allow",
        Action   = [
          "ec2:DescribeInstances",
        ],
        Resource = "*",
      }],
    })
  }
}

resource "aws_iam_role_policy_attachment" "policyEKSAmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.roleEKS.name
}

resource "aws_iam_role_policy_attachment" "policyEKSAmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.roleEKS.name
}

resource "aws_eks_cluster" "clusterFiapHackathon" {
  name     = "fiap-hackathon"
  role_arn = aws_iam_role.roleEKS.arn

  vpc_config {
    subnet_ids = [data.aws_subnet.subnet1.id, data.aws_subnet.subnet2.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.policyEKSAmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.policyEKSAmazonEKSVPCResourceController,
  ]
}

resource "aws_iam_role" "roleFargate" {
  name = "roleFargate"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "eks-fargate-pods.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "fargatePolicyRoleFargate" {
  role       = aws_iam_role.roleFargate.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
}

resource "aws_eks_fargate_profile" "fargateProfileFiapHackathon" {
  cluster_name = aws_eks_cluster.clusterFiapHackathon.name
  fargate_profile_name = "fargateProfileFiapHackathon"
  pod_execution_role_arn = aws_iam_role.roleFargate.arn
  subnet_ids = [data.aws_subnet.subnet1.id, data.aws_subnet.subnet2.id]

  selector {
    namespace = "default"
  }

  depends_on = [
    aws_iam_role_policy_attachment.fargatePolicyRoleFargate,
  ]
}

data "tls_certificate" "thumbprint_eks" {
  url = aws_eks_cluster.clusterFiapHackathon.identity.0.oidc.0.issuer
}

resource "aws_iam_openid_connect_provider" "oidc_eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.thumbprint_eks.certificates.0.sha1_fingerprint]
  url             = aws_eks_cluster.clusterFiapHackathon.identity.0.oidc.0.issuer
}
