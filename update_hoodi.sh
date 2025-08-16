PRIVATE=$(cat drosera_private.txt)
PUBLIC=$(cat drosera_public.txt)
RPC=$(cat drosera_rpc2.txt)
TRAP_ADDRESS=$(cat trap_address_update.txt)

curl -L https://app.drosera.io/install | bash
source ~/.bashrc
$HOME/.drosera/bin/droseraup

cd my-drosera-trap
ROLE=$(sed -n 's/.*path[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' "drosera.toml" | head -n1) 

if [ "$RPC" = "{@custom_rpc2}" ]; then
  RPC=""
fi

if [ "$TRAP_ADDRESS" = "{@trap_address_update}" ]; then
  TRAP_ADDRESS=""
fi

$HOME/.drosera/bin/drosera dryrun

if grep -q '^eth_chain_id *= *17000' drosera.toml; then
  sed -i '/^address *= *".*"/d' drosera.toml
fi

if [ -n "${TRAP_ADDRESS//[[:space:]]/}" ]; then
    grep -Eq '^[[:space:]]*address[[:space:]]*=' drosera.toml \
  || echo "address = \"$TRAP_ADDRESS\"" >> drosera.toml
    sed -i "s#^address = \".*\"#address = \"$TRAP_ADDRESS\"#" drosera.toml
fi

grep -Eq '^[[:space:]]*private_trap[[:space:]]*=' drosera.toml \
  || echo 'private_trap = true' >> drosera.toml
sed -i "s/^whitelist = \[\]/whitelist = [\"$PUBLIC\"]/" drosera.toml
sed -i 's|drosera_rpc = ".*"|drosera_rpc = "https://relay.hoodi.drosera.io"|' drosera.toml
sed -i 's|eth_chain_id = .*|eth_chain_id = 560048|' drosera.toml
sed -i 's|drosera_address = ".*"|drosera_address = "0x91cB447BaFc6e0EA0F4Fe056F5a9b1F14bb06e5D"|' drosera.toml
sed -i 's|response_contract = ".*"|response_contract = "0x183D78491555cb69B68d2354F7373cc2632508C7"|' drosera.toml

if [ -n "${RPC//[[:space:]]/}" ]; then
    sed -i "s#^ethereum_rpc = \".*\"#ethereum_rpc = \"$RPC\"#" drosera.toml
else
  sed -i 's|ethereum_rpc = ".*"|ethereum_rpc = "https://rpc.hoodi.ethpandaops.io"|' drosera.toml
fi

if [ "$ROLE" = "out/Trap.sol/Trap.json" ]; then
  sed -i 's|^response_contract = ".*"|response_contract = "0x25E2CeF36020A736CF8a4D2cAdD2EBE3940F4608"|' drosera.toml
  sed -i 's|^response_function = ".*"|response_function = "respondWithDiscordName(string)"|' drosera.toml
fi

$HOME/.foundry/bin/forge build
$HOME/.drosera/bin/drosera dryrun
export DROSERA_PRIVATE_KEY=$PRIVATE
echo ofc | $HOME/.drosera/bin/drosera apply | tee drosera_ln.log | grep 'address:' > address_line.txt

cd ..

rm drosera-operator-v1.16.2-x86_64-unknown-linux-gnu.tar.gz
rm drosera-operator-v1.17.1-x86_64-unknown-linux-gnu.tar.gz
rm drosera-operator-v1.17.2-x86_64-unknown-linux-gnu.tar.gz
rm drosera-operator-v1.19.0-x86_64-unknown-linux-gnu.tar.gz
rm /usr/bin/drosera-operator
curl -LO https://github.com/drosera-network/releases/releases/download/v1.20.0/drosera-operator-v1.20.0-x86_64-unknown-linux-gnu.tar.gz
tar -xvf drosera-operator-v1.20.0-x86_64-unknown-linux-gnu.tar.gz
sudo cp drosera-operator /usr/bin
drosera-operator register --eth-rpc-url https://rpc.hoodi.ethpandaops.io --eth-private-key $PRIVATE --drosera-address 0x91cB447BaFc6e0EA0F4Fe056F5a9b1F14bb06e5D

cd my-drosera-trap
export DROSERA_PRIVATE_KEY=$PRIVATE
echo ofc | $HOME/.drosera/bin/drosera apply | tee drosera_ln.log | grep 'address:' > address_line.txt

sudo tee /etc/systemd/system/drosera.service > /dev/null <<EOF
[Unit]
Description=drosera node service
After=network-online.target

[Service]
User=$USER
Restart=always
RestartSec=15
StandardOutput=null
StandardError=null
LimitNOFILE=65535
ExecStart=$(which drosera-operator) node --db-file-path $HOME/.drosera.db --network-p2p-port 31313 --server-port 31314 \
    --eth-rpc-url https://ethereum-hoodi-rpc.publicnode.com \
    --eth-backup-rpc-url https://0xrpc.io/hoodi \
    --drosera-address 0x91cB447BaFc6e0EA0F4Fe056F5a9b1F14bb06e5D \
    --eth-private-key $PRIVATE \
    --listen-address 0.0.0.0 \
    --network-external-p2p-address $(curl -4 -s ifconfig.me) \
    --disable-dnr-confirmation true

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable drosera
sudo systemctl start drosera
