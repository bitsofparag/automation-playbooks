#!/bin/bash
set -eou pipefail
export DEBIAN_FRONTEND=noninteractive

apt-get remove -y ansible
apt-get autoremove -y

sync
