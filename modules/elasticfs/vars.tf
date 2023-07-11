variable "tags" {
  type    = map(any)
  default = {}
}

variable "subnets" {
  type    = number
  default = 1
}

variable "subnet_id" {
  default = ""
}

variable "efs-sg" {
  default = []
}
