# CodeCommit
resource "aws_codecommit_repository" "this" {
  repository_name = "sample"
  description     = "This is the Sample App Repository"

  lifecycle {
    ignore_changes = ["repository_name"]
  }
}

# CodeBuild
data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

resource "aws_iam_role" "codebuild" {
  name = "sample-CodeBuild"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": [
        "sts:AssumeRole"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "codebuild" {
  name = "codebuild_policy"
  role = "${aws_iam_role.codebuild.id}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Resource": [
                "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/${var.service_name}-project",
                "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/${var.service_name}-project:*"
            ],
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ]
        },
        {
            "Effect": "Allow",
            "Resource": [
                "arn:aws:s3:::codepipeline-${var.service_name}-bucket*"
            ],
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:GetObjectVersion",
                "s3:GetBucketAcl",
                "s3:GetBucketLocation"
            ]
        },
        {
            "Effect": "Allow",
            "Resource": [
                "arn:aws:codecommit:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.service_name}"
            ],
            "Action": [
                "codecommit:GitPull"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "ssm:GetParameters",
                "secretsmanager:GetSecretValue",
                "kms:Decrypt"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "codebuild" {
  role       = "${aws_iam_role.codebuild.name}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

data "aws_ssm_parameter" "database_name" {
  name = "/${var.service_name}/db/name"
}

data "aws_ssm_parameter" "master_username" {
  name = "/${var.service_name}/db/username"
}

data "aws_ssm_parameter" "master_password" {
  name = "/${var.service_name}/db/password"
}

resource "aws_codebuild_project" "this" {
  name          = "sample"
  description   = "sample_codebuild_project"
  build_timeout = "5"
  service_role  = "${aws_iam_role.codebuild.arn}"

  artifacts {
    type = "NO_ARTIFACTS"
  }

  vpc_config {
    vpc_id             = "${var.vpc_id}"
    subnets            = ["${var.private_subnets}"]
    security_group_ids = ["${var.db_security_group_id}"]
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/docker:18.09.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true

    environment_variable {
      "name"  = "IMAGE_TAG"
      "value" = "latest"
    }

    environment_variable {
      "name"  = "IMAGE_REPO_NAME"
      "value" = "sample"
    }

    environment_variable {
      "name"  = "AWS_ACCOUNT_ID"
      "value" = "${data.aws_caller_identity.current.account_id}"
    }

    environment_variable {
      "name"  = "AWS_DEFAULT_REGION"
      "value" = "${data.aws_region.current.name}"
    }

    environment_variable {
      "name"  = "DB_HOST"
      "value" = "${var.db_host}"
    }

    environment_variable {
      "name"  = "DB_NAME"
      "value" = "${data.aws_ssm_parameter.database_name.value}"
    }

    environment_variable {
      "name"  = "DB_USERNAME"
      "value" = "${data.aws_ssm_parameter.master_username.value}"
    }

    environment_variable {
      "name"  = "DB_PASSWORD"
      "value" = "${data.aws_ssm_parameter.master_password.name}"
      "type"  = "PARAMETER_STORE"
    }

    environment_variable {
      "name"  = "RAILS_ENV"
      "value" = "${var.rails_env}"
    }
  }

  source {
    type            = "CODECOMMIT"
    location        = "${aws_codecommit_repository.this.clone_url_http}"
    git_clone_depth = 5
  }

  tags = {
    "Environment" = "dev"
  }
}

# CodeDeploy
resource "aws_iam_role" "codedeploy" {
  name = "ecsCodeDeployRole"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "codedeploy.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "codedeploy" {
  role       = "${aws_iam_role.codedeploy.name}"
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
}

resource "aws_codedeploy_app" "web" {
  compute_platform = "ECS"
  name             = "sample"

  lifecycle {
    ignore_changes = ["name"]
  }
}

resource "aws_codedeploy_deployment_group" "web" {
  app_name               = "${aws_codedeploy_app.web.name}"
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
  deployment_group_name  = "web"
  service_role_arn       = "${aws_iam_role.codedeploy.arn}"

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }

    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 20
    }
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  ecs_service {
    cluster_name = "${var.ecs_cluster_name}"
    service_name = "${var.ecs_service_name}"
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = ["${var.lb_https_listener_blue_arn}"]
      }

      test_traffic_route {
        listener_arns = ["${var.lb_https_listener_green_arn}"]
      }

      target_group {
        name = "${var.lb_target_group_blue_name}"
      }

      target_group {
        name = "${var.lb_target_group_green_name}"
      }
    }
  }

  depends_on = [
    "aws_codedeploy_app.web",
  ]

  # https://github.com/terraform-providers/terraform-provider-aws/issues/7128#issuecomment-461423222
  lifecycle {
    ignore_changes = ["blue_green_deployment_config"]
  }
}

