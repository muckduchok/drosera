bash -c '
set -euo pipefail

curl -L https://app.drosera.io/install | bash
droseraup

curl -L https://foundry.paradigm.xyz | bash
export PATH="$HOME/.foundry/bin:$PATH"
foundryup

curl -fsSL https://bun.sh/install | bash
'

PRIVATE=$(cat drosera_private.txt)
EMAIL=$(cat drosera_email.txt)
USERNAME=$(cat drosera_username.txt)

mkdir my-drosera-trap
cd my-drosera-trap

git config --global user.email $EMAIL
git config --global user.name $USERNAME

forge init -t drosera-network/trap-foundry-template
bun install
forge build

export DROSERA_PRIVATE_KEY=$PRIVATE
echo ofc | drosera apply | tee drosera_ln.log | grep 'address:' > address_line.txt
