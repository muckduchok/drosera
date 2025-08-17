PUBLIC=$(cat drosera_public.txt)
PRIVATE=$(cat drosera_private.txt)
DISCORD=$(cat drosera_discord.txt)
RPC=$(cat drosera_rpc.txt)

sudo systemctl daemon-reload
sudo systemctl stop drosera

cd $HOME/my-drosera-trap

sudo tee $HOME/my-drosera-trap/src/Trap.sol > /dev/null <<EOF
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ITrap} from "drosera-contracts/interfaces/ITrap.sol";

interface IMockResponse {
    function isActive() external view returns (bool);
}

contract Trap is ITrap {
    // Updated response contract address
    address public constant RESPONSE_CONTRACT = 0x25E2CeF36020A736CF8a4D2cAdD2EBE3940F4608;
    string constant discordName = "DISCORD_USERNAME"; // Replace with your Discord username

    function collect() external view returns (bytes memory) {
        bool active = IMockResponse(RESPONSE_CONTRACT).isActive();
        return abi.encode(active, discordName);
    }

    function shouldRespond(bytes[] calldata data) external pure returns (bool, bytes memory) {
        (bool active, string memory name) = abi.decode(data[0], (bool, string));
        if (!active || bytes(name).length == 0) {
            return (false, bytes(""));
        }

        return (true, abi.encode(name));
    }
}
EOF

sed -i 's|^path = "out/HelloWorldTrap\.sol/HelloWorldTrap\.json"|path = "out/Trap.sol/Trap.json"|' drosera.toml
sed -i 's|^response_contract = ".*"|response_contract = "0x25E2CeF36020A736CF8a4D2cAdD2EBE3940F4608"|' drosera.toml
sed -i 's|^response_function = ".*"|response_function = "respondWithDiscordName(string)"|' drosera.toml

$HOME/.foundry/bin/forge build
$HOME/.drosera/bin/drosera dryrun
export DROSERA_PRIVATE_KEY=$PRIVATE
echo ofc | $HOME/.drosera/bin/drosera apply

source /root/.bashrc

if [ -n "${RPC//[[:space:]]/}" ]; then
    $HOME/.foundry/bin/cast call 0x25E2CeF36020A736CF8a4D2cAdD2EBE3940F4608 "isResponder(address)(bool)" $PUBLIC --rpc-url $RPC
else
  $HOME/.foundry/bin/cast call 0x25E2CeF36020A736CF8a4D2cAdD2EBE3940F4608 "isResponder(address)(bool)" $PUBLIC --rpc-url https://rpc.hoodi.ethpandaops.io
fi

sudo systemctl daemon-reload
sudo systemctl enable drosera
sudo systemctl start drosera
