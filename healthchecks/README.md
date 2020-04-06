<a href="http://fvcproductions.com"><img src="https://avatars1.githubusercontent.com/u/4284691?v=3&s=200" title="FVCproductions" alt="FVCproductions"></a>

<!-- [![FVCproductions](https://avatars1.githubusercontent.com/u/4284691?v=3&s=200)](http://fvcproductions.com) -->

# Healthchecks and Alarms #

Common Text

I had so many problems figuring out how to do this with Terraform, when i finally figured it out, I had to make this repo. Specially using maps or lists to create resources.

In this case i had a few servers I needed to monitor with HealthChecks, and trigger alarms if they fail or come back from a failing state.

I had a list of servers like this:

###### Server 1
> ip_address = "1.2.3.4"
healthcheck_name = "server-1-failure"
resource_path = "/Alive.html"
resource_port = "80"

###### Server 2
> ip_address = "4.3.2.1"
healthcheck_name = "server-2-failure"
resource_path = "/Alive.html"
resource_port = "80"

###### Server 3
> ip_address = "9.8.7.6"
healthcheck_name = "server-3-failure"
resource_path = "/alive.html"
resource_port = "80"

---

I could have created them one by one, but that's not very efficient or practical.
I tried creating an arraym but using arrays would simply create a list and if we then changed the servers or the order of the list or removed one, ti would all go to hell...

So, long story short, I create a map of maps in the variables.tf file like so:
```
variable "servers" {
    default = {
        "s-1" = {
            ip_address = "1.2.3.4"
            healthcheck_name = "server-1-failure"
            resource_path = "/alive.html"
            resource_port = "80"
        },
        "s-2" = {
            ip_address = "4.3.2.1"
            healthcheck_name = "server-2-failure"
            resource_path = "/alive.html"
            resource_port = "80"
        },
        "s-3" = {
            ip_address = "9.8.7.6"
            healthcheck_name = "server-3-failure"
            resource_path = "/alive.html"
            resource_port = "80"
        }
    }
}
```
and then link that map to the resource creation like this:

#### Creating the Healthcheck

- Using `for_each` will iterate the map and store on each iteration all elements in the `each` "variable", and the item parameters can be accessed like `each.value.PARAMETER`, i.e. `each.value.ip_address`:

```
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
```
#### Creating the alarm and linking it to the healthcheck.

- Since we used `for_each` on the resource creation `aws_route53_health_check` is now a list of maps, so we again need to use `for_each` like so:

```
resource "aws_cloudwatch_metric_alarm" "alarm" {
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
```

I also struggled a while to figure out the way to link the alarm (in terms of AWS) to the halthcheck, was to set the correct `dimensions`


### And that's it!


---
