#output "instance_ips" {
#    value = ["${module.cloverdx.instance_ips}"]
#}

#output "check" {
#    #    value = element(module.cloverdx.instance_ids, 1)
#    # count = instance_ids
#    value = module.cloverdx.instance_ids
#}
#output "check-lookup" {
# value = lookup([{"instance_id"=module.cloverdx.instance_ids}], "instance_id", "what")
#  value = "-${element(
#      module.cloverdx.instance_ids,
#      0
#      # count.index / length(vpc_names),
#    )}-rtb"
#}
