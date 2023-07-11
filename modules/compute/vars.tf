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

variable "instance_type" {
  type    = string
  default = ""
}

variable "key_name" {
  type    = string
  default = ""
}

variable "instance_count" {
  type    = number
  default = 1
}

variable "security_group_ids" {
  default = []
}
