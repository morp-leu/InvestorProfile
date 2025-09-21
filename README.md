# InvestorProfile

InvestorProfile is an address reputation system smart contract for investor behavior and portfolio performance scoring on the Stacks blockchain. This contract enables tracking of investor profiles, portfolio performance metrics, and calculates dynamic reputation scores based on investment success rates and other factors.

## Features

- **Investor Registration**: Users can register investor profiles with comprehensive tracking capabilities
- **Investment Recording**: Track individual investments with amounts, types, and timestamps
- **Performance Monitoring**: Record investment outcomes and calculate ROI percentages
- **Reputation Scoring**: Dynamic reputation calculation based on multiple weighted factors
- **Verification System**: Contract owner can verify trusted investors for reputation bonuses
- **Ranking System**: Six-tier ranking system from Beginner to Elite based on reputation scores
- **Flexible Scoring Weights**: Configurable weight system for reputation calculation factors
- **Investment History**: Complete audit trail of all investor activities

## Technical Specifications

- **Blockchain**: Stacks
- **Language**: Clarity v2
- **Epoch**: 2.5
- **Contract Name**: InvestorProfile
- **Version**: 1.0.0

### Data Structures

The contract maintains three primary data maps:

1. **investor-profiles**: Core profile data including investments, success rates, and reputation scores
2. **investment-history**: Detailed record of individual investments and their outcomes
3. **investment-counters**: Tracking mechanism for investment IDs per investor

### Reputation Scoring Algorithm

Reputation scores are calculated using four weighted factors:
- **Success Rate Weight** (default: 40%): Based on successful vs failed investments
- **Portfolio Value Weight** (default: 30%): Based on total portfolio value (capped at 1M for scoring)
- **Experience Weight** (default: 20%): Based on number of investments (capped at 100 for scoring)
- **Verification Weight** (default: 10%): Bonus for verified investors

## Installation

### Prerequisites

- [Clarinet](https://docs.hiro.so/clarinet) installed
- Node.js (for optional tooling)
- Stacks CLI (for deployment)

### Setup

1. Clone the repository:
```bash
git clone <repository-url>
cd InvestorProfile
```

2. Navigate to the contract directory:
```bash
cd InvestorProfile_contract
```

3. Install dependencies (if using additional tooling):
```bash
npm install
```

4. Test the contract:
```bash
clarinet test
```

## Usage Examples

### Register as an Investor

```clarity
;; Register a new investor profile
(contract-call? .InvestorProfile register-investor)
```

### Record an Investment

```clarity
;; Record a new investment of 1000 STX in "DeFi Protocol"
(contract-call? .InvestorProfile record-investment u1000 "DeFi Protocol")
```

### Update Investment Outcome

```clarity
;; Mark investment ID 1 as successful with 25% ROI
(contract-call? .InvestorProfile update-investment-outcome u1 true 25)
```

### Get Investor Profile

```clarity
;; Get profile for a specific investor
(contract-call? .InvestorProfile get-investor-profile 'SP1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE)
```

### Check Investor Rank

```clarity
;; Get investor ranking (Beginner, Novice, Intermediate, Advanced, Expert, Elite)
(contract-call? .InvestorProfile get-investor-rank 'SP1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE)
```

## Contract Functions Documentation

### Public Functions

#### `register-investor`
Registers a new investor profile for the transaction sender.
- **Returns**: `(response bool uint)`
- **Errors**: `ERR-PROFILE-ALREADY-EXISTS` if profile already exists

#### `record-investment (amount uint) (investment-type (string-ascii 50))`
Records a new investment for the caller.
- **Parameters**:
  - `amount`: Investment amount (must be > 0)
  - `investment-type`: Description of investment type (max 50 characters)
- **Returns**: `(response bool uint)`
- **Errors**: `ERR-INVALID-AMOUNT`, `ERR-PROFILE-NOT-FOUND`

#### `update-investment-outcome (investment-id uint) (success bool) (roi-percentage int)`
Updates the outcome of a previously recorded investment.
- **Parameters**:
  - `investment-id`: ID of the investment to update
  - `success`: Whether the investment was successful
  - `roi-percentage`: Return on investment as percentage (can be negative)
- **Returns**: `(response bool uint)`
- **Errors**: `ERR-PROFILE-NOT-FOUND`

#### `verify-investor (investor principal)` (Owner Only)
Verifies an investor, providing reputation score bonus.
- **Parameters**:
  - `investor`: Principal address of investor to verify
- **Returns**: `(response bool uint)`
- **Errors**: `ERR-NOT-AUTHORIZED`, `ERR-PROFILE-NOT-FOUND`

#### `update-score-weights (new-success-weight uint) (new-portfolio-weight uint) (new-experience-weight uint) (new-verification-weight uint)` (Owner Only)
Updates the weights used in reputation score calculation.
- **Parameters**: Four weight values that must sum to 100
- **Returns**: `(response bool uint)`
- **Errors**: `ERR-NOT-AUTHORIZED`, `ERR-INVALID-SCORE`

### Read-Only Functions

#### `get-investor-profile (investor principal)`
Returns complete investor profile data.

#### `get-investment (investor principal) (investment-id uint)`
Returns details of a specific investment.

#### `get-investment-count (investor principal)`
Returns total number of investments for an investor.

#### `get-success-rate (investor principal)`
Returns success rate percentage for an investor.

#### `get-score-weights`
Returns current reputation scoring weights.

#### `get-total-investors`
Returns total number of registered investors.

#### `get-investor-rank (investor principal)`
Returns investor rank based on reputation score.

### Error Constants

- `ERR-NOT-AUTHORIZED (u1)`: Caller not authorized for action
- `ERR-PROFILE-NOT-FOUND (u2)`: Investor profile doesn't exist
- `ERR-INVALID-AMOUNT (u3)`: Invalid investment amount
- `ERR-INVALID-SCORE (u4)`: Invalid score or weight values
- `ERR-PROFILE-ALREADY-EXISTS (u5)`: Profile already registered

## Deployment Guide

### Testnet Deployment

1. Configure testnet settings in `settings/Testnet.toml`
2. Deploy using Clarinet:
```bash
clarinet deploy --testnet
```

### Mainnet Deployment

1. Configure mainnet settings in `settings/Mainnet.toml`
2. Ensure thorough testing on testnet
3. Deploy using Clarinet:
```bash
clarinet deploy --mainnet
```

### Post-Deployment Setup

1. Verify contract deployment
2. Configure initial scoring weights if needed
3. Begin investor registration process

## Security Notes

### Access Controls
- Only the contract owner can verify investors
- Only the contract owner can update scoring weights
- Investment outcomes can only be updated by the investment owner

### Data Validation
- Investment amounts must be greater than zero
- Scoring weights must sum to exactly 100
- Profiles cannot be registered twice for the same address

### Best Practices
- Investors should regularly update investment outcomes for accurate reputation scoring
- Contract owner should verify investors only after proper due diligence
- Monitor reputation score calculations for fairness and accuracy

### Limitations
- Portfolio values are capped at 1M STX for scoring purposes
- Investment count is capped at 100 for experience scoring
- ROI percentages are stored as integers (no decimal precision)

## Ranking System

The contract implements a six-tier ranking system based on reputation scores:

- **Elite**: 90-100 points
- **Expert**: 75-89 points
- **Advanced**: 60-74 points
- **Intermediate**: 40-59 points
- **Novice**: 20-39 points
- **Beginner**: 0-19 points

## License

This project is part of a smart contract development initiative. Please review and comply with applicable licensing terms before use in production environments.