#!/bin/bash
set -e

# Start Anvil in the background
anvil &
ANVIL_PID=$!
echo "Started Anvil (PID: $ANVIL_PID)"

# Wait for Anvil to initialize
sleep 3

# Deploy TicketFactory
echo "Deploying TicketFactory..."
TICKET_FACTORY_ADDRESS=$(forge create ./src/TicketFactory.sol:TicketFactory \
  --rpc-url http://127.0.0.1:8545 \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  | grep "Deployed to:" | awk '{print $3}')

echo "TicketFactory deployed to: $TICKET_FACTORY_ADDRESS"

# Deploy Marketplace with TicketFactory address
echo "Deploying Marketplace..."
MARKETPLACE_ADDRESS=$(forge create ./src/Marketplace.sol:Marketplace \
  --constructor-args "$TICKET_FACTORY_ADDRESS" "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266" 500 \
  --rpc-url http://127.0.0.1:8545 \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  | grep "Deployed to:" | awk '{print $3}')

echo "Marketplace deployed to: $MARKETPLACE_ADDRESS"

# Generate test data
HASHED_INFO=$(cast keccak "0x$(printf 'random user info' | xxd -p -c 1000000)")
TO_ADDRESS="0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"

# Call purchaseExternalTicket with sample data
echo "Calling purchaseExternalTicket..."
cast send "$TICKET_FACTORY_ADDRESS" \
  "purchaseExternalTicket(string,string,string,string,string,uint256,bytes32,address)" \
  "AA123" \
  "JFK" \
  "LAX" \
  "2023-10-01T12:00:00" \
  "2023-10-01T15:00:00" \
  100 \
  "$HASHED_INFO" \
  "$TO_ADDRESS" \
  --rpc-url http://127.0.0.1:8545 \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  --value 0.1ether

echo "Transaction completed successfully"

# Clean up
kill $ANVIL_PID
echo "Stopped Anvil"