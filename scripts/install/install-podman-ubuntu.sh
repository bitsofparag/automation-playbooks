#!/bin/bash
set -eou pipefail
export DEBIAN_FRONTEND=noninteractive

apt_install='apt-get install -y --no-install-recommends'

echo ">>>>> Set system metadata as env vars..."
. /etc/os-release

echo ">>>>> Set package repo for downloading Podman..."
sh -c "echo 'deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_${VERSION_ID}/ /' > /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list"
wget -nv https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable/xUbuntu_${VERSION_ID}/Release.key -O- | apt-key add -
apt-get update -qq

echo ">>>>> Installing podman pre-requisites..."
$apt_install uidmap slirp4netns libfuse3-dev

echo ">>>>> Installing podman..."
$apt_install podman

cat <<EOF
======================================
Podman installed!
======================================

For troubleshooting issues, see:
https://github.com/containers/podman/blob/main/troubleshooting.md

EOF
