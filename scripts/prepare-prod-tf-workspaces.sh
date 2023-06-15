#!/bin/zsh -f

set -e -u -o pipefail

echo "Prepare ops env for base setup"
export ENVIRONMENT=prod
export PLAYBOOK=main
export ANSIBLE_GROUPS=adminpc
export PROJECT_NAMESPACE=bp
export PLAYBOOK_ROOT=$HOME/Workspace/play/automation-playbooks
export PROJECT_ROOT=$HOME/Workspace/play/infra-as-code
export OPS_REPO_NAME=infra-as-code
export COOKIE_HOME=${COOKIE_HOME:-null}
export TF_CLI_CONFIG_FILE=$HOME/.terraformrc-${PROJECT_NAMESPACE}

set -a; source .env.${PROJECT_NAMESPACE}; set +a;

make create-ops-ssh-key

EXTRA_VARS='user_key_file=${OPS_USER}-${ENVIRONMENT}' ANSIBLE_TAGS=tfc_keys_new make run-playbook

mkdir -p group_vars/${PROJECT_NAMESPACE}_ops
envsubst < group_vars/templates/tfc_base_workspaces.json > group_vars/${PROJECT_NAMESPACE}_ops/tfc_base_workspaces.json
read -p "Update vars and then press enter to continue"

EXTRA_VARS='deploy_environment=${ENVIRONMENT}' \
    EXTRA_ARGS='--extra-vars "@group_vars/${PROJECT_NAMESPACE}_ops/tfc_base_workspaces.json"' \
    ANSIBLE_TAGS=tfc_base_workspaces_new \
    make run-playbook

EXTRA_VARS='deploy_environment=${ENVIRONMENT}' \
    ANSIBLE_TAGS=tfc_base_workspaces_tags_new \
    make run-playbook


w=( $(cat group_vars/${PROJECT_NAMESPACE}_ops/tfc_base_workspaces.json | jq -r ".tfc_base_workspaces[].name_prefix") )
num_w="${#w[@]}"
echo "${w[@]}"

# Loop through the workspaces and update the vars
for (( i=1; i<=$num_w; i++ ))
do
    export wname="${w[i]}"
    echo "Updating vars for ${wname}"
    EXTRA_VARS='tfc_workspace_name=${wname} deploy_environment=dev add_environment=${ENVIRONMENT}' \
        ANSIBLE_TAGS=tfc_vars_edit \
        make run-playbook

    sleep 2
    echo "Done updating vars for ${wname}"

    EXTRA_VARS='tfc_workspace_name=${wname} deploy_environment=${ENVIRONMENT}' \
        EXTRA_ARGS='--extra-vars "@group_vars/${PROJECT_NAMESPACE}_ops/${ENVIRONMENT}/tfc_${wname}_vars.json"' \
        ANSIBLE_TAGS=tfc_vars_new \
        make run-playbook

    EXTRA_VARS='user_key_file=${OPS_USER}-${ENVIRONMENT} tfc_workspace_name=${wname} deploy_environment=${ENVIRONMENT}' \
        ANSIBLE_TAGS=tfc_workspace_keys_edit \
        make run-playbook
done
