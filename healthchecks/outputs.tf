# output "healthcheck_ids" {
#     value = {
#         for hc in aws_route53_health_check.prod-hc :
#         hc_id = hc.id
#     }
# }
