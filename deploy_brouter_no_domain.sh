#!/bin/bash

set -e
export DEBIAN_FRONTEND=noninteractive

# === CONFIGURATION ===
APP_NAME="brouter"
APP_PORT=17777
NGINX_CONF="/etc/nginx/sites-available/$APP_NAME"
PROJECT_DIR="/root/$APP_NAME"
REPO_URL="https://github.com/rendzo-app/brouter-test.git"

# === 1. System Update & Dependencies ===
echo "===> Updating system and installing dependencies..."
apt update && apt upgrade -y
apt install -y docker.io docker-compose nginx git ufw curl

# === 2. Clone Project (optional) ===
if [ ! -d "$PROJECT_DIR" ]; then
  echo "===> Cloning repository..."
  git clone "$REPO_URL" "$PROJECT_DIR"
fi
cd "$PROJECT_DIR"

# === 3. Build Docker Image ===
echo "===> Building Docker image..."
docker build -t $APP_NAME .

# === 4. Run One-Time Container to Download Segments ===
echo "===> Running init container to download segments..."
docker rm -f ${APP_NAME}-init || true
docker run --name ${APP_NAME}-init $APP_NAME /bin/download_segments.sh

# === 5. Commit Container with Segments ===
echo "===> Saving container with downloaded segments..."
docker commit ${APP_NAME}-init ${APP_NAME}:with-segments
docker rm -f ${APP_NAME}-init

# === 6. Start Production Container ===
echo "===> Starting production container..."
docker rm -f $APP_NAME || true
docker run -d --restart always --name $APP_NAME -p $APP_PORT:$APP_PORT ${APP_NAME}:with-segments

# === 7. Configure Nginx Reverse Proxy with CORS ===
echo "===> Configuring Nginx reverse proxy with CORS..."
cat > $NGINX_CONF <<EOF
server {
    listen 80 default_server;
    server_name _;

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

# === 8. Enable UFW Firewall ===
echo "===> Enabling firewall..."
ufw allow OpenSSH
ufw allow 'Nginx Full'
ufw --force enable

# === 9. Done ===
DROPLET_IP=$(curl -s ifconfig.me)
echo "===> DONE!"
echo "Your BRouter server is available at: http://$DROPLET_IP"