# Decentralized Loyalty and Rewards System

A decentralized, blockchain-based loyalty and rewards system built on the Stacks ecosystem. This platform allows businesses to manage loyalty programs and issue rewards, while users can accumulate and redeem loyalty points in a transparent, trustless manner.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Installation](#installation)
- [Smart Contracts](#smart-contracts)
- [Frontend Application](#frontend-application)
- [Authentication System](#authentication-system)
- [Testing](#testing)
- [Deployment](#deployment)
- [Contributing](#contributing)
- [License](#license)

---

## Overview

This project is a decentralized loyalty program where businesses can create loyalty schemes, reward customers, and track user engagement, all powered by the Stacks blockchain. By using smart contracts, we remove the need for intermediaries, and customers can access their points across participating businesses with full transparency and ownership of their rewards.

## Features

- **Decentralized Loyalty Program**: Businesses can issue loyalty points using smart contracts.
- **User Account and Balance Management**: Users can view their points and manage redemptions.
- **Business Dashboard**: Interface for businesses to manage their loyalty programs and monitor activity.
- **On-Chain Data**: All transactions and balances are handled directly on the Stacks blockchain.
- **Stack Authentication**: Users can log in and connect using Stacks wallets.
- **Trustless Reward System**: Users can redeem points across any registered business in the network.

## Tech Stack

- **Blockchain**: Stacks (powered by Bitcoin)
- **Smart Contracts**: Clarity (for Stacks)
- **Frontend**: React.js with Stacks.js for blockchain interaction
- **Authentication**: Stacks Authentication
- **Storage**: On-chain storage for critical data, with optional off-chain Gaia storage for larger datasets
- **Testing Framework**: Clarinet for smart contract testing

## Installation

### Prerequisites

- Node.js (v14 or above)
- npm or yarn
- Clarinet (for Clarity smart contract testing)
- Stacks Wallet (for development and testing)

### Setup

1. Clone the repository:
    ```bash
    git clone https://github.com/gboigwe/be-loyal-community.git
    cd loyalty-rewards-system
    ```

2. Install dependencies:
    ```bash
    npm install
    ```

3. Set up environment variables (e.g., API endpoints, Stacks testnet/mainnet info) by creating a `.env` file:
    ```bash
    touch .env
    ```

4. Run the frontend application:
    ```bash
    npm start
    ```

5. Set up Clarinet for testing smart contracts:
    ```bash
    clarinet check
    ```

## Smart Contracts

The smart contracts are written in Clarity and include:

1. **Main Loyalty Program Contract**: 
   - Handles the issuance and redemption of points.
   - Manages rules for loyalty programs.
   
2. **Business Registry Contract**:
   - Allows businesses to register and manage their loyalty programs.
   
3. **User Registry Contract**:
   - Manages user accounts and keeps track of their point balances.

Contracts are located in the `contracts/` directory. Run unit tests using:
```bash
clarinet test
