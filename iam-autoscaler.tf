##### STEP1 this data block creates iam policy which allow ASSUME ROLE POLICY TO SERVICE ACCOUNT which we create later 
#### creates an IAM policy document that allows the Kubernetes Cluster Autoscaler, running as the system:serviceaccount:kube-system:cluster-autoscaler service account, to assume an IAM role using the web identity tokens provided by the EKS cluster's OIDC provider. 
#### This is essential for the Cluster Autoscaler to interact with AWS resources (like EC2 instances) to scale your EKS cluster.

 #### policy = jsonencode(  copy-paste here Full Cluster Autoscaler Features Policy (Recommended) from link---https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/cloudprovider/aws/README.md
 #### so below policy we get from above link no need to copy by ursellf just copy code this github repo


data "aws_iam_policy_document" "eks_cluster_autoscaler_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:cluster-autoscaler"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
      type        = "Federated"
    }
  }
}

#STEP2 ROLE GETS ASSUME ROLE POLICY
resource "aws_iam_role" "eks_cluster_autoscaler" {
  assume_role_policy = data.aws_iam_policy_document.eks_cluster_autoscaler_assume_role_policy.json
  name               = "eks-cluster-autoscaler"
}


# STEP3 NOW CREATES REAL AUTOSCALER POLICY WITH JSON
resource "aws_iam_policy" "eks_cluster_autoscaler" {
  name = "eks-cluster-autoscaler"

  policy = jsonencode({       #### policy = jsonencode(  copy-paste here Full Cluster Autoscaler Features Policy (Recommended) from link---https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/cloudprovider/aws/README.md
    Statement = [{            #### so below policy we get from above link no need to copy by ursellf just copy code this github repo
      Action = [
                "autoscaling:DescribeAutoScalingGroups",
                "autoscaling:DescribeAutoScalingInstances",
                "autoscaling:DescribeLaunchConfigurations",
                "autoscaling:DescribeTags",
                "autoscaling:SetDesiredCapacity",
                "autoscaling:TerminateInstanceInAutoScalingGroup",
                "ec2:DescribeLaunchTemplateVersions"
            ]
      Effect   = "Allow"
      Resource = "*"
    }]
    Version = "2012-10-17"
  })
}

#STEP4 ABOVE POLICY ADDED TO ABOVE ROLE
resource "aws_iam_role_policy_attachment" "eks_cluster_autoscaler_attach" {
  role       = aws_iam_role.eks_cluster_autoscaler.name
  policy_arn = aws_iam_policy.eks_cluster_autoscaler.arn
}

output "eks_cluster_autoscaler_arn" {
  value = aws_iam_role.eks_cluster_autoscaler.arn
}



