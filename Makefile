.DEFAULT_GOAL := help
SHELL = /bin/bash
ENVIRONMENT ?=

include .env.$(PROJECT_NAMESPACE)
export

PLAYBOOK_ROOT = $(PWD)


################################################
#  Help definitions
################################################
define CREATE_ROLE_HELP
Usage:
  >> ROLE_NAME=nginx make create-role
  (See more at https://galaxy.ansible.com/docs/finding/content_types.html#ansible-roles)
endef


define INSTALL_ROLE_HELP
Usage:
  >> ROLE_NAME=geerlingguy.java make install-role
  (Find more modules at https://galaxy.ansible.com/search?deprecated=false&keywords=&order_by=-relevance)
endef


define RUN_PLAYBOOK_HELP
Please enter the playbook file to run (in provision/playbooks)
For e.g,
    PLAYBOOK='webserver' \
		ANSIBLE_GROUPS='webservers' \
		ANSIBLE_TAGS='users_setup,vhosts_setup,letsencrypt_setup' \
		EXTRA_VARS='{"foo": "unquoted and 'quoted'"}' \
		EXTRA_ARGS='-vvvv' \
    make run-playbook

  (See Ansible playbook docs for more)
endef

define RUN_PACKER_HELP
Usage: PACKER_IMAGE=foo make deploy-machine-image
  See here for more - https://www.packer.io/docs/commands
endef

define _create_gitlab_env_variable
export new_var="$(shell echo $1 | tr '[:lower:]' '[:upper:]')" \
	&& curl -X POST -H "PRIVATE-TOKEN: $(PROJECT_GITLAB_USER_ACCESS_TOKEN)" \
	--form "key=$$new_var" \
	--form "value=$2" \
	--form "protected=false" \
	"https://gitlab.com/api/v4/projects/$(PROJECT_GITLAB_ID)/variables"
endef

define PRINT_HELP_PYSCRIPT
import re, sys
for line in sys.stdin:
	match = re.match(r'^([a-zA-Z_-]+):.*?## (.*)$$', line)
	if match:
		target, help = match.groups()
		print("%-20s %s" % (target, help))
endef
export PRINT_HELP_PYSCRIPT


# ================== Make commands ====================
help:
	@python -c "$$PRINT_HELP_PYSCRIPT" < $(MAKEFILE_LIST)


.PHONY: create-env-var create-ops-ssh-key create-project-tfrc
create-env-var: ## Create a new secret var in Gitlab's CI/CD
ifeq ($(KEY), )
	@echo "Usage: KEY=key_name VALUE=value make create-env-var"
	@exit 1
endif
	$(call _create_gitlab_env_variable,$(KEY),$(VALUE))


create-ops-ssh-key: ## Create a new SSH key for ops
ifeq ($(OPS_EMAIL), )
	@echo "Usage: OPS_USER=ops OPS_EMAIL=abc@example.com make create-ops-ssh-key"
	@exit 1
endif
	ssh-keygen -t rsa -b 4096 -N '' -C $(OPS_EMAIL) -m PEM -f ~/.ssh/$(OPS_USER)
	@cat ~/.ssh/$(OPS_USER).pub


create-project-tfrc: ## Create .terraformrc file for the specified project
ifeq ($(PROJECT_NAMESPACE), )
	@echo "Usage: Run the following commands in succession -"
	@echo "       make create-project-tfrc"
	@echo "       export TF_CLI_CONFIG_FILE=$HOME/.terraformrc-$(PROJECT_NAMESPACE)"
endif
	@mkdir -p $(HOME)/.terraform.d/plugin-cache
	@echo -e \
	  credentials "app.terraform.io" {\\n\
      token = "$(TFC_TOKEN)"\\n\
    }\\n\
    plugin_cache_dir = "$$HOME/.terraform.d/plugin-cache" >> $(HOME)/.terraformrc-$(PROJECT_NAMESPACE)
	@echo "Now run: export TF_CLI_CONFIG_FILE=\$$HOME/.terraformrc-$(PROJECT_NAMESPACE)"

.PHONY: deploy-machine-image
deploy-machine-image:
ifeq ($(PROVISION_ROOT), )
	@echo "Usage: Run the following commands -"
	@echo "       PROVISION_ROOT=\$PWD make deploy-machine-image"
endif
	@packer build images/webserver.pkr.hcl


.PHONY: create-role install-role run-playbook
################################################
#  Ansible tasks
################################################
create-role: ## Run ansible-galaxy to create an offline role
ifeq ($(ROLE_NAME), )
	@echo "$$CREATE_ROLE_HELP"
	@exit 1
endif
	@cd $(PLAYBOOK_ROOT) \
		&& ansible-galaxy init roles/internal/$(ROLE_NAME)


install-role: ## Run ansible-galaxy to install a role from the community modules
ifeq ($(ROLE_NAME), )
	@echo "$$INSTALL_ROLE_HELP"
	@exit 1
endif
	@cd $(PLAYBOOK_ROOT) \
		&& ansible-galaxy install --roles-path=roles/external $(ROLE_NAME)


run-playbook: ## Run ansible-playbook to provision a service or instance
ifeq ($(PLAYBOOK), )
	@echo "$$RUN_PLAYBOOK_HELP"
	@exit 1
endif
ifeq ($(ANSIBLE_GROUPS), )
	@echo "$$RUN_PLAYBOOK_HELP"
	@exit 1
endif
	@echo "==> Running Ansible playbook $(PLAYBOOK).yml"
	cd $(PLAYBOOK_ROOT) \
		&& ansible-playbook -i inventory/hosts.ini $(PLAYBOOK).yml \
		--tags '$(ANSIBLE_TAGS)' \
		--limit '$(ANSIBLE_GROUPS)' \
		--extra-vars '$(EXTRA_VARS)' \
		$(EXTRA_ARGS)


.PHONY: clean clean-ansible
################################################
#  Cleanup tasks
################################################
clean: clean-ansible ## remove all unwanted artifacts

clean-ansible:
	find . -name '*.retry' -exec rm -f {} +
