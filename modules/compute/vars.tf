variable "tags" {
  type    = map(any)
  default = {}
}

variable "subnets" {
  type    = list(string)
  default = []
}

variable "security_group_ids" {
  type    = list(string)
  default = []
}

variable "key_name" {
  type    = string
  default = ""
}

variable "public_ip" {
  type    = bool
  default = false
}

variable "instance_type" {
  type    = string
  default = "t2.small"
}

variable "volume_size" {
  type    = number
  default = 20
}

variable "userdata" {
  type    = string
  default = ""
}