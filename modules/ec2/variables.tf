variable "name" {
  type = string
}

variable "ami_override" {
  type    = string
  default = null
}

variable "instance_type_override" {
  type    = string
  default = null
}

variable "key_name" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "ssh_allowed_cidrs" {
  type = list(string)
}

variable "allocate_eip_override" {
  type    = bool
  default = null
}

variable "user_data" {
  type = string
}

variable "policy_arn" {
  type = string
}
