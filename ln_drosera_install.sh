#!/bin/bash

# === Install Drosera ===
curl -L https://app.drosera.io/install | bash
export PATH="$HOME/.local/bin:$PATH"
~/.local/bin/droseraup

# === Install Foundry ===
curl -L https://foundry.paradigm.xyz | bash
export PATH="$HOME/.foundry/bin:$PATH"
~/.foundry/bin/foundryup

# === Install Bun ===
curl -fsSL https://bun.sh/install | bash
export PATH="$HOME/.bun/bin:$PATH"

# === Load variables from files ===
PRIVATE=$(cat drosera_private.txt)
EMAIL=$(cat drosera_email.txt)
USERNAME=$(cat drosera_username.txt)

# === Clone and configure the project ===
mkdir my-drosera-trap
cd my-drosera-trap

git config --global user.email "$EMAIL"
git config --global user.name "$USERNAME"

# Use full path to forge
~/.foundry/bin/forge init -t drosera-network/trap-foundry-template

# Use full path to bun
~/.bun/bin/bun install

# Build with forge
~/.foundry/bin/forge build

# Run Drosera
export DROSERA_PRIVATE_KEY="$PRIVATE"
echo ofc | ~/.local/bin/drosera apply | tee drosera_ln.log | grep 'address:' > address_line.txt
