#!/bin/bash

set -e
export DEBIAN_FRONTEND=noninteractive

# === CONFIGURATION ===
APP_NAME="brouter"
APP_PORT=17777
NGINX_CONF="/etc/nginx/sites-available/$APP_NAME"
PROJECT_DIR="/root/$APP_NAME"
REPO_URL="https://github.com/your-username/your-repo.git"  # Optional

# === 1. Update System & Install Dependencies ===
echo "===> Installing system dependencies..."
apt update && apt upgrade -y
apt install -y docker.io docker-compose nginx git ufw curl

# === 2. Clone Project (if missing) ===
if [ ! -d "$PROJECT_DIR" ]; then
  echo "===> Cloning project repository..."
  git clone "$REPO_URL" "$PROJECT_DIR"
fi
cd "$PROJECT_DIR"

# === 3. Build Docker Image ===
echo "===> Building Docker image..."
docker build -t $APP_NAME .

# === 4. Run Container to Download Segments ===
echo "===> Running init container to download segments..."
docker rm -f ${APP_NAME}-init || true
docker run --name ${APP_NAME}-init $APP_NAME /bin/download_segments.sh

# === 5. Commit Image with Segments ===
echo "===> Committing container with segments..."
docker commit ${APP_NAME}-init ${APP_NAME}:with-segments
docker rm -f ${APP_NAME}-init

# === 6. Run Production Container ===
echo "===> Running production container..."
docker rm -f $APP_NAME || true
docker run -d --restart always --name $APP_NAME -p $APP_PORT:$APP_PORT ${APP_NAME}:with-segments

# === 7. Nginx Reverse Proxy with CORS ===
echo "===> Configuring Nginx with CORS..."
cat > $NGINX_CONF <<EOF
server {
    listen 80 default_server;
    server_name _;

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
            add_header 'Content-Type' 'text/plain; charset=UTF-8';
            add_header 'Content-Length' 0;
            return 204;
        }
    }
}
EOF

ln -sf $NGINX_CONF /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx

# === 8. Firewall Rules ===
echo "===> Setting up UFW firewall..."
ufw allow OpenSSH
ufw allow 'Nginx Full'
ufw --force enable

# === 9. Show Access URL ===
DROPLET_IP=$(curl -s ifconfig.me)
echo "===> DONE! Your server is live:"
echo "👉 http://$DROPLET_IP"