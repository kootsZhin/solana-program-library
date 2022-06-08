#!/usr/bin/env bash
#
# deploy the token lending program on devnet
#



echo "Running deploy script...";

MARKET_OWNER=$1
PROGRAM_ID=$2

if [[ -z $PROGRAM_ID ]]; then
  echo "Usage: $0 <owner-addr> <program-addr>"
  exit 1
fi

cargo build
cargo build-bpf

OWNER="owner.json"
PROGRAM="lending.json"
NETWORK="https://api.devnet.solana.com"
bold=$(tput bold)
normal=$(tput sgr0)

SOL_CONFIG_OUTPUT=$(solana config set --url $NETWORK --keypair owner.json); # deploying on devnet

solana airdrop 2 $MARKET_OWNER;
solana airdrop 2 $MARKET_OWNER;
solana airdrop 2 $MARKET_OWNER;
solana airdrop 2 $MARKET_OWNER;
solana airdrop 2 $MARKET_OWNER;
solana airdrop 2 $MARKET_OWNER;
solana airdrop 2 $MARKET_OWNER;
solana airdrop 2 $MARKET_OWNER;
solana airdrop 2 $MARKET_OWNER;
solana airdrop 2 $MARKET_OWNER;

echo -e "\nDeploying program...\n";
solana program deploy \
  -k $OWNER \
  --program-id $PROGRAM \
  target/deploy/spl_token_lending.so;


echo -e "\nCreating lending market...\n";
MARKET_OUTPUT=$(spl-token-lending \
  --program      $PROGRAM_ID \
  --fee-payer    $OWNER \
  create-market \
  --market-owner $MARKET_OWNER);
MARKET_ADDR=$(echo "$MARKET_OUTPUT" | grep "market" | cut -d ' ' -f 4);


echo -e "\nCreating SOL Reserve...\n";

WRAP_OUTPUT=$(spl-token wrap --fee-payer $OWNER 0.1 -- $OWNER);
SOURCE=$(echo "$WRAP_OUTPUT" | grep "into" | cut -d ' ' -f 5);

# TODO: add parameters
SOL_RESERVE_OUTPUT=$(spl-token-lending \
  --program           $PROGRAM_ID \
  --fee-payer         $OWNER \
  add-reserve \
  --market-owner      $OWNER \
  --source-owner      $OWNER \
  --market            $MARKET_ADDR \
  --source            $SOURCE \
  --amount            0.05  \
  --pyth-product      3Mnn2fX6rQyUsyELYms1sBJyChWofzSNRoqYzvgMVz5E \
  --pyth-price        J83w4HKfqxwcq3BEMMkPFSppX3gqekLyLJBexebFVkix \
  --verbose);

SOL_RESERVE_ADDER=$(echo "$SOL_RESERVE_OUTPUT" | grep "reserve" | cut -d ' ' -f 3);
SOL_RESERVE_COLLATERAL_MINT_ADDR=$(echo "$SOL_RESERVE_OUTPUT" | grep "Adding collateral mint" | cut -d ' ' -f 4);
SOL_RESERVE_COLLATERAL_SUPPLY_ADDR=$(echo "$SOL_RESERVE_OUTPUT" | grep "Adding collateral supply" | cut -d ' ' -f 4);
SOL_RESERVE_LIQUIDITY_ADDER=$(echo "$SOL_RESERVE_OUTPUT" | grep "Adding liquidity supply" | cut -d ' ' -f 4);
SOL_RESERVE_LIQUIDITY_FEE_RECEIVER_ADDER=$(echo "$SOL_RESERVE_OUTPUT" | grep "Adding liquidity fee receiver" | cut -d ' ' -f 5);


echo -e "\nCreating USDC Reserve...\n";

USDC_TOKEN_MINT=$(spl-token create-token --decimals 6)
USDC_ADDR=$(echo "$USDC_TOKEN_MINT" | grep "token" | cut -d ' ' -f 3);