# CodePipeline
resource "aws_s3_bucket" "codepipeline" {
  bucket = "codepipeline-sample-bucket"
  acl    = "private"
}

resource "aws_iam_role" "codepipeline" {
  name = "sample-CodePipeline"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "codepipeline_policy"
  role = "${aws_iam_role.codepipeline.id}"

  policy = <<EOF
{
    "Statement": [
        {
            "Action": [
                "iam:PassRole"
            ],
            "Resource": "*",
            "Effect": "Allow",
            "Condition": {
                "StringEqualsIfExists": {
                    "iam:PassedToService": [
                        "cloudformation.amazonaws.com",
                        "elasticbeanstalk.amazonaws.com",
                        "ec2.amazonaws.com",
                        "ecs-tasks.amazonaws.com"
                    ]
                }
            }
        },
        {
            "Action": [
                "codecommit:CancelUploadArchive",
                "codecommit:GetBranch",
                "codecommit:GetCommit",
                "codecommit:GetUploadArchiveStatus",
                "codecommit:UploadArchive"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "codedeploy:CreateDeployment",
                "codedeploy:GetApplication",
                "codedeploy:GetApplicationRevision",
                "codedeploy:GetDeployment",
                "codedeploy:GetDeploymentConfig",
                "codedeploy:RegisterApplicationRevision"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "elasticbeanstalk:*",
                "ec2:*",
                "elasticloadbalancing:*",
                "autoscaling:*",
                "cloudwatch:*",
                "s3:*",
                "sns:*",
                "cloudformation:*",
                "rds:*",
                "sqs:*",
                "ecs:*"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "lambda:InvokeFunction",
                "lambda:ListFunctions"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "codebuild:BatchGetBuilds",
                "codebuild:StartBuild"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Effect": "Allow",
            "Action": [
                "servicecatalog:ListProvisioningArtifacts",
                "servicecatalog:CreateProvisioningArtifact",
                "servicecatalog:DescribeProvisioningArtifact",
                "servicecatalog:DeleteProvisioningArtifact",
                "servicecatalog:UpdateProduct"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ecr:DescribeImages"
            ],
            "Resource": "*"
        }
    ],
    "Version": "2012-10-17"
}
EOF
}

resource "aws_codepipeline" "this" {
  name     = "sample-pipeline"
  role_arn = "${aws_iam_role.codepipeline.arn}"

  artifact_store {
    location = "${aws_s3_bucket.codepipeline.bucket}"
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["source"]

      configuration = {
        RepositoryName       = "${aws_codecommit_repository.this.id}"
        BranchName           = "master"
        PollForSourceChanges = "false"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source"]
      output_artifacts = ["build"]
      version          = "1"

      configuration = {
        ProjectName = "${aws_codebuild_project.this.name}"
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeployToECS"
      input_artifacts = ["source", "build"]
      version         = "1"

      configuration {
        ApplicationName                = "${aws_codedeploy_app.web.name}"
        DeploymentGroupName            = "${aws_codedeploy_deployment_group.web.deployment_group_name}"
        Image1ArtifactName             = "build"
        Image1ContainerName            = "IMAGE1_NAME"
        TaskDefinitionTemplateArtifact = "source"
        TaskDefinitionTemplatePath     = "taskdef.json"
        AppSpecTemplateArtifact        = "source"
        AppSpecTemplatePath            = "appspec.yaml"
      }
    }
  }
}
