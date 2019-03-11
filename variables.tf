variable "region" {
  default = "us-east-1"
}

variable "service_name" {
  default = "sample"
}

variable "domain" {
  default = ""
}

# DB
variable "instance_class" {
  default = ""
}

variable "time_zone" {
  default = "Asia/Tokyo"
}

# Rails
variable "rails_env" {
  default = "staging"
}