USDC_TOKEN_ACC_OUTPUT=$(spl-token create-account $USDC_ADDR);
USDC_TOKEN_ACC=$(echo "$USDC_TOKEN_ACC_OUTPUT" | grep "account" | cut -d ' ' -f 3);

spl-token mint $USDC_ADDR 1000000000;

USDC_RESERVE_OUTPUT=$(spl-token-lending \
  --program           $PROGRAM_ID \
  --fee-payer         $OWNER \
  add-reserve \
  --market-owner      $OWNER \
  --source-owner      $OWNER \
  --market            $MARKET_ADDR \
  --source            $USDC_TOKEN_ACC \
  --amount            1.0  \
  --pyth-product      6NpdXrQEpmDZ3jZKmM2rhdmkd3H6QAk23j2x8bkXcHKA \
  --pyth-price        5SSkXsEKQepHHAewytPVwdej4epN1nxgLVM84L4KXgy7 \
  --verbose);

USDC_RESERVE_ADDER=$(echo "$USDC_RESERVE_OUTPUT" | grep "reserve" | cut -d ' ' -f 3);
USDC_RESERVE_COLLATERAL_MINT_ADDR=$(echo "$USDC_RESERVE_OUTPUT" | grep "Adding collateral mint" | cut -d ' ' -f 4);
USDC_RESERVE_COLLATERAL_SUPPLY_ADDR=$(echo "$USDC_RESERVE_OUTPUT" | grep "Adding collateral supply" | cut -d ' ' -f 4);
USDC_RESERVE_LIQUIDITY_ADDER=$(echo "$USDC_RESERVE_OUTPUT" | grep "Adding liquidity supply" | cut -d ' ' -f 4);
USDC_RESERVE_LIQUIDITY_FEE_RECEIVER_ADDER=$(echo "$USDC_RESERVE_OUTPUT" | grep "Adding liquidity fee receiver" | cut -d ' ' -f 5);


echo -e "${bold}\n\nDeveployment Results\n${normal}";
echo -e "${bold}Network:${normal} $NETWORK";
echo -e "${bold}Owner address:${normal} $MARKET_OWNER ($OWNER)"
echo -e "${bold}Program address:${normal} $PROGRAM_ID ($PROGRAM)"
echo -e "${bold}Lending market address:${normal} $MARKET_ADDR";
echo -e ""

echo -e "${bold}Wrapped SOL address${normal}: So11111111111111111111111111111111111111112";
echo -e "${bold}Decimals:${normal} 9"
echo -e "${bold}Source address:${normal} $SOURCE";
echo -e "${bold}Reserve address:${normal} $SOL_RESERVE_ADDER";
echo -e "${bold}Collateral mint address:${normal} $SOL_RESERVE_COLLATERAL_MINT_ADDR";
echo -e "${bold}Collateral supply address:${normal} $SOL_RESERVE_COLLATERAL_SUPPLY_ADDR";
echo -e "${bold}Liquidity address:${normal} $SOL_RESERVE_LIQUIDITY_ADDER";
echo -e "${bold}Liquidity fee receiver address:${normal} $SOL_RESERVE_LIQUIDITY_FEE_RECEIVER_ADDER";
echo -e ""

echo -e "${bold}USDC address:${normal} $USDC_ADDR";
echo -e "${bold}Decimals:${normal} 6"
echo -e "${bold}Source address:${normal} $USDC_TOKEN_ACC";
echo -e "${bold}Reserve address:${normal} $USDC_RESERVE_ADDER";
echo -e "${bold}Collateral mint address:${normal} $USDC_RESERVE_COLLATERAL_MINT_ADDR";
echo -e "${bold}Collateral supply address:${normal} $USDC_RESERVE_COLLATERAL_SUPPLY_ADDR";
echo -e "${bold}Liquidity address:${normal} $USDC_RESERVE_LIQUIDITY_ADDER";
echo -e "${bold}Liquidity fee receiver address:${normal} $USDC_RESERVE_LIQUIDITY_FEE_RECEIVER_ADDR";
echo -e ""