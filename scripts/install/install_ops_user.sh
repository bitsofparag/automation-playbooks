#!/bin/bash
set -eou pipefail
export DEBIAN_FRONTEND=noninteractive
u=${OPS_USER:-`whoami`}

mkdir -p /home/$u
groupadd -rg 1010 $u
useradd -rg $u -G wheel,sudo -u 1010 -d /home/$u $u
chown $u:$u /home/$u
