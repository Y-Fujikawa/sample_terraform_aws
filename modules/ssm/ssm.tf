resource "aws_ssm_maintenance_window" "redash" {
  name     = "${terraform.workspace}-${var.service_name}-redash-ssm-maintenance-window"
  schedule = "cron(0 3 ? * * *)"
  duration = 3
  cutoff   = 1

  tags = {
    Environment = "${terraform.workspace}"
    Service     = "${terraform.workspace}-${var.service_name}-redash"
    Name        = "${terraform.workspace}-${var.service_name}-redash-ssm-maintenance-window"
  }
}

resource "aws_ssm_maintenance_window_target" "redash" {
  window_id     = "${aws_ssm_maintenance_window.redash.id}"
  name             = "${terraform.workspace}-${var.service_name}-redash-ssm-maintenance-window-target"
  description      = "${terraform.workspace}-${var.service_name}-redash-ssm-maintenance-window-target-description"
  resource_type = "INSTANCE"

  targets {
    key    = "tag:Name"
    values = ["${var.ec2_redash_name}"]
  }
}

# SSM Automation用
resource "aws_iam_role" "redash_ssm_automation" {
  name               = "${terraform.workspace}-${var.service_name}-redash-ssm-automation-role"
  description        = "Allows EC2 instances and Systems Manager to call AWS SSM Automation on your behalf."
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": ["ec2.amazonaws.com","ssm.amazonaws.com"]
      },
      "Action": "sts:AssumeRole"
    }
 ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "redash_ssm_automation" {
  role       = "${aws_iam_role.redash_ssm_automation.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonSSMAutomationRole"
}

# SSM Maintenance Windows用
data "aws_caller_identity" "current" {}

resource "aws_iam_policy" "redash_ssm_maintenance_windows" {
  name = "${terraform.workspace}-${var.service_name}-redash-ssm-maintenance-windows-policy"

  policy = <<EOL
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "VisualEditor0",
      "Effect": "Allow",
      "Action": "iam:PassRole",
      "Resource": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/AmazonSSMAutomationRole",
        "Condition": {
          "StringEqualsIfExists": {
            "iam:PassedToService": "ssm.amazonaws.com"
          }
        }
    }
  ]
}
EOL
}

resource "aws_iam_role" "redash_ssm_maintenance_windows" {
  name               = "${terraform.workspace}-${var.service_name}-redash-ssm-maintenance-windows-role"
  description        = "Allows EC2 instances and Systems Manager to call AWS SSM Maintenance Window on your behalf."
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": ["ec2.amazonaws.com","ssm.amazonaws.com"]
      },
      "Action": "sts:AssumeRole"
    }
 ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "redash_ssm_maintenance_windows" {
  role       = "${aws_iam_role.redash_ssm_maintenance_windows.name}"
  policy_arn = "${aws_iam_policy.redash_ssm_maintenance_windows.arn}"
}

# Lambda用
resource "aws_iam_role" "redash_ssm_lambda" {
  name               = "${terraform.workspace}-${var.service_name}-redash-ssm-lambda-role"
  description        = "Exec lambda from ssm."
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
 ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "redash_ssm_lambda" {
  role       = "${aws_iam_role.redash_ssm_lambda.name}"
  policy_arn = "arn:aws:iam::aws:policy/AWSLambdaExecute"
}

resource "aws_iam_policy" "redash_automation_ec2_create_image" {
  name = "${terraform.workspace}-${var.service_name}-automation-ec2-create-image"

  policy = <<EOL
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "VisualEditor0",
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeImages",
        "ec2:DeregisterImage",
        "ec2:DescribeInstances",
        "ec2:DeleteSnapshot",
        "ec2:DescribeTags",
        "ec2:CreateTags",
        "ec2:CreateImage",
        "ec2:DescribeSnapshots"
      ],
      "Resource": "*"
    }
  ]
}
EOL
}

resource "aws_iam_role_policy_attachment" "redash_ssm_lambda_2" {
  role       = "${aws_iam_role.redash_ssm_lambda.name}"
  policy_arn = "${aws_iam_policy.redash_automation_ec2_create_image.arn}"
}
