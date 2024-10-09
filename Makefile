-include .env

.PHONY: all test clean deploy

update:; forge update

build:; forge build

test :; forge test 

format :; forge fmt


NETWORK_ARGS := --rpc-url http://localhost:8545 --private-key $(DEFAULT_ANVIL_KEY) --broadcast

deploy-base-sepolia:
	@forge script script/DeployAirplaneNft.s.sol:DeployAirplaneNft --rpc-url $(BASE_SEPOLIA_RPC_URL) --account deployer --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv