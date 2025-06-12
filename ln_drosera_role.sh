PUBLIC=$(cat drosera_public.txt)
PRIVATE=$(cat drosera_private.txt)
DISCORD=$(cat drosera_discord.txt)

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
    address public constant RESPONSE_CONTRACT = 0x4608Afa7f277C8E0BE232232265850d1cDeB600E;
    string constant discordName = "$DISCORD"; // add your discord name here

    function collect() external view returns (bytes memory) {
        bool active = IMockResponse(RESPONSE_CONTRACT).isActive();
        return abi.encode(active, discordName);
    }

    function shouldRespond(bytes[] calldata data) external pure returns (bool, bytes memory) {
        // take the latest block data from collect
        (bool active, string memory name) = abi.decode(data[0], (bool, string));
        // will not run if the contract is not active or the discord name is not set
        if (!active || bytes(name).length == 0) {
            return (false, bytes(""));
        }

        return (true, abi.encode(name));
    }
}
EOF

sed -i 's|^path = "out/HelloWorldTrap\.sol/HelloWorldTrap\.json"|path = "out/Trap.sol/Trap.json"|' drosera.toml
sed -i 's|^response_contract = "0xdA890040Af0533D98B9F5f8FE3537720ABf83B0C"|response_contract = "0x4608Afa7f277C8E0BE232232265850d1cDeB600E"|' drosera.toml
sed -i 's|^response_function = "helloworld(string)"|response_function = "respondWithDiscordName(string)"|' drosera.toml

$HOME/.foundry/bin/forge build
$HOME/.drosera/bin/drosera dryrun
export DROSERA_PRIVATE_KEY=$PRIVATE
echo ofc | $HOME/.drosera/bin/drosera apply

source /root/.bashrc
$HOME/.foundry/bin/cast call 0x4608Afa7f277C8E0BE232232265850d1cDeB600E "isResponder(address)(bool)" $PUBLIC --rpc-url https://ethereum-holesky-rpc.publicnode.com

sudo systemctl daemon-reload
sudo systemctl enable drosera
sudo systemctl start drosera
