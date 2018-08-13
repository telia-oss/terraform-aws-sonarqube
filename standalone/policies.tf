resource "aws_iam_policy" "sonarqube-task-pol" {
  name = "${var.prefix}-task-pol"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ssm:DescribeParameters"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ssm:GetParameters"
            ],
            "Resource": "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/${var.prefix}/*"
        },
        {
            "Sid": "",
            "Effect": "Allow",
            "Action": [
                "ecs:Submit*",
                "ecs:StartTelemetrySession",
                "ecs:RegisterContainerInstance",
                "ecs:Poll",
                "ecs:DiscoverPollEndpoint",
                "ecs:DeregisterContainerInstance",
                "ecs:CreateCluster",
                "ecr:ListImages",
                "ecr:GetRepositoryPolicy",
                "ecr:GetDownloadUrlForLayer",
                "ecr:GetAuthorizationToken",
                "ecr:DescribeRepositories",
                "ecr:DescribeImages",
                "ecr:BatchGetImage",
                "ecr:BatchCheckLayerAvailability"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

data "aws_iam_policy_document" "task-role-policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "kmsfortaskpol" {
  name = "kms-access-for-${var.prefix}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "kms:*"
      ],
      "Effect": "Allow",
      "Resource": "${var.ssm_key}"
    }
  ]
}
EOF
}