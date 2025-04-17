droseraup
foundryup

mkdir my-drosera-trap
cd my-drosera-trap

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
