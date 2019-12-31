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

destroy-aws:
	$(MAKE) -C $(GREEN_BERET_HOME)/terraform destroy COMPONENT=aws

clean:
	$(MAKE) -C $(GREEN_BERET_HOME)/terraform clean-all

.PHONY: all init plan apply destroy aws destroy-aws clean
