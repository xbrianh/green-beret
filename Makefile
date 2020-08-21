include common.mk

all: apply

init:
	$(MAKE) -C $(GREEN_BERET_HOME)/terraform init COMPONENT=$(GREEN_BERET_PLATFORM)

plan: init
	$(MAKE) -C $(GREEN_BERET_HOME)/terraform plan COMPONENT=$(GREEN_BERET_PLATFORM)

apply:
	$(MAKE) -C $(GREEN_BERET_HOME)/terraform apply COMPONENT=$(GREEN_BERET_PLATFORM)

destroy:
	$(MAKE) -C $(GREEN_BERET_HOME)/terraform destroy COMPONENT=$(GREEN_BERET_PLATFORM)

# Server configuration occasionally fails after instance creation (some services not available yet?)
# This pattern forces reconfiguration.
reconfigure:
	(cd $(GREEN_BERET_HOME)/terraform/$(GREEN_BERET_PLATFORM) && terraform state rm null_resource.instance_config)
	(cd $(GREEN_BERET_HOME)/terraform/$(GREEN_BERET_PLATFORM) && terraform apply -auto-approve -target null_resource.instance_config)

clean:
	$(MAKE) -C $(GREEN_BERET_HOME)/terraform clean-all

.PHONY: all init plan apply destroy aws destroy-aws clean
