variable "run_authentication_check" {
  description = "Read account settings to verify provider authentication without changing remote state."
  type        = bool
  default     = false
}

data "netbird_account_settings" "authentication" {
  count = var.run_authentication_check ? 1 : 0
}
