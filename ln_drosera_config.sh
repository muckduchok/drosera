PRIVATE=$(cat drosera_private.txt)
PUBLIC=$(cat drosera_public.txt)
RPC=$(cat drosera_rpc2.txt)

curl -L https://app.drosera.io/install | bash
source ~/.bashrc
$HOME/.drosera/bin/droseraup

cd my-drosera-trap
ROLE=$(sed -n 's/.*path[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' "drosera.toml" | head -n1) 

if [ "$RPC" = "{@custom_rpc2}" ]; then
  RPC=""
fi

$HOME/.drosera/bin/drosera dryrun
grep -Eq '^[[:space:]]*private_trap[[:space:]]*=' drosera.toml \
  || echo 'private_trap = true' >> drosera.toml
sed -i "s/^whitelist = \[\]/whitelist = [\"$PUBLIC\"]/" drosera.toml
export DROSERA_PRIVATE_KEY=$PRIVATE
sed -i 's|drosera_rpc = ".*"|drosera_rpc = "https://relay.testnet.drosera.io"|' drosera.toml
sed -i 's|eth_chain_id = .*|eth_chain_id = 17000|' drosera.toml
sed -i 's|drosera_address = ".*"|drosera_address = "0xea08f7d533C2b9A62F40D5326214f39a8E3A32F8"|' drosera.toml
sed -i 's|response_contract = ".*"|drosera_address = "0xdA890040Af0533D98B9F5f8FE3537720ABf83B0C"|' drosera.toml
grep -q '^drosera_team' $HOME/my-drosera-trap/drosera.toml || sed -i 's|^drosera_rpc.*|drosera_team = "https://relay.testnet.drosera.io/"|' $HOME/my-drosera-trap/drosera.toml

if [ -n "${RPC//[[:space:]]/}" ]; then
    sed -i "s#^ethereum_rpc = \".*\"#ethereum_rpc = \"$RPC\"#" drosera.toml
else
  sed -i 's|ethereum_rpc = ".*"|ethereum_rpc = "https://ethereum-holesky-rpc.publicnode.com/"|' drosera.toml
fi

if [ "$ROLE" = "out/Trap.sol/Trap.json" ]; then
  sed -i 's|^response_contract = ".*"|response_contract = "0x4608Afa7f277C8E0BE232232265850d1cDeB600E"|' drosera.toml
  sed -i 's|^response_function = ".*"|response_function = "respondWithDiscordName(string)"|' drosera.toml
fi

echo ofc | $HOME/.drosera/bin/drosera apply | tee drosera_ln.log | grep 'address:' > address_line.txt

cd ..

rm drosera-operator-v1.16.2-x86_64-unknown-linux-gnu.tar.gz
rm drosera-operator-v1.17.1-x86_64-unknown-linux-gnu.tar.gz
rm drosera-operator-v1.17.2-x86_64-unknown-linux-gnu.tar.gz
rm /usr/bin/drosera-operator
curl -LO https://github.com/drosera-network/releases/releases/download/v1.19.0/drosera-operator-v1.19.0-x86_64-unknown-linux-gnu.tar.gz
tar -xvf drosera-operator-v1.19.0-x86_64-unknown-linux-gnu.tar.gz
sudo cp drosera-operator /usr/bin
docker pull ghcr.io/drosera-network/drosera-operator:latest
drosera-operator register --eth-rpc-url https://ethereum-holesky-rpc.publicnode.com --eth-private-key $PRIVATE

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
    --eth-rpc-url https://ethereum-holesky-rpc.publicnode.com \
    --eth-backup-rpc-url https://1rpc.io/holesky \
    --drosera-address 0xea08f7d533C2b9A62F40D5326214f39a8E3A32F8 \
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
