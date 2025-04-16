#!/bin/bash
set -e

echo "🔧 Starting Drosera Node Installation..."

# === Update system ===
echo "🔄 Updating packages..."
sudo apt-get update && sudo apt-get upgrade -y

# === Install dependencies ===
echo "📦 Installing required packages..."
sudo apt install -y curl ufw iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev ca-certificates gnupg

# === Remove old Drosera ===
echo "🪜 Removing old drosera versions..."
rm -f "$HOME/.cargo/bin/drosera"
sudo rm -f /usr/local/bin/drosera

# === Install Drosera v1.16.2 ===
echo "📅 Installing Drosera v1.16.2..."
cd /usr/local/bin
sudo curl -LO https://github.com/drosera-network/releases/releases/download/v1.16.2/drosera-v1.16.2-x86_64-unknown-linux-gnu.tar.gz
sudo tar -xvf drosera-v1.16.2-x86_64-unknown-linux-gnu.tar.gz
sudo chmod +x drosera
sudo rm drosera-v1.16.2-x86_64-unknown-linux-gnu.tar.gz

# === Clear shell command cache ===
hash -r

# === Confirm version ===
echo "✅ Drosera version installed:"
drosera --version

# === Install Rust (if missing, required for some tooling) ===
echo "🦀 Installing Rust (Cargo)..."
if ! command -v cargo &> /dev/null; then
  curl https://sh.rustup.rs -sSf | sh -s -- -y
  source "$HOME/.cargo/env"
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
