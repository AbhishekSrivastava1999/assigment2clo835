# Default tags
output "default_tags" {
  value = {
    "Owner" = "Abhishek"
    "App"   = "Docker_ECR"
    "Project" = "CLO835_assi02"
  }
}

# Prefix to identify resources
output "prefix" {
  value     = "ass02"
}