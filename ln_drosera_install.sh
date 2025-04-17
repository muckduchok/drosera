#!/usr/bin/env bash
set -euo pipefail

### ─────────────────────── 1. Drosera CLI ───────────────────────
curl -L https://app.drosera.io/install | bash
PS1='$ ' source ~/.bashrc         # чтобы drosera попал в PATH
droseraup

### ─────────────────────── 2. Foundry (forge) ───────────────────
curl -L https://foundry.paradigm.xyz | bash
# гарантируем PATH
echo 'export PATH="$HOME/.foundry/bin:$PATH"' >> ~/.bashrc
PS1='$ ' source ~/.bashrc
foundryup                 # скачивает forge/cast/anvil

### ─────────────────────── 3. Bun ───────────────────────────────
curl -fsSL https://bun.sh/install | bash
echo 'export PATH="$HOME/.bun/bin:$PATH"' >> ~/.bashrc
PS1='$ ' source ~/.bashrc

### ─────────────────────── 4. Trap‑проект ───────────────────────
mkdir -p my-drosera-trap
cd my-drosera-trap

# берём данные из файлов (или подставь свои значения сразу)
EMAIL=$(cat ../drosera_email.txt)
USERNAME=$(cat ../drosera_username.txt)
PRIVATE=$(cat ../drosera_private.txt)

git config --global user.email "$EMAIL"
git config --global user.name  "$USERNAME"

forge init -t drosera-network/trap-foundry-template
bun install
forge build

### ─────────────────────── 5. Apply trap ────────────────────────
export DROSERA_PRIVATE_KEY=$PRIVATE
echo ofc | drosera apply | tee drosera_ln.log | grep 'address:' > address_line.txt
