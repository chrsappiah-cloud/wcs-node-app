data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  name_prefix = "${var.project_name}-${var.environment}"
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Layer       = "middleware-backend"
  }

  provided_db_secret_arn   = trimspace(var.db_password_secret_arn)
  provided_smtp_secret_arn = trimspace(var.smtp_password_secret_arn)

  create_db_secret = local.provided_db_secret_arn == ""
  create_smtp_secret = (
    local.provided_smtp_secret_arn == "" &&
    var.smtp_pass != null &&
    trimspace(var.smtp_pass) != ""
  )

  db_password_secret_arn   = local.create_db_secret ? aws_secretsmanager_secret.db_password[0].arn : local.provided_db_secret_arn
  smtp_password_secret_arn = local.create_smtp_secret ? aws_secretsmanager_secret.smtp_password[0].arn : local.provided_smtp_secret_arn

  ecs_secret_arns = compact([
    local.db_password_secret_arn,
    local.smtp_password_secret_arn
  ])

  ecs_container_secrets = concat(
    [
      {
        name      = "DATABASE_PASSWORD",
        valueFrom = local.db_password_secret_arn
      }
    ],
    local.smtp_password_secret_arn != "" ? [
      {
        name      = "SMTP_PASS",
        valueFrom = local.smtp_password_secret_arn
      }
    ] : []
  )
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-vpc"
  })
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-igw"
  })
}

resource "aws_subnet" "public" {
  for_each = {
    for idx, cidr in var.public_subnet_cidrs : idx => cidr
  }

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[tonumber(each.key)]

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-public-${each.key}"
    Tier = "public"
  })
}

resource "aws_subnet" "private" {
  for_each = {
    for idx, cidr in var.private_subnet_cidrs : idx => cidr
  }

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value
  map_public_ip_on_launch = false
  availability_zone       = data.aws_availability_zones.available.names[tonumber(each.key)]

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-private-${each.key}"
    Tier = "private"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-public-rt"
  })
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "alb" {
  name        = "${local.name_prefix}-alb-sg"
  description = "Ingress for backend ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

resource "aws_security_group" "ecs" {
  name        = "${local.name_prefix}-ecs-sg"
  description = "Backend ECS tasks"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = var.api_container_port
    to_port         = var.api_container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

resource "aws_security_group" "rds" {
  name        = "${local.name_prefix}-rds-sg"
  description = "PostgreSQL access from ECS tasks"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

resource "aws_security_group" "elasticache" {
  name        = "${local.name_prefix}-redis-sg"
  description = "Redis access from ECS tasks"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

resource "aws_db_subnet_group" "main" {
  name       = "${local.name_prefix}-db-subnet"
  subnet_ids = [for s in aws_subnet.private : s.id]

  tags = local.common_tags
}

resource "aws_db_instance" "postgres" {
  identifier              = "${local.name_prefix}-postgres"
  engine                  = "postgres"
  engine_version          = "16.3"
  instance_class          = "db.t4g.micro"
  allocated_storage       = var.db_allocated_storage
  db_name                 = var.db_name
  username                = var.db_username
  password                = var.db_password
  port                    = 5432
  db_subnet_group_name    = aws_db_subnet_group.main.name
  vpc_security_group_ids  = [aws_security_group.rds.id]
  backup_retention_period = 7
  skip_final_snapshot     = true
  publicly_accessible     = false
  storage_encrypted       = true

  tags = local.common_tags
}

resource "aws_elasticache_subnet_group" "main" {
  name       = "${local.name_prefix}-cache-subnet"
  subnet_ids = [for s in aws_subnet.private : s.id]
}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id       = replace("${local.name_prefix}-redis", "_", "-")
  description                = "Redis middleware cache and queue backbone"
  node_type                  = var.redis_node_type
  port                       = 6379
  parameter_group_name       = "default.redis7"
  subnet_group_name          = aws_elasticache_subnet_group.main.name
  security_group_ids         = [aws_security_group.elasticache.id]
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  automatic_failover_enabled = false
  num_cache_clusters         = 1

  tags = local.common_tags
}

resource "aws_s3_bucket" "middleware_artifacts" {
  bucket = "${local.name_prefix}-middleware-artifacts"

  tags = local.common_tags
}

resource "aws_s3_bucket_public_access_block" "middleware_artifacts" {
  bucket                  = aws_s3_bucket.middleware_artifacts.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_sqs_queue" "middleware_dlq" {
  name                      = "${local.name_prefix}-middleware-dlq"
  message_retention_seconds = 1209600

  tags = local.common_tags
}

resource "aws_sqs_queue" "middleware" {
  name                       = "${local.name_prefix}-middleware"
  visibility_timeout_seconds = 60
  message_retention_seconds  = 345600

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.middleware_dlq.arn
    maxReceiveCount     = 5
  })

  tags = local.common_tags
}

resource "aws_sns_topic" "notifications" {
  name = "${local.name_prefix}-notifications"

  tags = local.common_tags
}

resource "aws_cloudwatch_log_group" "api" {
  name              = "/ecs/${local.name_prefix}-api"
  retention_in_days = 14

  tags = local.common_tags
}

resource "aws_secretsmanager_secret" "db_password" {
  count       = local.create_db_secret ? 1 : 0
  name        = "${local.name_prefix}/database/password"
  description = "Database password for DreamFlow backend"

  tags = local.common_tags
}

resource "aws_secretsmanager_secret_version" "db_password" {
  count         = local.create_db_secret ? 1 : 0
  secret_id     = aws_secretsmanager_secret.db_password[0].id
  secret_string = var.db_password
}

resource "aws_secretsmanager_secret" "smtp_password" {
  count       = local.create_smtp_secret ? 1 : 0
  name        = "${local.name_prefix}/smtp/password"
  description = "SMTP password for DreamFlow backend"

  tags = local.common_tags
}

resource "aws_secretsmanager_secret_version" "smtp_password" {
  count         = local.create_smtp_secret ? 1 : 0
  secret_id     = aws_secretsmanager_secret.smtp_password[0].id
  secret_string = var.smtp_pass
}

resource "aws_iam_role" "ecs_task_execution" {
  name = "${local.name_prefix}-ecs-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task" {
  name = "${local.name_prefix}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "ecs_task_middleware" {
  name = "${local.name_prefix}-ecs-middleware-policy"
  role = aws_iam_role.ecs_task.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = concat([
      {
        Effect = "Allow",
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ],
        Resource = [
          aws_sqs_queue.middleware.arn,
          aws_sqs_queue.middleware_dlq.arn
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "sns:Publish"
        ],
        Resource = [aws_sns_topic.notifications.arn]
      },
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ],
        Resource = [
          aws_s3_bucket.middleware_artifacts.arn,
          "${aws_s3_bucket.middleware_artifacts.arn}/*"
        ]
      }
      ], length(local.ecs_secret_arns) > 0 ? [
      {
        Effect = "Allow",
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ],
        Resource = local.ecs_secret_arns
      }
    ] : [])
  })
}

