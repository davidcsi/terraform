# Configure the AWS Provider
provider "aws" {
    alias = "use1"
    version = "~> 2.0"
}

######### SNS Topic and Subscription ##########

resource "aws_sns_topic" "email_notifications" {
    name = var.topic_name

    provisioner "local-exec" {
        command = "AWS_DEFAULT_REGION='${var.aws_region}' aws sns subscribe --topic-arn ${self.arn} --protocol email --notification-endpoint ${var.email_addresses_1}"
    }

    provisioner "local-exec" {
        command = "AWS_DEFAULT_REGION='${var.aws_region}' aws sns subscribe --topic-arn ${self.arn} --protocol email --notification-endpoint ${var.email_addresses_2}"
    }
}

######### Route53 HealthCheck ##########

resource "aws_route53_health_check" "prod_hc" {

    for_each = var.servers

    provider                = aws.use1
    ip_address              = each.value.ip_address
    type                    = "HTTP"
    resource_path           = each.value.resource_path
    port                    = each.value.resource_port
    failure_threshold       = "2"
    request_interval        = "30"
    regions                 = var.hc_regions

    tags = {
        Product	        = "Voice Servers Monitoring"
        Owner           = "mp-devops"
        TagsComponent   = "HeathCheck"
        Env	            = "prod"
        Contact	        = "mp-david"
        Name            = each.value.healthcheck_name
    }
}

######### Cloudwatch Alarm ##########

resource "aws_cloudwatch_metric_alarm" "prod-alarm" {
    for_each = aws_route53_health_check.prod_hc

    alarm_name          = each.value.tags.Name
    comparison_operator = "LessThanThreshold"
    evaluation_periods  = "2"
    metric_name         = "HealthCheckStatus"
    namespace           = "AWS/Route53"
    statistic           = "Maximum"
    threshold           = "1"
    period              = "60"
    alarm_actions       = [ aws_sns_topic.email_notifications.arn ]
    ok_actions          = [ aws_sns_topic.email_notifications.arn ]
    alarm_description   = "Prod Monitoring"

    dimensions          = {
        HealthCheckId = each.value.id
    }
}

