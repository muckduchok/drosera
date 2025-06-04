$HOME/.drosera/bin/droseraup
$HOME/.foundry/bin/foundryup

mkdir my-drosera-trap
cd my-drosera-trap

EMAIL=$(cat ../drosera_email.txt)
USERNAME=$(cat ../drosera_username.txt)
PRIVATE=$(cat ../drosera_private.txt)
TRAP_ADDRESS=$(cat ../trap_address_recovery.txt)

git config --global user.email "$EMAIL"
git config --global user.name  "$USERNAME"

$HOME/.foundry/bin/forge init -t drosera-network/trap-foundry-template
$HOME/.bun/bin/bun install
$HOME/.foundry/bin/forge build

if [ -n "${TRAP_ADDRESS:-}" ]; then
    grep -Eq '^[[:space:]]*address[[:space:]]*=' drosera.toml \
        || echo "address = \"${TRAP_ADDRESS}\"" >> drosera.toml
fi

export DROSERA_PRIVATE_KEY=$PRIVATE
echo ofc | $HOME/.drosera/bin/drosera apply | tee drosera_ln.log | grep 'address:' > address_line.txt
