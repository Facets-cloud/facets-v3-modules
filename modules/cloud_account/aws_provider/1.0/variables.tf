variable "instance" {
  type = any
}

variable "instance_name" {
  type    = string
  default = "default"
}

variable "environment" {
  type = any
  default = {
    unique_name = "default"
    namespace   = "default"
    cloud_tags  = {}
  }
}

variable "inputs" {
  type    = any
  default = {}
}