resource "aws_lb" "api" {
  name               = substr("${local.name_prefix}-api-alb", 0, 32)
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.alb.id]
  subnets            = [for s in aws_subnet.public : s.id]

  tags = local.common_tags
}

resource "aws_lb_target_group" "api" {
  name        = substr("${local.name_prefix}-api-tg", 0, 32)
  port        = var.api_container_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
    path                = "/health"
    matcher             = "200-399"
  }

  tags = local.common_tags
}

resource "aws_lb_listener" "api" {
  load_balancer_arn = aws_lb.api.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }
}

resource "aws_ecs_cluster" "main" {
  name = "${local.name_prefix}-cluster"

  tags = local.common_tags
}

resource "aws_ecs_task_definition" "api" {
  family                   = "${local.name_prefix}-api"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = tostring(var.api_task_cpu)
  memory                   = tostring(var.api_task_memory)
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name      = "api",
      image     = var.api_container_image,
      essential = true,
      portMappings = [
        {
          containerPort = var.api_container_port,
          hostPort      = var.api_container_port,
          protocol      = "tcp"
        }
      ],
      environment = [
        {
          name  = "NODE_ENV",
          value = "production"
        },
        {
          name  = "PORT",
          value = tostring(var.api_container_port)
        },
        {
          name  = "DATABASE_HOST",
          value = aws_db_instance.postgres.address
        },
        {
          name  = "DATABASE_PORT",
          value = "5432"
        },
        {
          name  = "DATABASE_NAME",
          value = var.db_name
        },
        {
          name  = "DATABASE_USER",
          value = var.db_username
        },
        {
          name  = "REDIS_HOST",
          value = aws_elasticache_replication_group.redis.primary_endpoint_address
        },
        {
          name  = "REDIS_PORT",
          value = "6379"
        },
        {
          name  = "AWS_REGION",
          value = var.aws_region
        },
        {
          name  = "AWS_SQS_MIDDLEWARE_QUEUE_URL",
          value = aws_sqs_queue.middleware.id
        },
        {
          name  = "AWS_SNS_NOTIFICATIONS_TOPIC_ARN",
          value = aws_sns_topic.notifications.arn
        },
        {
          name  = "AWS_S3_MIDDLEWARE_BUCKET",
          value = aws_s3_bucket.middleware_artifacts.id
        },
        {
          name  = "SMTP_HOST",
          value = var.smtp_host
        },
        {
          name  = "SMTP_PORT",
          value = tostring(var.smtp_port)
        },
        {
          name  = "SMTP_SECURE",
          value = tostring(var.smtp_secure)
        },
        {
          name  = "SMTP_USER",
          value = var.smtp_user
        }
      ],
      secrets = local.ecs_container_secrets,
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = aws_cloudwatch_log_group.api.name,
          awslogs-region        = var.aws_region,
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  tags = local.common_tags
}

resource "aws_ecs_service" "api" {
  name            = "${local.name_prefix}-api"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.api.arn
  desired_count   = var.api_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    assign_public_ip = false
    subnets          = [for s in aws_subnet.private : s.id]
    security_groups  = [aws_security_group.ecs.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.api.arn
    container_name   = "api"
    container_port   = var.api_container_port
  }

  depends_on = [aws_lb_listener.api]

  tags = local.common_tags
}
