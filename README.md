# Sprinkle Contracts

Smart contracts powering the Sprinkle platform — deployed on [Robinhood Chain](https://robinhoodchain.blockscout.com) (Chain ID 4663).

## Contracts

### SprinkleCredits (`cSPRINK`)
ERC-20 credit token used for on-chain billing. Users purchase credits and the platform deducts them per API call.

- **Mainnet:** [`0xEc7d54eF36dA5cbdf5249Ba30683259009eb69ed`](https://robinhoodchain.blockscout.com/address/0xEc7d54eF36dA5cbdf5249Ba30683259009eb69ed)
- **Verified:** [Sourcify](https://sourcify.dev/#/lookup/0xEc7d54eF36dA5cbdf5249Ba30683259009eb69ed)

### SprinkleDataRegistry
On-chain registry mapping public keys and user metadata for the relay network.

- **Mainnet (current):** [`0xB32fcAFaD834a9Ef952A2108be0EFFA62B99F582`](https://robinhoodchain.blockscout.com/address/0xB32fcAFaD834a9Ef952A2108be0EFFA62B99F582)
- **Mainnet (legacy):** [`0xD78998ae7467Fd34dB8ea9a108e1DE6Dc8A4aCE3`](https://robinhoodchain.blockscout.com/address/0xD78998ae7467Fd34dB8ea9a108e1DE6Dc8A4aCE3)
- **Verified:** [Sourcify](https://sourcify.dev/#/lookup/0xB32fcAFaD834a9Ef952A2108be0EFFA62B99F582)

### SprinklePayments
ETH payment receiver — collects funds and sweeps to treasury.

- **Status:** Not yet deployed

## Chain

| Property | Value |
|---|---|
| Chain ID | 4663 |
| RPC | `https://rpc.mainnet.chain.robinhood.com` |
| Explorer | `https://robinhoodchain.blockscout.com` |

## Compiler

| Property | Value |
|---|---|
| Solidity | `0.8.36+commit.8a079791` |
| EVM Version | `cancun` |
| Optimizer | disabled |

## Deploying

```bash
export DEPLOYER_PRIVATE_KEY=0x...
export BACKEND_SIGNER_KEY=0x...
export TREASURY_ADDRESS=0x...
npx tsx scripts/deploy.ts
```

## License

MIT
