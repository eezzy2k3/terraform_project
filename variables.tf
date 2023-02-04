
variable "subnet" {
  type = map(any)
  default = {
    sub-1 = {
      az   = "use1-az1"
      cidr = "10.0.1.0/24"
    }
    sub-2 = {
      az   = "use1-az2"
      cidr = "10.0.2.0/24"
    }

  }
}

variable "sb-name" {
  description = "Prefix used for all resources names"
  default     = "public"
}

variable "instance_name" {
  description = "Name of the instance to be created"
  default     = "webserver"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "subnet_id" {
  description = "The VPC subnet the instance(s) will be created in"
  default     = "subnet-07ebbe60"
}

variable "ami_id" {
  description = "The AMI to use"
  default     = "ami-00874d747dde814fa"
  
}

variable "number_of_instances" {
  description = "number of instances to be created"
  default     = 3
}


variable "ami_key_pair_name" {
  default = "aws"
}