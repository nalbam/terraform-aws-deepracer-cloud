# variable

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "name" {
  type    = string
  default = "dr-cloud"
}

variable "instance_type" {
  type    = string
  default = "g5.8xlarge"
}

variable "market_type" {
  type    = string
  default = "spot"
}

variable "ami_id" {
  type    = string
  default = "ami-0365f1c02d110fa96"
  # ami-0365f1c02d110fa96 - AWS Deep Learning Base AMI (Ubuntu 18.04) Version 49.0 - us-east-1
  # ami-01242c3178ffa1b87 - AWS Deep Learning Base AMI (Ubuntu 18.04) Version 49.0 - us-west-2
}

variable "ebs_optimized" {
  type    = bool
  default = true
}

variable "volume_type" {
  type    = string
  default = "gp3"
}

variable "volume_size" {
  type    = string
  default = "100"
}

variable "iops" {
  type    = string
  default = "3000"
}

variable "throughput" {
  type    = string
  default = "125"
}

variable "delete_on_termination" {
  type    = bool
  default = true
}

variable "associate_public_ip_address" {
  type    = bool
  default = true
}

variable "min" {
  type    = number
  default = 0
}

variable "max" {
  type    = number
  default = 1
}

variable "desired" {
  type    = number
  default = 1
}

# variable "suspended_processes" {
#   type = list(string)
#   default = [
#     # "Launch",
#   ]
# }

variable "ports" {
  type = list(string)
  default = [
    "8100",
    "8888",
    "8080",
    "8081",
    "8082",
    "8083",
    "8084",
    "8085",
  ]
}

variable "allow_ip_address" {
  type = list(string)
  default = [
    "0.0.0.0/0",
    # "39.117.14.79/32", # echo "$(curl -sL icanhazip.com)/32"
  ]
}

variable "key_name" {
  type    = string
  default = "nalbam-seoul"
}

# variable "zone_name" {
#   type    = string
#   default = ""
# }
