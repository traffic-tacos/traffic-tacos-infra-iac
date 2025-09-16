resource "aws_cloudwatch_event_bus" "custom_bus" {
  name = "${var.name}-${var.custom_bus_name}"

  tags = {
    Name = "${var.name}-${var.custom_bus_name}"
  }
}

resource "aws_sqs_queue" "dlq" {
  count = var.enable_dlq ? 1 : 0

  name                      = "${var.name}-events-dlq"
  message_retention_seconds = var.dlq_retention_days * 24 * 60 * 60
  max_message_size          = 262144
  delay_seconds             = 0
  receive_wait_time_seconds = 0

  tags = {
    Name = "${var.name}-events-dlq"
  }
}

resource "aws_cloudwatch_event_rule" "rules" {
  for_each = { for rule in var.rules : rule.name => rule }

  name           = "${var.name}-${each.value.name}"
  description    = each.value.description
  event_bus_name = aws_cloudwatch_event_bus.custom_bus.name
  event_pattern  = each.value.event_pattern
  schedule_expression = each.value.schedule_expression
  state          = each.value.state

  tags = {
    Name = "${var.name}-${each.value.name}"
  }
}

resource "aws_cloudwatch_event_target" "targets" {
  for_each = merge([
    for rule_key, rule in var.rules : {
      for target in rule.targets :
      "${rule_key}-${target.id}" => {
        rule_name  = rule.name
        target     = target
        rule_arn   = aws_cloudwatch_event_rule.rules[rule_key].arn
      }
    }
  ]...)

  rule           = aws_cloudwatch_event_rule.rules[each.value.rule_name].name
  event_bus_name = aws_cloudwatch_event_bus.custom_bus.name
  target_id      = each.value.target.id
  arn            = each.value.target.arn
  input          = each.value.target.input
  input_path     = each.value.target.input_path
  role_arn       = each.value.target.role_arn

  dynamic "dead_letter_config" {
    for_each = var.enable_dlq && each.value.target.dead_letter_config == null ? [1] : (each.value.target.dead_letter_config != null ? [each.value.target.dead_letter_config] : [])
    content {
      arn = var.enable_dlq && each.value.target.dead_letter_config == null ? aws_sqs_queue.dlq[0].arn : dead_letter_config.value.arn
    }
  }

  dynamic "retry_policy" {
    for_each = each.value.target.retry_policy != null ? [each.value.target.retry_policy] : []
    content {
      maximum_retry_attempts       = retry_policy.value.maximum_retry_attempts
      maximum_event_age_in_seconds = retry_policy.value.maximum_event_age_in_seconds
    }
  }

  dynamic "sqs_parameters" {
    for_each = each.value.target.sqs_parameters != null ? [each.value.target.sqs_parameters] : []
    content {
      message_group_id = sqs_parameters.value.message_group_id
    }
  }
}

resource "aws_cloudwatch_event_archive" "archive" {
  count = var.archive_config.enabled ? 1 : 0

  name             = "${var.name}-${var.archive_config.archive_name}"
  description      = var.archive_config.description
  event_source_arn = aws_cloudwatch_event_bus.custom_bus.arn
  retention_days   = var.archive_config.retention_days
  event_pattern    = var.archive_config.event_pattern
}

resource "aws_cloudwatch_log_group" "eventbridge_logs" {
  name              = "/aws/events/${var.name}-eventbridge"
  retention_in_days = 30

  tags = {
    Name = "${var.name}-eventbridge-logs"
  }
}

resource "aws_cloudwatch_metric_alarm" "failed_invocations" {
  for_each = { for rule in var.rules : rule.name => rule }

  alarm_name          = "${var.name}-${each.value.name}-failed-invocations"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "FailedInvocations"
  namespace           = "AWS/Events"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "This metric monitors EventBridge rule failed invocations"
  alarm_actions       = []

  dimensions = {
    RuleName = aws_cloudwatch_event_rule.rules[each.key].name
  }

  tags = {
    Name = "${var.name}-${each.value.name}-failed-invocations"
  }
}