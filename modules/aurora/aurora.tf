# 下記は「AWS Systems Manager」で管理するすること
# データベース名
# マスターユーザー名
# マスターパスワード
#
# コマンド
# $ aws ssm put-parameter --name "/sample/db/name" --value sample --type String 
# $ aws ssm put-parameter --name "/sample/db/username" --value sample --type String 
# $ aws ssm put-parameter --name "/sample/db/password" --value sample --type String
resource "aws_iam_role" "audit" {
  name = "sample-rds-cluster-audit"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "rds.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = {
    Name = "dev"
  }
}

# FYI. https://dev.classmethod.jp/cloud/aws/amazon-aurora-audit-events-cloudwatch-logs/
resource "aws_iam_policy" "audit_policy" {
  name = "sample-aurora-audit-policy"

  policy = <<EOL
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "EnableCreationAndManagementOfRDSCloudwatchLogGroups",
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:PutRetentionPolicy"
      ],
      "Resource": [
        "arn:aws:logs:*:*:log-group:/aws/rds/*"
      ]
    },
    {
      "Sid": "EnableCreationAndManagementOfRDSCloudwatchLogStreams",
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams",
        "logs:GetLogEvents"
      ],
      "Resource": [
        "arn:aws:logs:*:*:log-group:/aws/rds/*:log-stream:*"
      ]
    }
  ]
}
EOL
}

resource "aws_iam_policy_attachment" "attach_audit_policy" {
  name       = "sample-attach-audit-policy"
  roles      = ["${aws_iam_role.audit.name}"]
  policy_arn = "${aws_iam_policy.audit_policy.arn}"
}

# Auroraサブネット
resource "aws_db_subnet_group" "this" {
  name       = "sample-db-sg"
  subnet_ids = ["${var.private_subnets}"]

  tags = {
    Name = "dev"
  }
}

# Auroraセキュリティグループ
resource "aws_security_group" "aurora" {
  name   = "sample-aurora-sg"
  vpc_id = "${var.vpc_id}"

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr_block}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "dev"
  }
}

# Auroraパラメータグループ
resource "aws_rds_cluster_parameter_group" "this" {
  name        = "sample-rds-cluster-pg"
  family      = "aurora5.6"

  parameter {
    name  = "character_set_client"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_connection"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_database"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_results"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }

  parameter {
    name  = "collation_connection"
    value = "utf8mb4_bin"
  }

  parameter {
    name  = "collation_server"
    value = "utf8mb4_bin"
  }

  parameter {
    name         = "binlog_format"
    value        = "MIXED"
    apply_method = "pending-reboot"
  }

  parameter {
    name  = "server_audit_logging"
    value = "1"
  }

  parameter {
    name  = "server_audit_events"
    value = "connect,query,query_dcl,query_ddl,query_dml,table"
  }

  parameter {
    name  = "server_audit_logs_upload"
    value = "1"
  }

  parameter {
    name  = "aws_default_logs_role"
    value = "${aws_iam_role.audit.arn}"
  }

  parameter {
    name  = "time_zone"
    value = "${var.time_zone}"
  }
}
