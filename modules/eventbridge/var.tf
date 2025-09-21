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

variable "additional_buses" {
  type = list(object({
    name        = string
    description = optional(string, "")
  }))
  description = "추가 이벤트 버스 목록"
  default = [
    {
      name        = "reservation-events"
      description = "Reservation domain events"
    }
  ]
}

variable "rules" {
  type = list(object({
    name                = string
    description         = optional(string)
    event_pattern       = optional(string)
    schedule_expression = optional(string)
    state               = optional(string, "ENABLED")

    targets = list(object({
      id         = string
      arn        = string
      input      = optional(string)
      input_path = optional(string)
      role_arn   = optional(string)

      dead_letter_config = optional(object({
        arn = string
      }))

      retry_policy = optional(object({
        maximum_retry_attempts       = number
        maximum_event_age_in_seconds = number
      }))

      # sqs_parameters not supported in aws_cloudwatch_event_target
    }))
  }))

  default = [
    {
      name          = "ticket-created"
      description   = "티켓 생성 이벤트 처리"
      event_pattern = "{\"source\":[\"ticket.service\"],\"detail-type\":[\"Ticket Created\"],\"detail\":{\"status\":[\"created\"]}}"
      targets = [
        {
          id  = "ticket-created-handler"
          arn = "arn:aws:lambda:ap-northeast-2:137406935518:function:ticket-handler"
        }
      ]
    },
    {
      name          = "ticket-status-changed"
      description   = "티켓 상태 변경 이벤트 처리"
      event_pattern = "{\"source\":[\"ticket.service\"],\"detail-type\":[\"Ticket Status Changed\"],\"detail\":{\"status\":[\"approved\",\"rejected\",\"completed\"]}}"
      targets = [
        {
          id  = "status-change-handler"
          arn = "arn:aws:lambda:ap-northeast-2:137406935518:function:status-handler"
        }
      ]
    },
    # Reservation API Events
    {
      name          = "reservation-created"
      description   = "예약 생성 이벤트 처리"
      event_pattern = "{\"source\":[\"reservation.service\"],\"detail-type\":[\"Reservation Created\"],\"detail\":{\"status\":[\"HOLD\"]}}"
      targets = [
        {
          id  = "reservation-created-handler"
          arn = "arn:aws:lambda:ap-northeast-2:137406935518:function:reservation-handler"
        }
      ]
    },
    {
      name          = "reservation-status-changed"
      description   = "예약 상태 변경 이벤트 처리"
      event_pattern = "{\"source\":[\"reservation.service\"],\"detail-type\":[\"Reservation Status Changed\"],\"detail\":{\"status\":[\"CONFIRMED\",\"CANCELLED\",\"EXPIRED\"]}}"
      targets = [
        {
          id  = "reservation-status-handler"
          arn = "arn:aws:lambda:ap-northeast-2:137406935518:function:reservation-status-handler"
        }
      ]
    },
    {
      name          = "reservation-expiry-scheduler"
      description   = "예약 만료 스케줄러 이벤트"
      event_pattern = "{\"source\":[\"aws.scheduler\"],\"detail-type\":[\"Scheduled Event\"],\"detail\":{\"event_type\":[\"reservation-expiry\"]}}"
      targets = [
        {
          id  = "reservation-expiry-handler"
          arn = "arn:aws:lambda:ap-northeast-2:137406935518:function:reservation-expiry-handler"
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

    event_pattern = optional(string, "{\"source\":[\"ticket.service\",\"reservation.service\",\"aws.scheduler\"]}")
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