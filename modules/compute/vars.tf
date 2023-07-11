variable "tags" {
  type    = map(any)
  default = {}
}

variable "azs" {
  default = ""
}

variable "subnets" {
  default = ""
}

variable "instances" {
  type = map(object({
  }))
  default = {
    "name" = {
    }
  }
}

variable "instance_name" {
  type    = string
  default = ""
}

variable "volume_size" {
  type    = number
  default = 20
}

variable "volume_type" {
  type    = string
  default = "gp3"
}

variable "instance_type" {
  type    = string
  default = ""
}

variable "instance_count" {
  type    = number
  default = 1
}
