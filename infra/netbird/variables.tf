variable "estate_file" {
  description = "Optional Estate inventory path used by isolated validation."
  type        = string
  default     = null
}

variable "state_encryption_passphrase" {
  description = "Passphrase used for native OpenTofu state and plan encryption."
  type        = string
  sensitive   = true
  ephemeral   = true
  nullable    = false

  validation {
    condition     = length(var.state_encryption_passphrase) >= 32
    error_message = "The state-encryption passphrase must contain at least 32 characters."
  }
}
