#!/bin/bash

# Stop and remove all containers
docker stop $(docker ps -aq)
docker rm $(docker ps -aq)

# Remove all images
docker rmi -f $(docker images -q)

# Remove all volumes
docker volume prune -f

# delete nginx config
rm -f /etc/nginx/sites-enabled/brouter /etc/nginx/sites-available/brouter
nginx -t && systemctl reload nginx

# reset ufw
ufw reset

# delete project folder
rm -rf brouter-test/