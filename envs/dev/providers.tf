terraform {
  required_version = ">= 1.6"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "pnet-state-rg"
    storage_account_name = "pnetstsaran2026"
    container_name       = "tfstate"
    key                  = "policynet-dev.tfstate"
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}
