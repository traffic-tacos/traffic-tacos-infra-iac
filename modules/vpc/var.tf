variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR"
  default     = "10.180.0.0/20"
}

variable "name" {
    type = string
    description = "리소스 접두사"
    default = "ticket"
}

variable "tags" {
  type        = map(string)
  description = "공통 태그"
  default     = {}
}

variable "azs" {
  type    = list(string)
  default = ["ap-northeast-2a", "ap-northeast-2c"]
}

variable "public_cidrs" {
  type    = list(string)
  default = ["10.180.0.0/26", "10.180.0.64/26"]
}

variable "private_app_cidrs" {
  type    = list(string)
  default = ["10.180.1.0/25", "10.180.1.128/25"] 
}

variable "private_db_cidrs" {
  type    = list(string)
  default = ["10.180.2.0/26", "10.180.2.64/26"] 
}