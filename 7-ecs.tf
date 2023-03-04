resource "aws_ecs_cluster" "production" {
  name = "${var.ecs_cluster_name}-cluster"
}

resource "aws_launch_configuration" "ecs" {
  name                        = "${var.ecs_cluster_name}-cluster"
  image_id                    = var.amis
  instance_type               = var.instance_type
  security_groups             = [aws_security_group.ecs.id]
  iam_instance_profile        = aws_iam_instance_profile.ecs.name
  key_name                    = aws_key_pair.production.key_name
  associate_public_ip_address = true
  user_data                   = "#!/bin/bash\necho ECS_CLUSTER='${var.ecs_cluster_name}-cluster' > /etc/ecs/ecs.config"
}

resource "aws_ecs_service" "production" {
  name            = "${var.ecs_cluster_name}-service"
  cluster         = aws_ecs_cluster.production.id
  task_definition = aws_ecs_task_definition.app.arn
  iam_role        = aws_iam_role.ecs-service-role.arn
  desired_count   = var.app_count
  depends_on      = [aws_alb_listener.ecs-alb-http-listener, aws_iam_role_policy.ecs-service-role-policy]

  load_balancer {
    target_group_arn = aws_alb_target_group.default-target-group.arn
    container_name   = "trebu-game-ban"
    container_port   = 8000
  }
}

resource "aws_ecs_task_definition" "app" {
  family                = "trebu-game-ban"
  container_definitions = jsonencode([
    {
      name      = "trebu-game-ban"
      image     = "${var.docker_image_trebu}"
      cpu       = 10
      memory    = 512
      essential = true
      portMappings = [
        {
        containerPort: 8000,
        hostPort: 0,
        protocol: "tcp"
      },
      {
        containerPort: 8007,
        hostPort: 0,
        protocol: "tcp"
      }
      ]
      command: ["docker", "run", "-p", "8007:8000", "--name", "trebu-game-ban-image", "trebu-game-ban-image"]
      environment: []
      logConfiguration: {
        logDriver: "awslogs"
        options: {
          awslogs-group: "/ecs/trebu-game-ban"
          awslogs-region: "${var.region}"
          awslogs-stream-prefix: "trebu-app-log-stream"
        }
      }
    }
  ])
}