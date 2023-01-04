variable "org" {
  type        = string
  description = "The GitHub organization where the repository lives"
}

variable "repo" {
  type        = string
  description = "The name of the repository inside the organization"
}

variable "user_name" {
  type        = string
  default     = null
  description = "Custom name for the IAM user. If omitted a default username is generated"
}

variable "env_prefix" {
  type        = string
  default     = null
  description = "Prefix the environment variables in GitHub Actions should have"
}
