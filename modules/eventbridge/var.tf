variable "name" {
  type        = string
  description = "리소스 접두사"
  default     = "ticket"
}

variable "custom_bus_name" {
  type        = string
  description = "커스텀 이벤트 버스 이름"
  default     = "ticket-events"
}

variable "rules" {
  type = list(object({
    name                = string
    description         = optional(string)
    event_pattern       = optional(string)
    schedule_expression = optional(string)
    state               = optional(string, "ENABLED")

    targets = list(object({
      id            = string
      arn           = string
      input         = optional(string)
      input_path    = optional(string)
      role_arn      = optional(string)

      dead_letter_config = optional(object({
        arn = string
      }))

      retry_policy = optional(object({
        maximum_retry_attempts = number
        maximum_event_age_in_seconds = number
      }))

      sqs_parameters = optional(object({
        message_group_id = string
      }))
    }))
  }))

  default = [
    {
      name        = "ticket-created"
      description = "티켓 생성 이벤트 처리"
      event_pattern = jsonencode({
        source      = ["ticket.service"]
        detail-type = ["Ticket Created"]
        detail = {
          status = ["created"]
        }
      })
      targets = [
        {
          id  = "ticket-created-handler"
          arn = "arn:aws:lambda:ap-northeast-2:137406935518:function:ticket-handler"
        }
      ]
    },
    {
      name        = "ticket-status-changed"
      description = "티켓 상태 변경 이벤트 처리"
      event_pattern = jsonencode({
        source      = ["ticket.service"]
        detail-type = ["Ticket Status Changed"]
        detail = {
          status = ["approved", "rejected", "completed"]
        }
      })
      targets = [
        {
          id  = "status-change-handler"
          arn = "arn:aws:lambda:ap-northeast-2:137406935518:function:status-handler"
        }
      ]
    }
  ]
}

variable "enable_dlq" {
  type        = bool
  description = "Dead Letter Queue 활성화"
  default     = true
}

variable "dlq_retention_days" {
  type        = number
  description = "DLQ 메시지 보관 기간 (일)"
  default     = 14
}

variable "archive_config" {
  type = object({
    enabled        = bool
    archive_name   = optional(string, "ticket-events-archive")
    description    = optional(string, "Event archive for ticket events")
    retention_days = optional(number, 365)

    event_pattern = optional(string, jsonencode({
      source = ["ticket.service"]
    }))
  })

  default = {
    enabled = true
  }
}

variable "dynamodb_table_arns" {
  type        = list(string)
  description = "DynamoDB 테이블 ARN 목록 (EventBridge에서 접근할 테이블)"
  default     = []
}