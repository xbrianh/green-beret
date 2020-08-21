SHELL=/bin/bash

ifndef GREEN_BERET_HOME
$(error Please run "source environment" in the green-beret repo root directory before running make commands)
endif

ifeq ($(shell which jq),)
$(error Please install jq using "apt-get install jq" or "brew install jq")
endif

ifeq ($(findstring Python 3.8, $(shell python --version 2>&1)),)
$(error Please run make commands from a Python 3.8 virtualenv)
endif

ifeq ($(findstring terraform, $(shell which terraform 2>&1)),)
else ifeq ($(findstring Terraform v0.13.0, $(shell terraform --version 2>&1)),)
$(error You must use Terraform v0.13.0, please check your terraform version.)
endif
