resource "aws_wafv2_web_acl" "cf_web_acl" {
  name        = var.waf_name
  provider    = aws.us_east_1
  scope       = "CLOUDFRONT"
  description = var.waf_description

  # 규칙 공통 속성
  visibility_config {
    cloudwatch_metrics_enabled = var.cloudwatch_metrics_enabled
    sampled_requests_enabled   = var.sampled_requests_enabled # 웹 요청 샘플을 저장할지 여부
    metric_name                = var.waf_name
  }

  default_action {
    allow {}
  }

  # API 경로 예외 규칙 (우선순위 0)
  rule {
    name     = "AllowAPIRequests"
    priority = 0

    action {
      allow {}
    }

    statement {
      byte_match_statement {
        search_string = var.api_path_prefix
        field_to_match {
          uri_path {}
        }
        text_transformation {
          priority = 0
          type     = "LOWERCASE"
        }
        positional_constraint = "STARTS_WITH"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = var.cloudwatch_metrics_enabled
      sampled_requests_enabled   = var.sampled_requests_enabled
      metric_name                = "AllowAPIRequests"
    }
  }

  # Bot Control 규칙 (우선순위 1)
  rule {
    name     = "BotControl"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesBotControlRuleSet"

        managed_rule_group_configs {
          aws_managed_rules_bot_control_rule_set {
            inspection_level = var.bot_control_inspection_level
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = var.cloudwatch_metrics_enabled
      sampled_requests_enabled   = var.sampled_requests_enabled
      metric_name                = "BotControl"
    }
  }

  # CAPTCHA 규칙 (우선순위 2)
  rule {
    name     = "CaptchaIfBot"
    priority = 2

    action {
      captcha {}
    }

    statement {
      or_statement {
        statement {
          label_match_statement {
            scope = "LABEL"
            key   = "awswaf:managed:aws:bot-control:signal:non_browser_user_agent"
          }
        }
        statement {
          label_match_statement {
            scope = "LABEL"
            key   = "awswaf:managed:aws:bot-control:category:http_library"
          }
        }
        statement {
          label_match_statement {
            scope = "LABEL"
            key   = "awswaf:managed:aws:bot-control:bot:known"
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = var.cloudwatch_metrics_enabled
      sampled_requests_enabled   = var.sampled_requests_enabled
      metric_name                = "CaptchaIfBot"
    }
  }
}