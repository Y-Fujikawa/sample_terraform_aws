# 下記は「AWS Systems Manager」で管理するすること
# データベース名
# マスターユーザー名
# マスターパスワード
#
# コマンド
# $ aws ssm put-parameter --name "/sample/db/name" --value sample --type String 
# $ aws ssm put-parameter --name "/sample/db/username" --value sample --type String 
# $ aws ssm put-parameter --name "/sample/db/password" --value samplesample --type String

# 監査ログのためのIAMロール
resource "aws_iam_role" "monitoring" {
  name = "${var.service_name}-rds-cluster-monitoring"

  assume_role_policy = <<EOL
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "monitoring.rds.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOL

  tags = {
    Environment = "${terraform.workspace}"
  }
}

# FYI. https://dev.classmethod.jp/cloud/aws/amazon-aurora-audit-events-cloudwatch-logs/
resource "aws_iam_policy" "monitoring_policy" {
  name = "${var.service_name}-aurora-monitoring-policy"

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

resource "aws_iam_policy_attachment" "monitoring" {
  name       = "${var.service_name}-attach-monitoring"
  roles      = ["${aws_iam_role.monitoring.name}"]
  policy_arn = "${aws_iam_policy.monitoring_policy.arn}"
}

# Auroraサブネット
resource "aws_db_subnet_group" "this" {
  name       = "${var.service_name}-db-sg"
  subnet_ids = ["${var.private_subnets}"]

  tags = {
    Environment = "${terraform.workspace}"
  }
}

# Auroraセキュリティグループ
resource "aws_security_group" "aurora" {
  name   = "${var.service_name}-aurora-sg"
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
    Environment = "${terraform.workspace}"
  }
}

# Auroraパラメータグループ
resource "aws_rds_cluster_parameter_group" "this" {
  name   = "${var.service_name}-rds-cluster-pg"
  family = "aurora-mysql5.7"

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

  # 監査ログ系の設定
  parameter {
    name  = "server_audit_logging"
    value = "1"                    # 監査ログを有効にする
  }

  parameter {
    name  = "server_audit_events"
    value = "connect,query,query_dcl,query_ddl,query_dml,table" #監査する対象のイベント
  }

  parameter {
    name  = "server_audit_logs_upload"
    value = "1"
  }

  parameter {
    name  = "aws_default_logs_role"
    value = "${aws_iam_role.monitoring.arn}"
  }

  parameter {
    name  = "time_zone"
    value = "${var.time_zone}"
  }
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

resource "aws_rds_cluster" "this" {
  cluster_identifier              = "${var.service_name}-aurora-cluster"
  engine                          = "aurora-mysql"
  engine_version                  = "5.7.12"
  database_name                   = "${data.aws_ssm_parameter.database_name.value}"
  master_username                 = "${data.aws_ssm_parameter.master_username.value}"
  master_password                 = "${data.aws_ssm_parameter.master_password.value}"
  backup_retention_period         = 5
  preferred_backup_window         = "07:00-09:00"
  port                            = 3306
  db_subnet_group_name            = "${aws_db_subnet_group.this.name}"
  vpc_security_group_ids          = ["${aws_security_group.aurora.id}"]
  db_cluster_parameter_group_name = "${aws_rds_cluster_parameter_group.this.name}"

  tags = {
    Environment = "${terraform.workspace}"
  }
}

resource "aws_rds_cluster_instance" "this" {
  count                = 2
  identifier           = "${var.service_name}-${count.index}"
  cluster_identifier   = "${aws_rds_cluster.this.id}"
  engine               = "${aws_rds_cluster.this.engine}"
  engine_version       = "${aws_rds_cluster.this.engine_version}"
  instance_class       = "${var.instance_class}"
  db_subnet_group_name = "${aws_db_subnet_group.this.name}"
  monitoring_role_arn  = "${aws_iam_role.monitoring.arn}"
  monitoring_interval  = 60

  tags = {
    Environment = "${terraform.workspace}"
  }
}
