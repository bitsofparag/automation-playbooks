#!/bin/bash
set -eou pipefail
export DEBIAN_FRONTEND=noninteractive
apt_install='apt-get install -y --no-install-recommends'

apt-get update

apt-add-repository -y ppa:ansible/ansible
apt-get update
$apt_install python3-pip
$apt_install ansible
