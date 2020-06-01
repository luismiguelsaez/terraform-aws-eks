
variable "node-group" {
  type    = map
  default = {
    "remote-access" = true
  }
}

variable "vpc" {
  type = map
  default = {
    "subnet-public" = false
  }
}