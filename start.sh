#!/bin/ash
set -e

cd /home/container

echo "Starting Ghost CMS..."
echo "PWD: $(pwd)"

if [ ! -d /home/container/ghost ]; then
  echo "Ghost directory not found."
  exit 1
fi

echo "Fixing Ghost current symlink..."
if [ -d /home/container/ghost/versions ]; then
  GHOST_VERSION="$(find /home/container/ghost/versions -mindepth 1 -maxdepth 1 -type d | sed 's|.*/||' | sort -V | tail -n 1)"

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

mkdir -p /home/container/ghost/content/data
mkdir -p /home/container/ghost/content/logs
mkdir -p /home/container/ghost/content/themes

cat > /home/container/ghost/config.development.json <<EOF
{
  "url": "https://just-mc.com/",
  "server": {
    "port": 2368,
    "host": "127.0.0.1"
  },
  "database": {
    "client": "sqlite3",
    "connection": {
      "filename": "/home/container/ghost/content/data/ghost-local.db"
    }
  },
  "mail": {
    "transport": "Direct"
  },
  "logging": {
    "transports": [
      "file",
      "stdout"
    ]
  },
  "process": "local",
  "security": {
    "staffDeviceVerification": false
  },
  "paths": {
    "contentPath": "/home/container/ghost/content"
  }
}
EOF

echo "Ensuring Ghost Source theme exists..."
if [ ! -d /home/container/ghost/content/themes/source ]; then
  rm -rf /home/container/ghost/content/themes/source
  mkdir -p /home/container/ghost/content/themes/source

  mkdir -p /tmp/source-theme
  rm -rf /tmp/source-theme/*

  curl -fsSL https://github.com/TryGhost/Source/archive/refs/heads/main.tar.gz -o /tmp/source-theme.tar.gz
  tar -xzf /tmp/source-theme.tar.gz -C /tmp/source-theme --strip-components=1
  rm -f /tmp/source-theme.tar.gz

  cp -r /tmp/source-theme/. /home/container/ghost/content/themes/source/
  rm -rf /tmp/source-theme
fi

rm -f /home/container/ghost/.ghostpid

echo "Writing Caddyfile..."
cat > /home/container/caddy/Caddyfile <<EOF
{
    admin off
    http_port ${SERVER_PORT}
}

:${SERVER_PORT} {
    encode zstd gzip

    reverse_proxy 127.0.0.1:2368 {
        header_up Host {host}
        header_up X-Real-IP {remote_host}
        header_up X-Forwarded-For {remote_host}
        header_up X-Forwarded-Proto https
        header_up X-Forwarded-Host {host}
    }
}
EOF

echo "Starting Caddy..."
cd /home/container
./caddy-server run --config ./caddy/Caddyfile &

echo "Starting Ghost in foreground..."
cd /home/container/ghost

export NODE_ENV=development
exec node current/index.js