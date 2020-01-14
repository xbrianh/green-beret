all: apply

init:
	$(MAKE) -C $(GREEN_BERET_HOME)/terraform init-all

plan: init
	$(MAKE) -C $(GREEN_BERET_HOME)/terraform plan-all

apply: init
	$(MAKE) -C $(GREEN_BERET_HOME)/terraform apply-all

destroy: init
	$(MAKE) -C $(GREEN_BERET_HOME)/terraform destroy-all

aws:
	$(MAKE) -C $(GREEN_BERET_HOME)/terraform apply COMPONENT=aws

# Server configuration occasionally fails after instance creation (some services not available yet?)
# This pattern forces re-configuration.
configure-aws:
	(cd $(GREEN_BERET_HOME)/terraform/aws && terraform taint null_resource.instance_config)
	(cd $(GREEN_BERET_HOME)/terraform/aws && terraform apply -auto-approve -target null_resource.instance_config)

destroy-aws:
	$(MAKE) -C $(GREEN_BERET_HOME)/terraform destroy COMPONENT=aws

clean:
	$(MAKE) -C $(GREEN_BERET_HOME)/terraform clean-all

.PHONY: all init plan apply destroy aws destroy-aws clean
