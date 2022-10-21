# Instance type
variable "instance_type" {
  default = {
    "prod"    = "t3.medium"
    "test"    = "t3.micro"
    "staging" = "t2.micro"
    "dev"     = "t3.medium"
  }
  description = "instance type"
  type        = map(string)
}

# Variable to signal the current environment 
variable "env" {
  default     = "dev"
  type        = string
  description = "Deployment Environment"
}

variable "ecr_repo" {
  default     = ["web", "datab"]
  type        = set(string)
  description = "Amazon ECR Repo Names"
}

variable "sg_ports" {
  default     = ["22","80","8081","8082", "8083"]
  type        = list(string)
  description = "Ports that should be open on the host machine"
}


