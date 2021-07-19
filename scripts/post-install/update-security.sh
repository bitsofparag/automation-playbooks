#!/bin/bash
set -eou pipefail
export DEBIAN_FRONTEND=noninteractive
CUSTOM_SSH_PORT=${CUSTOM_SSH_PORT:-22}

apt_install='apt-get install -y --no-install-recommends'

echo ">>>>> Updating firewall settings..."
$apt_install ufw
ufw allow ${CUSTOM_SSH_PORT}/tcp
ufw status
