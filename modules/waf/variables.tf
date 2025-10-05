variable "project_name" {
  description = "Project name for tagging and naming resources"
  type        = string
  default     = "ticket"
}

variable "waf_name" {
  description = "Name of the WAF Web ACL"
  type        = string
  default     = "ticket-waf"
}

variable "waf_description" {
  description = "Description of the WAF Web ACL"
  type        = string
  default     = "Apply CAPTCHA only to bot traffics"
}

variable "api_path_prefix" {
  description = "API path prefix to exclude from bot control (e.g., '/api/v1')"
  type        = string
  default     = "/api/v1"
}

variable "bot_control_inspection_level" {
  description = "Inspection level for Bot Control rule set"
  type        = string
  default     = "COMMON"
  validation {
    condition     = contains(["COMMON", "TARGETED"], var.bot_control_inspection_level)
    error_message = "Bot control inspection level must be either 'COMMON' or 'TARGETED'."
  }
}

variable "captcha_labels" {
  description = "List of bot control labels that should trigger CAPTCHA"
  type        = list(string)
  default = [
    "awswaf:managed:aws:bot-control:signal:non_browser_user_agent",
    "awswaf:managed:aws:bot-control:category:http_library",
    "awswaf:managed:aws:bot-control:bot:known"
  ]
}

variable "cloudwatch_metrics_enabled" {
  description = "Enable CloudWatch metrics for WAF"
  type        = bool
  default     = true
}

variable "sampled_requests_enabled" {
  description = "Enable sampled requests logging"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags for WAF resources"
  type        = map(string)
  default     = {}
}
