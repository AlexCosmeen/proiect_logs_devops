variable "instance_type" {
  type    = string
  default = "t3.micro"
}
variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "subnet_cidr" {
  type    = string
  default = "10.0.2.0/24"
}

variable "availability_zone" {
  type    = string
  default = "eu-north-1b"
}
variable "ssh_allowed_cidr" {
  description = "CIDR allowed to connect to EC2 through SSH"
  type        = string
}
variable "database_secrets" {
  type = map(string)

  default = {
    db_user     = "log-app/db-user"
    db_password = "log-app/db-password"
    db_name     = "log-app/db-name"
  }
}