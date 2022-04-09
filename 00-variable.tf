# variable

variable "region" {
  type    = string
  default = "us-west-2"
}

variable "name" {
  type    = string
  default = "dr-local"
}

variable "instance_type" {
  type    = string
  default = "g4dn.8xlarge"
}

variable "ami_id" {
  type    = string
  default = ""
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

variable "suspended_processes" {
  type = list(string)
  default = [
    # "Launch",
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

variable "zone_name" {
  type    = string
  default = "nalbam.com"
}
