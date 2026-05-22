#!/bin/ash
set -e

cd /home/container

echo "PWD: $(pwd)"
echo "Listing /home/container:"
ls -la /home/container

echo "Listing /home/container/ghost:"
ls -la /home/container/ghost

echo "Starting Caddy..."
./caddy-server run --watch --config ./caddy/Caddyfile &

echo "Starting Ghost..."
cd /home/container/ghost
exec ghost run