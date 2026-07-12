provider "kubernetes" {
  config_path = var.kubeconfig_path
}

provider "helm" {
  kubernetes {
    config_path = var.kubeconfig_path
  }
}

provider "cloudflare" {
  # Automatically picks up CLOUDFLARE_API_TOKEN from the environment variables
}
