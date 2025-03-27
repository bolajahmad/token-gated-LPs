# Token-Gated Liquidity Pools

## Overview

This project implements a token-gated liquidity pool system using Uniswap V4 hooks. It allows only DAO members (NFT holders) to provide liquidity to a specific liquidity pool.

### Components

1. **TokenGatingNFT (`TGNft.sol`)**: Non-transferable NFT representing DAO membership
2. **CustomC20 (`CR20.sol`)**: DAO governance token with special minting privileges for members
3. **GatedLPHook (`GatedLPHook.sol`)**: Uniswap V4 hook that verifies NFT ownership before allowing liquidity provision
4. **CreatePool (`CreateLP.sol`)**: Utility contract to create and initialize the token-gated liquidity pool

## Architecture

- **DAO Membership**: Users mint a non-transferable NFT to become DAO members
- **Token Economy**: Members can mint the DAO token using ETH or receive free tokens (once per address)
- **LP Gating**: Only NFT holders can provide liquidity to the DAO's liquidity pool
- **Pool Creation**: The system creates a ETH/DAO Token liquidity pool with token-gating features

```
┌──────────────┐           ┌──────────────┐
│  DAO Member  │◄────────►│  TokenGating  │
│  (NFT Owner) │           │     NFT      │
└──────────────┘           └──────────────┘
        ▲                          ▲
        │                          │
        │                          │
        ▼                          ▼
┌──────────────┐           ┌──────────────┐
│  CustomC20   │◄────────►│  GatedLPHook  │
│  DAO Token   │           │ (Uniswap V4) │
└──────────────┘           └──────────────┘
        ▲                          ▲
        │                          │
        │                          │
        ▼                          ▼
┌──────────────┐           ┌──────────────┐
│   ETH/DAO    │◄────────►│  CreatePool   │
│ Liquidity Pool│           │  (Factory)   │
└──────────────┘           └──────────────┘
```

## Key Features

- **Non-transferable NFTs**: DAO membership NFTs cannot be transferred, sold or burned
- **Free Token Minting**: DAO members get a one-time free token allocation
- **Token-Gated Liquidity**: Only members can provide liquidity
- **Price Control**: DAO governance can adjust minting prices
- **Error Handling**: Robust error handling and event emission throughout the system

## Getting Started

### Prerequisites

- Foundry (Forge, Cast, Anvil)
- Access to Ethereum Sepolia testnet or a compatible network
- Some ETH for deployment

### Installation

1. Clone the repository
```bash
git clone https://github.com/yourusername/token-gated-LPs.git
cd token-gated-LPs
forge install
```

2. Set up environment variables
```bash
export PRIVATE_KEY=<your-private-key>
export RPC_URL=<your-rpc-url>
```

### Deployment

```bash
forge script script/Deploy.sol --rpc-url $RPC_URL --broadcast
```

### Usage Flow

1. User mints a DAO membership NFT
2. User can then claim free DAO tokens
3. User can provide liquidity to the gated ETH/DAO token pool
4. User can participate in DAO governance

## Testing

Run the test suite:

```bash
forge test
```

## Security Considerations

- The contracts require administrative control for initial setup
- Access control is implemented using OpenZeppelin's Ownable
- Non-transferable NFTs prevent token-gating bypasses
- Error handling prevents unintended state changes

## License

This project is licensed under the UNLICENSED license.

# Token-Gated Liquidity Pool Deployment

This project creates a token-gated Uniswap V4 liquidity pool, where only members who own a specific NFT can add liquidity.

## Deployment Instructions

### Prerequisites

1. Install Foundry: https://book.getfoundry.sh/getting-started/installation
2. Clone this repository
3. Run `forge install` to install dependencies

### Required Environment Variables

Create a `.env` file with the following variables:

```
PRIVATE_KEY=your_private_key
TOKEN_ADDRESS=address_of_your_token
MEMBERSHIP_NFT_ADDRESS=address_of_your_membership_nft
ADMIN_ADDRESS=address_of_admin_account
```

### Deployment Steps

1. Load environment variables:
   ```bash
   source .env
   ```

2. Deploy contracts to Sepolia testnet:
   ```bash
   forge script script/DeployCreatLP.s.sol:DeployCreatLPScript --rpc-url https://sepolia.infura.io/v3/YOUR_INFURA_KEY --broadcast --verify
   ```

3. After deployment, you'll get the addresses for `GatedLPHook` and `CreatePool` contracts.

4. To create the pool, call the `createPool()` function on the deployed `CreatePool` contract:
   ```bash
   cast send ADDRESS_OF_CREATE_POOL "createPool()" --private-key $PRIVATE_KEY --rpc-url https://sepolia.infura.io/v3/YOUR_INFURA_KEY
   ```

### Pool Parameters

The default pool parameters are:
- LP Fee: 0.5% (5000)
- Starting Price: 0.5 ETH/TOKEN

You can update these parameters before pool creation by calling:
```bash
cast send ADDRESS_OF_CREATE_POOL "updatePoolParameters(uint24,uint160)" NEW_FEE NEW_STARTING_PRICE --private-key $PRIVATE_KEY --rpc-url https://sepolia.infura.io/v3/YOUR_INFURA_KEY
```

## Contract Overview

- `CreatePool.sol`: Main contract that creates the Uniswap V4 pool
- `GatedLPHook.sol`: Hook contract that enforces the NFT ownership requirement for LP providers
