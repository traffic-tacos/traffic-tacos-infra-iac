variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "traffic-tacos"
}

variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default     = {}
}