#!/bin/bash

set -e

echo "=== Installing Drosera CLI ==="
curl -L https://app.drosera.io/install | bash
export PATH="$HOME/.local/bin:$PATH"

# Check if Rust (cargo) is installed, install if missing
if ! command -v cargo &> /dev/null; then
  echo "Installing Rust toolchain..."
  curl https://sh.rustup.rs -sSf | sh -s -- -y
  source "$HOME/.cargo/env"
  export PATH="$HOME/.cargo/bin:$PATH"
else
  echo "Rust is already installed."
  export PATH="$HOME/.cargo/bin:$PATH"
fi

# Install Drosera CLI via cargo if not present
if ! command -v drosera &> /dev/null; then
  echo "Installing Drosera CLI via cargo..."
  cargo install drosera
else
  echo "Drosera is already installed."
fi

# === Install Foundry ===
echo "=== Installing Foundry ==="
curl -L https://foundry.paradigm.xyz | bash
export PATH="$HOME/.foundry/bin:$PATH"
~/.foundry/bin/foundryup

# === Install Bun ===
echo "=== Installing Bun ==="
curl -fsSL https://bun.sh/install | bash
export PATH="$HOME/.bun/bin:$PATH"

# === Load variables from files ===
echo "=== Loading user data ==="
if [[ ! -f drosera_private.txt || ! -f drosera_email.txt || ! -f drosera_username.txt ]]; then
  echo "Missing one of the required files: drosera_private.txt, drosera_email.txt, drosera_username.txt"
  exit 1
fi

PRIVATE=$(< drosera_private.txt)
EMAIL=$(< drosera_email.txt)
USERNAME=$(< drosera_username.txt)

# === Clone and configure the project ===
echo "=== Setting up Drosera trap project ==="
mkdir -p my-drosera-trap
cd my-drosera-trap

git config --global user.email "$EMAIL"
git config --global user.name "$USERNAME"

~/.foundry/bin/forge init -t drosera-network/trap-foundry-template

# Install Bun deps
~/.bun/bin/bun install

# Compile project
~/.foundry/bin/forge build

# Run Drosera apply
export DROSERA_PRIVATE_KEY="$PRIVATE"
echo ofc | drosera apply | tee drosera_ln.log | grep 'address:' > address_line.txt

echo "✅ Done. Deployed address:"
cat address_line.txt
