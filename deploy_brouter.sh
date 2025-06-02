#!/bin/bash

set -e
export DEBIAN_FRONTEND=noninteractive

# === CONFIGURATION ===
APP_NAME="brouter"
APP_PORT=17777
DOMAIN="brouter.rendzo.com"
EMAIL="admin@$DOMAIN"
NGINX_CONF="/etc/nginx/sites-available/$APP_NAME"

echo "===> Updating system and installing dependencies..."
apt update && apt upgrade -y
apt install -y docker.io nginx certbot python3-certbot-nginx curl ufw

# === Build Docker Image ===
echo "===> Building Docker image from current directory..."
docker build -t $APP_NAME .

# === Run Docker Container ===
echo "===> Starting container..."
docker rm -f $APP_NAME || true
docker run -d --restart always --name $APP_NAME -p $APP_PORT:$APP_PORT $APP_NAME

# === Configure Nginx with Reverse Proxy and CORS ===
echo "===> Creating Nginx config for $DOMAIN..."
cat > $NGINX_CONF <<EOF
server {
    listen 80;
    server_name $DOMAIN;

    location / {
        proxy_pass http://localhost:$APP_PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;

        # CORS headers
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS' always;
        add_header 'Access-Control-Allow-Headers' 'Content-Type, Authorization' always;

        if (\$request_method = OPTIONS) {
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

# === Issue HTTPS Certificate ===
echo "===> Requesting HTTPS certificate for $DOMAIN..."
certbot --non-interactive --agree-tos --nginx -d $DOMAIN -m $EMAIL

# === Firewall Configuration ===
echo "===> Configuring UFW firewall..."
ufw allow OpenSSH
ufw allow 'Nginx Full'
ufw --force enable

# === Done ===
echo "===> Deployment complete!"
echo "🌐 Your server is available at: https://$DOMAIN"