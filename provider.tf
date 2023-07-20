provider "azurerm" {
   features {}
}

terraform {
  required_providers {
    azuredevops = {
      source = "microsoft/azuredevops"
      version = ">=0.1.0"
    }
  }
}

provider "azuredevops" {
  # version = ">= 0.5.0"
  # Remember to specify the org service url and personal access token details below
  org_service_url       = local.org_service_url
  personal_access_token = local.git_pat
}