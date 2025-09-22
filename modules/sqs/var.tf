variable "name" {
  type        = string
  description = "리소스 접두사"
  default     = "traffic-tacos"
}

variable "queue_name" {
  type        = string
  description = "SQS 큐 이름"
  default     = "payment-webhooks"
}

variable "visibility_timeout_seconds" {
  type        = number
  description = "메시지 가시성 타임아웃 (초)"
  default     = 30
}

variable "message_retention_seconds" {
  type        = number
  description = "메시지 보관 시간 (초)"
  default     = 1209600 # 14일
}

variable "max_receive_count" {
  type        = number
  description = "최대 수신 횟수 (DLQ로 이동 전)"
  default     = 3
}

variable "delay_seconds" {
  type        = number
  description = "메시지 전달 지연 시간 (초)"
  default     = 0
}

variable "receive_wait_time_seconds" {
  type        = number
  description = "롱 폴링 대기 시간 (초)"
  default     = 20
}

variable "enable_dlq" {
  type        = bool
  description = "Dead Letter Queue 활성화"
  default     = true
}

variable "dlq_message_retention_seconds" {
  type        = number
  description = "DLQ 메시지 보관 시간 (초)"
  default     = 1209600 # 14일
}

variable "kms_master_key_id" {
  type        = string
  description = "KMS 키 ID (암호화용)"
  default     = "alias/aws/sqs"
}

variable "enable_encryption" {
  type        = bool
  description = "서버 사이드 암호화 활성화"
  default     = true
}

variable "tags" {
  type        = map(string)
  description = "리소스 태그"
  default = {
    Environment = "dev"
    Service     = "payment"
    Component   = "webhook"
  }
}