# PledgeProof Terraform Automation

SG_NAME := pledgeproof-alb-sg

.PHONY: update-ip

# Look up the ALB security group by name, find the existing 443 ingress rule, and update it with your current public IP
update-ip:
	@echo "Fetching current public IP..."
	$(eval MY_IP := $(shell curl -s ifconfig.me))
	@echo "Current IP: $(MY_IP)"
	@echo "Looking up security group '$(SG_NAME)'..."
	$(eval SG_ID := $(shell aws ec2 describe-security-groups \
		--filters Name=group-name,Values=$(SG_NAME) \
		--query "SecurityGroups[0].GroupId" --output text))
	@echo "Found SG: $(SG_ID)"
	@echo "Finding existing HTTPS (443) ingress rule..."
	$(eval RULE_ID := $(shell aws ec2 describe-security-group-rules \
		--filters Name=group-id,Values=$(SG_ID) \
		--query "SecurityGroupRules[?!IsEgress && FromPort==\`443\` && ToPort==\`443\`].SecurityGroupRuleId" \
		--output text))
	@echo "Updating rule $(RULE_ID) to $(MY_IP)/32..."
	@aws ec2 modify-security-group-rules \
		--group-id $(SG_ID) \
		--security-group-rules "SecurityGroupRuleId=$(RULE_ID),SecurityGroupRule={IpProtocol=tcp,FromPort=443,ToPort=443,CidrIpv4=$(MY_IP)/32,Description=Allow HTTPS from my IP}"
	@echo "Done. HTTPS ingress on $(SG_NAME) now allows $(MY_IP)"
