variable "region" {
  default = "us-east-1"
}

variable "cluster_name" {
  type = string
}

variable "cluster_version" {
  default = "1.31"
}

variable "instance_type" {
  default = "t3.medium"
}
