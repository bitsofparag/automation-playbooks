.DEFAULT_GOAL := help
SHELL = /bin/bash
ENVIRONMENT ?=

include .env.$(PROJECT_NAME)
export

PROJECT_ROOT = $(PWD)
PROVISION_ROOT = $(PROJECT_ROOT)


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


.PHONY: create-env-var create-ops-ssh-key
create-env-var: ## Create a new secret var in Gitlab's CI/CD
ifeq ($(KEY), )
	@echo "Usage: KEY=key_name VALUE=value make create-env-var"
	@exit 1
endif
	$(call _create_gitlab_env_variable, $(KEY), $(VALUE))

create-ops-ssh-key: ## Create a new SSH key for ops
ifeq ($(OPS_EMAIL), )
	@echo "Usage: OPS_USER=ops OPS_EMAIL=abc@example.com make create-ops-ssh-key"
	@exit 1
endif
	ssh-keygen -t rsa -b 4096 -N '' -C $(OPS_EMAIL) -m PEM -f ~/.ssh/$(OPS_USER)-shared
	@cat ~/.ssh/$(OPS_USER)-shared.pub


.PHONY: create-role install-role run-playbook
################################################
#  Ansible tasks
################################################
create-role: ## Run ansible-galaxy to create an offline role
ifeq ($(ROLE_NAME), )
	@echo "$$CREATE_ROLE_HELP"
	@exit 1
endif
	@cd $(PROVISION_ROOT) \
		&& ansible-galaxy init roles/internal/$(ROLE_NAME)


install-role: ## Run ansible-galaxy to install a role from the community modules
ifeq ($(ROLE_NAME), )
	@echo "$$INSTALL_ROLE_HELP"
	@exit 1
endif
	@cd $(PROVISION_ROOT) \
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
	@echo "\n==> Running Ansible playbook $(PLAYBOOK).yml"
	cd $(PROVISION_ROOT) \
		&& ansible-playbook -i inventory/hosts.ini \
		playbooks/$(PLAYBOOK).yml \
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
