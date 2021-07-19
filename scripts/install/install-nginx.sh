#!/bin/bash
set -eou pipefail
export DEBIAN_FRONTEND=noninteractive
NGINX_VERSION=${NGINX_VERSION:-1.21.0}-1~$(lsb_release -cs)

apt_install='apt-get install -y --no-install-recommends'

# Taken from http://nginx.org/en/linux_packages.html
echo ">>>>> Install the prerequisites..."
$apt_install curl gnupg2 ca-certificates lsb-release

echo ">>>>> Update repository settings for nginx packages..."
echo "deb http://nginx.org/packages/mainline/`lsb_release -is |  tr '[:upper:]' '[:lower:]'` `lsb_release -cs` nginx" \
    | sudo tee /etc/apt/sources.list.d/nginx.list
echo -e "Package: *\nPin: origin nginx.org\nPin: release o=nginx\nPin-Priority: 900\n" \
    | sudo tee /etc/apt/preferences.d/99nginx
curl -o /tmp/nginx_signing.key https://nginx.org/keys/nginx_signing.key

echo ">>>>> Restart gpg agent"
gpgconf --kill gpg-agent
gpg --dry-run --homedir="/home/`logname`" --quiet --import --import-options import-show /tmp/nginx_signing.key
mv /tmp/nginx_signing.key /etc/apt/trusted.gpg.d/nginx_signing.asc

echo ">>>>> Installing nginx ${NGINX_VERSION}..."
apt-get update
$apt_install nginx=$(echo $NGINX_VERSION)

# Sources:
# https://certbot.eff.org/lets-encrypt/debianbuster-nginx
# https://certbot.eff.org/lets-encrypt/ubuntufocal-nginx
echo ">>>>> Install snapd..."
if [ "$(lsb_release -is)" == "Debian" ]; then
    $apt_install snapd
fi
snap install core
snap refresh core

echo ">>>>> Install certbot..."
snap install --classic certbot
ln -sf /snap/bin/certbot /usr/bin/certbot

echo ">>>>> Install additional security utils..."
$apt_install apache2-utils
$apt_install ufw

echo ">>>>> Run some housekeeping..."
cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup
mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled
chown -R www-data /var/log/nginx
ufw allow 80,443/tcp
ufw status

echo ">>>>> Updating DH keys..."
openssl dhparam -out /etc/nginx/dhparam.pem 2048

echo ">>>>> Installed. Please check firewall settings and configure virtual hosts."
echo ">>>>> You can run Nginx with: systemctl reload nginx"
