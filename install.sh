#!/bin/ash
set -e

cd /mnt/server

echo "🗂️ DEBUG 1"


echo "🧰 Installing runtime dependencies..."
apk add --no-cache \
  python3 py3-pip py3-setuptools py3-wheel \
  make g++ vips-dev build-base autoconf automake libtool \
  nasm libc6-compat bash curl su-exec ca-certificates

echo "🗂️ DEBUG 2"

echo "🧰 Installing dependencies..."
apk --no-cache add sudo curl
apk add --no-cache 'su-exec>=0.2'

echo "🗂️ DEBUG 3"

echo "⬇️  Downloading Node.js 22.22.3..."
curl -fsSL https://unofficial-builds.nodejs.org/download/release/v22.22.3/node-v22.22.3-linux-x64-musl.tar.xz -o node.tar.xz

echo "📦 Extracting Node.js..."
tar -xf node.tar.xz -C /usr/local --strip-components=1
rm -f node.tar.xz

echo "🗂️ DEBUG 4"

# Ensure Node 22 replaces Node 18 everywhere
export PATH="/usr/local/bin:$PATH"
if [ -f /usr/bin/node ]; then
  rm -f /usr/bin/node
  ln -s /usr/local/bin/node /usr/bin/node
fi

echo "🗂️ DEBUG 5"

echo "✅ Node version after upgrade:"
node -v

echo "🗂️ DEBUG 6"

echo "🗂️ Updating node packages"
npm outdated || true
npm update -g || true

echo "🗂️ DEBUG 7"

echo "📦 Installing Ghost CLI..."
npm i --no-audit -g ghost-cli@latest

echo "📦 Installing Corepack..."
npm i -g corepack@latest
corepack enable
corepack prepare pnpm@latest --activate

echo "🗂️ DEBUG 8"

echo "🗂️ Setting up directories..."
mkdir -p \
  /.npm \
  /.cache/yarn \
  /home/container \
  /home/container/.cache \
  /home/container/.cache/node \
  /home/container/.cache/corepack \
  /home/container/.local/share/corepack \
  /mnt/server/.ghost \
  /mnt/server/ghost

chmod -R 755 \
  /.npm \
  /.cache/yarn \
  /home/container \
  /mnt/server/.ghost \
  /mnt/server/ghost

chown -R nobody: \
  /mnt/server \
  /home/container \
  /.npm \
  /.cache/yarn

echo "🗂️ DEBUG 9"

echo "📁 Copying required files..."
cp -r ./temp/caddy /mnt/server/
cp ./temp/start.sh /mnt/server
curl -fsSL "https://caddyserver.com/api/download?os=linux&arch=amd64&idempotency=33572405766393" -o /mnt/server/caddy-server

echo "🗂️ DEBUG 10"

chmod +x /mnt/server/caddy-server /mnt/server/start.sh

echo "🗂️ DEBUG 11"

# Route Ghost config to mount
ln -s /mnt/server/.ghost /.ghost

echo "🗂️ DEBUG 12"

echo "🚀 Installing Ghost..."
su -s /bin/ash nobody -c '
  export HOME=/home/container
  export XDG_CACHE_HOME=/home/container/.cache
  export COREPACK_HOME=/home/container/.cache/corepack
  export npm_config_cache=/home/container/.cache/npm
  export PATH="/usr/local/bin:$PATH"

  ghost install local --dir /mnt/server/ghost --no-start
'

echo "🗂️ DEBUG 13"

unlink /.ghost

echo "🗂️ DEBUG 14"

echo "📦 Installing sharp..."
npm install -g sharp --unsafe-perm --no-audit

echo "🗂️ DEBUG 15"

echo "🔗 Fixing Ghost current symlink for Pterodactyl runtime..."
GHOST_VERSION="$(basename "$(readlink /mnt/server/ghost/current)")"
rm -f /mnt/server/ghost/current
ln -s "versions/${GHOST_VERSION}" /mnt/server/ghost/current

echo "📦 Verifying Ghost install..."
ls -la /mnt/server
ls -la /mnt/server/ghost
ls -la /mnt/server/ghost/current

echo "🗂️ DEBUG 16"

echo "✅ Ghost installation complete!"