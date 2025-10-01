variable "region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "key_pair_name" {
  description = "Existing EC2 key pair name"
  type        = string
}
