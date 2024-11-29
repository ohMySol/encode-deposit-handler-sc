-include .env

.PHONY: all test clean deploy fund help install snapshot format anvil

DEFAULT_ANVIL_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

all: clean remove install update build test

# Clean the repo
clean:; forge clean

# Remove modules
remove:; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

install:; forge install foundry-rs/forge-std --no-commit && forge install OpenZeppelin/openzeppelin-contracts --no-commit

# Update Dependencies
update:; forge update

build:; forge build

# Run all tests locally
test:; forge test

# At the moment once you deploy with make file locally the anvil process won't be attached to terminal,
# but the process will be still running, so this command helps to finish Anvil process.
kill-anvil:
	@ANVIL_PID=$$(lsof -t -i:8545); \
	if [ -n "$$ANVIL_PID" ]; then \
		echo "Killing Anvil process on port 8545 (PID: $$ANVIL_PID)"; \
		kill -9 $$ANVIL_PID; \
	else \
		echo "No Anvil process found on port 8545."; \
	fi

# Deploy BootcampFactory, DepositHandler or DepositTokenMock to different networks(localhost(Anvil), Tenderly virtual network, Polygon Amoy).
# Request example: make deploy CONTRACT_NAME="DepositTokenMock" ARGS="pol_fork_mainnet". This will deploy to tenderly virtual network.
deploy: \
	# checking if contract name argument is provided or no.
	@if [ -z "$(CONTRACT_NAME)" ]; then \
		echo "No CONTRACT_NAME provided. Please specify the contract to deploy."; \
		exit 1; \
	fi; \
	CONTRACT_SCRIPT="script/deploy/Deploy$(CONTRACT_NAME).s.sol:Deploy$(CONTRACT_NAME)Script"; \
	if [ ! -f $$(echo $$CONTRACT_SCRIPT | cut -d':' -f1) ]; then \
		echo "Deployment script not found: $$CONTRACT_SCRIPT"; \
		exit 1; \
	fi; \
	if [ -z "$(ARGS)" ]; then \
       echo "No ARGS provided. Defaulting to Anvil network."; \
       ANVIL_PID=$$(lsof -t -i :8545); \
       if [ ! -z "$$ANVIL_PID" ]; then \
           echo "Killing existing Anvil process on port 8545 (PID: $$ANVIL_PID)."; \
           kill -9 $$ANVIL_PID; \
           sleep 2; \
		   echo "Starting a new Anvil instance..."; \
		   anvil & \
           echo "Waiting for Anvil to start..."; \
           sleep 2; \
           NETWORK_ARGS="--rpc-url http://localhost:8545 --private-key $(DEFAULT_ANVIL_KEY) --broadcast"; \
       else \
           echo "No Anvil process found on port 8545."; \
           anvil & \
           echo "Waiting for Anvil to start..."; \
           sleep 2; \
           NETWORK_ARGS="--rpc-url http://localhost:8545 --private-key $(DEFAULT_ANVIL_KEY) --broadcast"; \
       fi \
	elif echo $(ARGS) | grep -q -- "pol_fork_mainnet"; then \
		echo "Deploying to Tenderly Virtual Network."; \
		NETWORK_ARGS="--rpc-url $(TN_FORK_POL_MAINNET_RPC_URL) --private-key $(TN_FORK_POL_MAINNET_ADMIN_PK) --etherscan-api-key $(TENDERLY_ACCESS_KEY) --broadcast --verify"; \
   	elif echo $(ARGS) | grep -q -- "amoy"; then \
		echo "Deploying to AMOY Test Network."; \
		NETWORK_ARGS="--rpc-url $(AMOY_RPC_URL) --private-key $(AMOY_ADMIN_PK) --etherscan-api-key $(AMOY_API_KEY) --broadcast --verify"; \
	else \
		echo "Unknown network in ARGS."; \
		exit 1; \
   	fi; \
	echo "Deploying $(CONTRACT_NAME) with args: $$NETWORK_ARGS"; \
	forge script $$CONTRACT_SCRIPT $$NETWORK_ARGS