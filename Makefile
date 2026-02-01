.PHONY: test compile build install

include .env

install:
	forge install smartcontractkit/chainlink-brownie-contracts
	forge install Cyfrin/foundry-devops
	forge remappings > remappings.txt
	
compile :; forge compile 

build:
	forge build 

test :; forge test 

