resource "aws_dynamodb_table" "table" {
  for_each = { for table in var.tables : table.name => table }

  name           = "${var.name}-${each.value.name}"
  billing_mode   = each.value.billing_mode
  hash_key       = each.value.hash_key
  range_key      = each.value.range_key
  read_capacity  = each.value.billing_mode == "PROVISIONED" ? each.value.read_capacity : null
  write_capacity = each.value.billing_mode == "PROVISIONED" ? each.value.write_capacity : null

  stream_enabled   = each.value.stream_enabled
  stream_view_type = each.value.stream_enabled ? each.value.stream_view_type : null

  deletion_protection_enabled = var.enable_deletion_protection

  dynamic "attribute" {
    for_each = each.value.attributes
    content {
      name = attribute.value.name
      type = attribute.value.type
    }
  }

  dynamic "global_secondary_index" {
    for_each = each.value.global_secondary_indexes
    content {
      name            = global_secondary_index.value.name
      hash_key        = global_secondary_index.value.hash_key
      range_key       = global_secondary_index.value.range_key
      projection_type = global_secondary_index.value.projection_type
      read_capacity   = each.value.billing_mode == "PROVISIONED" ? global_secondary_index.value.read_capacity : null
      write_capacity  = each.value.billing_mode == "PROVISIONED" ? global_secondary_index.value.write_capacity : null
    }
  }

  dynamic "local_secondary_index" {
    for_each = each.value.local_secondary_indexes
    content {
      name            = local_secondary_index.value.name
      range_key       = local_secondary_index.value.range_key
      projection_type = local_secondary_index.value.projection_type
    }
  }

  server_side_encryption {
    enabled = var.server_side_encryption
  }

  point_in_time_recovery {
    enabled = var.enable_point_in_time_recovery
  }

  dynamic "ttl" {
    for_each = each.value.ttl_enabled ? [1] : []
    content {
      enabled        = true
      attribute_name = each.value.ttl_attribute
    }
  }

  tags = {
    Name = "${var.name}-${each.value.name}"
  }
}

resource "aws_cloudwatch_metric_alarm" "dynamodb_read_throttle" {
  for_each = { for table in var.tables : table.name => table }

  alarm_name          = "${var.name}-${each.value.name}-read-throttle"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ReadThrottledEvents"
  namespace           = "AWS/DynamoDB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "This metric monitors dynamodb read throttle"
  alarm_actions       = []

  dimensions = {
    TableName = aws_dynamodb_table.table[each.key].name
  }

  tags = {
    Name = "${var.name}-${each.value.name}-read-throttle"
  }
}

resource "aws_cloudwatch_metric_alarm" "dynamodb_write_throttle" {
  for_each = { for table in var.tables : table.name => table }

  alarm_name          = "${var.name}-${each.value.name}-write-throttle"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "WriteThrottledEvents"
  namespace           = "AWS/DynamoDB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "This metric monitors dynamodb write throttle"
  alarm_actions       = []

  dimensions = {
    TableName = aws_dynamodb_table.table[each.key].name
  }

  tags = {
    Name = "${var.name}-${each.value.name}-write-throttle"
  }
}