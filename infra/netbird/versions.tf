terraform {
  required_version = ">= 1.11.0, < 2.0.0"

  required_providers {
    netbird = {
      source  = "netbirdio/netbird"
      version = "= 0.0.10"
    }
  }

  backend "local" {}

  encryption {
    key_provider "pbkdf2" "network" {
      passphrase = var.state_encryption_passphrase
    }

    method "aes_gcm" "network" {
      keys = key_provider.pbkdf2.network
    }

    state {
      method   = method.aes_gcm.network
      enforced = true
    }

    plan {
      method   = method.aes_gcm.network
      enforced = true
    }
  }
}
