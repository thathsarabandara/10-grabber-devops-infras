provider "kubernetes" {
  config_path = var.kubeconfig_path
}

provider "helm" {
  kubernetes {
    config_path = var.kubeconfig_path
  }
}

provider "cloudflare" {
  # Picks up CLOUDFLARE_API_TOKEN from the environment
}
