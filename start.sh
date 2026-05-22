#!/bin/ash
set -e

cd /home/container

echo "PWD: $(pwd)"
echo "Listing /home/container:"
ls -la /home/container

echo "Listing /home/container/ghost:"
ls -la /home/container/ghost

echo "Fixing Ghost current symlink..."
if [ -d /home/container/ghost/versions ]; then
  GHOST_VERSION="$(find /home/container/ghost/versions -mindepth 1 -maxdepth 1 -type d | sed 's|.*/||' | sort | tail -n 1)"

  if [ -n "${GHOST_VERSION}" ] && [ -d "/home/container/ghost/versions/${GHOST_VERSION}" ]; then
    rm -f /home/container/ghost/current
    ln -s "versions/${GHOST_VERSION}" /home/container/ghost/current
  else
    echo "Could not determine installed Ghost version."
    exit 1
  fi
else
  echo "Ghost versions directory does not exist."
  exit 1
fi

echo "Fixing Ghost runtime paths..."
sed -i 's|/mnt/server/ghost/content/data/ghost-local.db|/home/container/ghost/content/data/ghost-local.db|g' /home/container/ghost/config.development.json
sed -i 's|/mnt/server/ghost/content|/home/container/ghost/content|g' /home/container/ghost/config.development.json
mkdir -p /home/container/ghost/content/data

echo "Listing fixed Ghost current symlink:"
ls -la /home/container/ghost/current
ls -la /home/container/ghost/current/index.js

echo "Ghost config:"
cat /home/container/ghost/config.development.json

echo "Starting Caddy..."
./caddy-server run --watch --config ./caddy/Caddyfile &

echo "Starting Ghost..."
cd /home/container/ghost
exec ghost run