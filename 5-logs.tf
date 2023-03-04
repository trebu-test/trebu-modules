resource "aws_cloudwatch_log_group" "trebu-log-group" {
  name              = "/ecs/trebu-game-ban"
  retention_in_days = var.log_retention_in_days
}

resource "aws_cloudwatch_log_stream" "trebu-log-stream" {
  name           = "trebu-app-log-stream"
  log_group_name = aws_cloudwatch_log_group.trebu-log-group.name
}