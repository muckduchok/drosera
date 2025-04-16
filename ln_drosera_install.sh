#!/bin/bash
set -e

echo "🔧 Starting Drosera Node Installation..."

# === Update system ===
echo "🔄 Updating packages..."
sudo apt-get update && sudo apt-get upgrade -y

# === Install dependencies ===
echo "📦 Installing required packages..."
sudo apt install -y curl ufw iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev ca-certificates gnupg

# === Install Docker (with GPG fix) ===
echo "🐳 Installing Docker..."
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
  sudo apt-get remove -y "$pkg" || true
done

sudo install -m 0755 -d /etc/apt/keyrings
export GPG_TTY=$(tty)

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
  sudo gpg --batch --yes --dearmor -o /etc/apt/keyrings/docker.gpg

sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update -y && sudo apt upgrade -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "✅ Docker installed. Testing..."
sudo docker run hello-world || echo "⚠️ Docker test container failed (may be expected in some environments)."

# === Install Rust + Cargo if missing ===
echo "🦀 Installing Rust (Cargo)..."
if ! command -v cargo &> /dev/null; then
  curl https://sh.rustup.rs -sSf | sh -s -- -y
  source "$HOME/.cargo/env"
fi
export PATH="$HOME/.cargo/bin:$PATH"

# === Ensure Drosera CLI is installed and recent ===
echo "🔍 Checking Drosera version..."
REQUIRED_VERSION="1.16.2"
INSTALLED_VERSION=$(drosera --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "0.0.0")

version_ge() {
  [ "$(printf '%s\n' "$1" "$2" | sort -V | head -n 1)" != "$1" ]
}

if ! command -v drosera &> /dev/null || ! version_ge "$INSTALLED_VERSION" "$REQUIRED_VERSION"; then
  echo "📥 Installing or upgrading Drosera to >= $REQUIRED_VERSION..."
  cargo install drosera --force
else
  echo "✅ Drosera version $INSTALLED_VERSION is up to date."
fi

# === Install Foundry ===
echo "⚙️ Installing Foundry..."
curl -L https://foundry.paradigm.xyz | bash
source "$HOME/.bashrc"
export PATH="$HOME/.foundry/bin:$PATH"
foundryup

# === Install Bun ===
echo "🍞 Installing Bun..."
curl -fsSL https://bun.sh/install | bash
export PATH="$HOME/.bun/bin:$PATH"

# === Load user secrets ===
if [[ ! -f drosera_private.txt || ! -f drosera_email.txt || ! -f drosera_username.txt ]]; then
  echo "❌ Missing one of: drosera_private.txt, drosera_email.txt, drosera_username.txt"
  exit 1
fi

PRIVATE=$(cat drosera_private.txt)
EMAIL=$(cat drosera_email.txt)
USERNAME=$(cat drosera_username.txt)

# === Setup Trap project ===
echo "🧪 Setting up Trap project..."
mkdir -p ~/my-drosera-trap
cd ~/my-drosera-trap

git config --global user.email "$EMAIL"
git config --global user.name "$USERNAME"

~/.foundry/bin/forge init -t drosera-network/trap-foundry-template

~/.bun/bin/bun install
~/.foundry/bin/forge build

# === Deploy Trap ===
echo "🚀 Deploying Trap..."
export DROSERA_PRIVATE_KEY="$PRIVATE"
echo ofc | drosera apply | tee drosera_ln.log | grep 'address:' > address_line.txt

echo "✅ Trap successfully deployed! Address:"
cat address_line.txt
