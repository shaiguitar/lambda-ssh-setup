variable "name" {
  description = "name"
  default = "An_ssh_access_lambda"
}

variable "schedule" {
  description = "CW how often"
  default = "rate(1 hour)"
}

# XXX can create in this example/use aws hardened_os
variable "ami" {
  description = "ami of test image to access"
  default = "ami-CHANGEME"
}

# XXX can create in this example
variable "vpc_id" {
  default = "vpc-CHANGEME"
}

# XXX can create in this example
variable "vpc_subnet_id" {
  default = "subnet-CHANGEME"
}

