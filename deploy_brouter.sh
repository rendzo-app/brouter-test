#!/bin/bash

set -e

# === CONFIGURATION ===
APP_NAME="brouter"
DOMAIN="brouter.rendzo.com"
REPO_URL="https://github.com/rendzo-app/brouter-test.git"
APP_PORT=17777
NGINX_CONF="/etc/nginx/sites-available/$APP_NAME"

echo "===> Updating system"
apt update && apt upgrade -y

echo "===> Installing required packages"
apt install -y docker.io docker-compose nginx certbot python3-certbot-nginx git ufw

# echo "===> Cloning project repo (if needed)"
# if [ ! -d "/root/$APP_NAME" ]; then
#   git clone "$REPO_URL" "/root/$APP_NAME"
# fi
# cd "/root/$APP_NAME"

echo "===> Building Docker image"
docker build -t $APP_NAME .

echo "===> Running container to download segments"
docker rm -f ${APP_NAME}-init || true
docker run --name ${APP_NAME}-init $APP_NAME /bin/download_segments.sh

echo "===> Committing container with segments"
docker commit ${APP_NAME}-init ${APP_NAME}:with-segments
docker rm -f ${APP_NAME}-init

echo "===> Running production container"
docker rm -f $APP_NAME || true
docker run -d --restart always --name $APP_NAME -p $APP_PORT:$APP_PORT ${APP_NAME}:with-segments

echo "===> Configuring Nginx reverse proxy with CORS"
cat > $NGINX_CONF <<EOF
server {
    listen 80;
    server_name $DOMAIN;

    location / {
        proxy_pass http://localhost:$APP_PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;

        # CORS Headers
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS' always;
        add_header 'Access-Control-Allow-Headers' 'Content-Type, Authorization' always;

        if (\$request_method = 'OPTIONS') {
            add_header 'Access-Control-Max-Age' 1728000;
            add_header 'Content-Type' 'text/plain charset=UTF-8';
            add_header 'Content-Length' 0;
            return 204;
        }
    }
}
EOF

ln -sf $NGINX_CONF /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx

echo "===> Setting up HTTPS via Certbot"
certbot --non-interactive --agree-tos --nginx -d $DOMAIN -m admin@$DOMAIN

echo "===> Firewall: allowing OpenSSH + HTTPS"
ufw allow OpenSSH
ufw allow 'Nginx Full'
ufw --force enable

echo "===> Done! Your app should be live at: https://$DOMAIN"