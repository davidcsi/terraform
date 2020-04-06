######### Variables ##########

variable "aws_region" {
    type = string
    default = "us-east-1"
}

variable "topic_name" {
    type = string
    default = "Monitoring"  
}

variable "hc_regions" {
    type    = list(string)
    default = [ "eu-west-1", "sa-east-1", "us-east-1" ]
}

variable "email_addresses_1" {
    type        = string
    description = "Email address to send notifications to"
    default = "email1"
}

variable "servers" {
    #type = list(map(string))
    default = {
        "fs-1" = {
            ip_address = "1.2.3.4"
            healthcheck_name = "server-1-failure"
            resource_path = "/alive.html"
            resource_port = "80"
        },
        "fs-2" = {
            ip_address = "4.3.2.1"
            healthcheck_name = "server-2-failure"
            resource_path = "/alive.html"
            resource_port = "80"
        },
        "kam" = {
            ip_address = "9.8.7.6"
            healthcheck_name = "server-3"
            resource_path = "/alive.html"
            resource_port = "80"
        }
    }
}
