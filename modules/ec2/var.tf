variable "name" {
  type        = string
  description = "리소스 접두사"
  default     = "ticket"
}
variable "vpc_id" {
  type = string
}

variable "public_subnet" {
  type = list(string)
}

variable "key_name" {
  type    = string
  default = "ticket-shared"
}