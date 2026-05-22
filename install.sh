#!/bin/ash
set -e

cd /mnt/server

echo "🧹 Cleaning previous setup..."
rm -rf /mnt/server/ghost /mnt/server/.ghost /home/container/ghost || true

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
npm outdated
npm update -g

echo "🗂️ DEBUG 7"

echo "📦 Installing Ghost CLI..."
npm i --no-audit -g ghost-cli@latest

echo "🗂️ DEBUG 8"

echo "🗂️ Setting up directories..."
mkdir -p /.npm /.cache/yarn /home/container /mnt/server/.ghost
chmod -R 755 /.npm /.cache/yarn /home/container /mnt/server/.ghost
chown -R nobody: /mnt/server /home/container /.npm /.cache/yarn

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
su -s /bin/ash "nobody" -c "ghost install local --dir /home/container/ghost"

echo "🗂️ DEBUG 13"

unlink /.ghost

echo "🗂️ DEBUG 14"

echo "📦 Installing sharp..."
npm install -g sharp --unsafe-perm --no-audit

echo "🗂️ DEBUG 15"

echo "📦 Moving Ghost to server directory..."
mv /home/container/ghost /mnt/server/

echo "🗂️ DEBUG 16"

echo "✅ Ghost installation complete!"
