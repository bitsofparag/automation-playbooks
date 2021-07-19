#!/bin/bash
set -eou pipefail
export DEBIAN_FRONTEND=noninteractive

apt_install='apt-get install -y --no-install-recommends'

echo 'deb http://deb.debian.org/debian buster-backports main' >> /etc/apt/sources.list
echo 'deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/Debian_10/ /' > /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list
curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/Debian_10/Release.key | sudo apt-key add -
apt-get update
$apt_install -t buster-backports libseccomp2 uidmap
$apt_install podman
