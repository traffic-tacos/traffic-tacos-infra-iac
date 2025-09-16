variable "name" {
  type        = string
  description = "리소스 접두사"
  default     = "ticket"
}

variable "tables" {
  type = list(object({
    name             = string
    hash_key         = string
    range_key        = optional(string)
    billing_mode     = optional(string, "PAY_PER_REQUEST")
    read_capacity    = optional(number, 5)
    write_capacity   = optional(number, 5)
    stream_enabled   = optional(bool, false)
    stream_view_type = optional(string, "NEW_AND_OLD_IMAGES")

    attributes = list(object({
      name = string
      type = string
    }))

    global_secondary_indexes = optional(list(object({
      name      = string
      hash_key  = string
      range_key = optional(string)
      projection_type = optional(string, "ALL")
      read_capacity   = optional(number, 5)
      write_capacity  = optional(number, 5)
    })), [])

    local_secondary_indexes = optional(list(object({
      name      = string
      range_key = string
      projection_type = optional(string, "ALL")
    })), [])

    ttl_enabled = optional(bool, false)
    ttl_attribute = optional(string, "ttl")
  }))

  default = [
    {
      name     = "tickets"
      hash_key = "ticket_id"
      attributes = [
        {
          name = "ticket_id"
          type = "S"
        },
        {
          name = "user_id"
          type = "S"
        },
        {
          name = "status"
          type = "S"
        }
      ]
      global_secondary_indexes = [
        {
          name     = "user-index"
          hash_key = "user_id"
        },
        {
          name     = "status-index"
          hash_key = "status"
        }
      ]
    },
    {
      name     = "users"
      hash_key = "user_id"
      attributes = [
        {
          name = "user_id"
          type = "S"
        },
        {
          name = "email"
          type = "S"
        }
      ]
      global_secondary_indexes = [
        {
          name     = "email-index"
          hash_key = "email"
        }
      ]
    },
    # Reservation API Tables
    {
      name     = "reservation-reservations"
      hash_key = "pk"
      range_key = "sk"
      attributes = [
        {
          name = "pk"
          type = "S"
        },
        {
          name = "sk"
          type = "S"
        },
        {
          name = "user_id"
          type = "S"
        },
        {
          name = "status"
          type = "S"
        },
        {
          name = "created_at"
          type = "S"
        }
      ]
      global_secondary_indexes = [
        {
          name     = "user-status-index"
          hash_key = "user_id"
          range_key = "status"
        },
        {
          name     = "status-created-index"
          hash_key = "status"
          range_key = "created_at"
        }
      ]
    },
    {
      name     = "reservation-orders"
      hash_key = "pk"
      range_key = "sk"
      attributes = [
        {
          name = "pk"
          type = "S"
        },
        {
          name = "sk"
          type = "S"
        },
        {
          name = "user_id"
          type = "S"
        },
        {
          name = "event_id"
          type = "S"
        },
        {
          name = "created_at"
          type = "S"
        }
      ]
      global_secondary_indexes = [
        {
          name     = "user-created-index"
          hash_key = "user_id"
          range_key = "created_at"
        },
        {
          name     = "event-created-index"
          hash_key = "event_id"
          range_key = "created_at"
        }
      ]
    },
    {
      name     = "reservation-idempotency"
      hash_key = "pk"
      attributes = [
        {
          name = "pk"
          type = "S"
        }
      ]
      ttl_enabled = true
      ttl_attribute = "ttl"
    },
    {
      name     = "reservation-outbox"
      hash_key = "pk"
      range_key = "sk"
      attributes = [
        {
          name = "pk"
          type = "S"
        },
        {
          name = "sk"
          type = "S"
        },
        {
          name = "status"
          type = "S"
        },
        {
          name = "created_at"
          type = "S"
        }
      ]
      global_secondary_indexes = [
        {
          name     = "status-created_at-index"
          hash_key = "status"
          range_key = "created_at"
        }
      ]
    }
  ]
}

variable "enable_point_in_time_recovery" {
  type        = bool
  description = "Point-in-time recovery 활성화"
  default     = true
}

variable "enable_deletion_protection" {
  type        = bool
  description = "삭제 보호 활성화"
  default     = false
}

variable "server_side_encryption" {
  type        = bool
  description = "서버 측 암호화 활성화"
  default     = true
}

variable "kms_key_id" {
  type        = string
  description = "KMS 키 ID (선택사항)"
  default     = null
}