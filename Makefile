.PHONY: test compile build install

include .env

install:
	forge install smartcontractkit/chainlink-brownie-contracts
	forge remappings > remappings.txt
	
compile :; forge compile 

build:
	forge build 

test :; forge test 

