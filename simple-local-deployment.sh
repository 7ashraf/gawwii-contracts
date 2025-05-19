#!/bin/bash
set -e

# Start Anvil in the background
anvil &
ANVIL_PID=$!
echo "Started Anvil (PID: $ANVIL_PID)"

# Wait for Anvil to initialize
sleep 2  # Increased wait time

# Private key WITHOUT 0x prefix for Foundry
PRIVATE_KEY="ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
RPC_URL="http://127.0.0.1:8545"
FROM_ADDRESS="0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"  # Default first Anvil account
TO_ADDRESS="0xe222cF5C3809dDB589806EBe698196131dD38AA4"  # Your target transfer address

# Generate test data
HASHED_INFO=$(cast keccak "0x$(printf 'random user info' | xxd -p -c 1000000)")
NEW_HASHED_INFO=$(cast keccak "0x$(printf 'new user info' | xxd -p -c 1000000)")

# Deploy TicketFactory
echo "Deploying TicketFactory..."
TICKET_FACTORY_ADDRESS=$(forge create ./src/TicketFactory.sol:TicketFactory \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY \
  | grep "Deployed to:" | awk '{print $3}')

echo "TicketFactory deployed to: $TICKET_FACTORY_ADDRESS"

# Deploy Marketplace with TicketFactory address
echo "Deploying Marketplace..."
MARKETPLACE_ADDRESS=$(forge create ./src/Marketplace.sol:Marketplace \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY \
  | grep "Deployed to:" | awk '{print $3}')

echo "Marketplace deployed to: $MARKETPLACE_ADDRESS"

echo "Initializing Marketplace..."
cast send $MARKETPLACE_ADDRESS \
  "initialize(address)" \
  $TICKET_FACTORY_ADDRESS \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY

echo "Marketplace initialized with TicketFactory: $TICKET_FACTORY_ADDRESS"


# Call purchaseExternalTicket with sample data
echo "Calling purchaseExternalTicket..."
echo "Minting new ticket..."
TX_HASH=$(cast send $TICKET_FACTORY_ADDRESS \
  "purchaseExternalTicket(string,string,string,string,string,uint256,bytes32,address)" \
  "AA123" \
  "JFK" \
  "LAX" \
  "2023-10-01T12:00:00" \
  "2023-10-01T15:00:00" \
  100 \
  "$HASHED_INFO" \
  "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266" \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY \
  --value 0.1ether \
  | grep "transactionHash" | awk '{print $2}')

  echo "Mint transaction hash: $TX_HASH"

# Transfer the ticket
echo "Transferring ticket to $TO_ADDRESS..."
cast send $TICKET_FACTORY_ADDRESS \
  "transferTicket(address,uint256,address,bytes32)" \
  $FROM_ADDRESS \
  "0" \
  $TO_ADDRESS \
  $NEW_HASHED_INFO \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY

echo "Ticket transferred successfully"

# Verify ownership - FIXED VERSION
echo "Verifying new owner..."
RAW_OWNER_OUTPUT=$(cast call $TICKET_FACTORY_ADDRESS \
  "ownerOf(uint256)" \
  "0" \
  --rpc-url $RPC_URL)

# Print the raw output
echo "Raw owner output: $RAW_OWNER_OUTPUT"

# Check if the output is empty
if [ -z "$RAW_OWNER_OUTPUT" ]; then
  echo "✗ No owner found for ticket ID 0"
  exit 1
fi

# Check if the output is a valid 32-byte hex string (which contains an address)
if ! [[ "$RAW_OWNER_OUTPUT" =~ ^0x[a-fA-F0-9]{64}$ ]]; then
  echo "✗ Invalid hex format: $RAW_OWNER_OUTPUT"
  exit 1
fi

# Extract address from the 32-byte hex string (last 20 bytes = last 40 hex chars)
# Remove the 0x prefix, take the last 40 characters, and add 0x back
DETECTED_OWNER="0x${RAW_OWNER_OUTPUT: -40}"

# Verify the conversion worked
if ! [[ "$DETECTED_OWNER" =~ ^0x[a-fA-F0-9]{40}$ ]]; then
  echo "✗ Address extraction failed: $DETECTED_OWNER"
  exit 1
fi

# Compare addresses (case-insensitive)
if [ "${DETECTED_OWNER,,}" = "${TO_ADDRESS,,}" ]; then
  echo "✓ Ownership verified: $DETECTED_OWNER"
else
  echo "✗ Ownership mismatch!"
  echo "Expected: $TO_ADDRESS"
  echo "Got: $DETECTED_OWNER"
  exit 1
fi

# Clean up
# kill $ANVIL_PID
# echo "Stopped Anvil"