function update-clientarea-db-target-group
	set target_group_arn 'arn:aws:elasticloadbalancing:us-east-2:944942797583:targetgroup/clientarea-dev-db/c3f9dd519f83d899'

	set deregister_input (aws elbv2 describe-target-health --target-group-arn $target_group_arn | jq --compact-output --arg 'target_arn' "$target_group_arn" '{"TargetGroupArn":$target_arn, "Targets":[.TargetHealthDescriptions[].Target]}')
	aws elbv2 deregister-targets --cli-input-json "$deregister_input"

	set new_target (aws --region sa-east-1 ec2 describe-network-interfaces | jq --compact-output --arg 'target_arn' "$target_group_arn" '{"TargetGroupArn": $target_arn, "Targets": [.NetworkInterfaces[] | select(.RequesterId == "amazon-rds" and .Groups[0].GroupName == "RDS-clientarea-dev") | {"Id":.PrivateIpAddress, "Port":5432, "AvailabilityZone":"all"}]}')
	aws elbv2 register-targets --cli-input-json "$new_target"
end
