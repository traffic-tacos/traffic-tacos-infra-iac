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

  # Bot Control 규칙
  rule {
    name     = "BotControl"
    priority = 1

    override_action {
      count {}
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

        # 테스트용 User-Agent 제외
        scope_down_statement {
          not_statement {
            statement {
              byte_match_statement {
                search_string = "hey/0.0.1"
                field_to_match {
                  single_header {
                    name = "user-agent"
                  }
                }
                positional_constraint = "EXACTLY"
                text_transformation {
                  priority = 0
                  type     = "NONE"
                }
              }
            }
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

  # CAPTCHA 규칙
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

  # Rate Limit 규칙
  rule {
    name     = "RBR_APIv1_UserAgentIP"
    priority = 5

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit                 = 1000
        evaluation_window_sec = 60
        aggregate_key_type    = "IP" # User-Agent 검사할 경우 "CUSTOM_KEYS"

        # customKeys: (User-Agent, IP)로 버킷을 묶어 집계
        # custom_key {
        #   header {
        #     name = "User-Agent"
        #     text_transformation {
        #       priority = 0
        #       type     = "NONE"
        #     }
        #   }
        # }

        custom_key {
          ip {}
        }

        scope_down_statement {
          byte_match_statement {
            search_string = "/" # 혹은 var.api_path_prefix
            field_to_match {
              uri_path {}
            }
            positional_constraint = "STARTS_WITH"
            text_transformation {
              priority = 0
              type     = "NONE"
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = var.cloudwatch_metrics_enabled
      sampled_requests_enabled   = var.sampled_requests_enabled
      metric_name                = "RBR_APIv1_UserAgentIP"
    }
  }

  #   # API 경로 예외 규칙
  #   rule {
  #     name     = "AllowAPIRequests"
  #     priority = 10

  #     action {
  #       allow {}
  #     }

  #     statement {
  #       byte_match_statement {
  #         search_string = var.api_path_prefix
  #         field_to_match {
  #           uri_path {}
  #         }
  #         text_transformation {
  #           priority = 0
  #           type     = "LOWERCASE"
  #         }
  #         positional_constraint = "STARTS_WITH"
  #       }
  #     }

  #     visibility_config {
  #       cloudwatch_metrics_enabled = var.cloudwatch_metrics_enabled
  #       sampled_requests_enabled   = var.sampled_requests_enabled
  #       metric_name                = "AllowAPIRequests"
  #     }
  #   }
}