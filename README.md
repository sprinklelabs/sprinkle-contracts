# Sprinkle Contracts

Smart contracts powering the Sprinkle platform, deployed on [Robinhood Chain](https://robinhoodchain.blockscout.com) (Chain ID 4663).

## Contracts

### SprinkleCredits (cSPRINK)
ERC-20 credit token used for on-chain billing. Users purchase credits and the platform deducts them per API call.

- **Mainnet:** [`0xEc7d54eF36dA5cbdf5249Ba30683259009eb69ed`](https://robinhoodchain.blockscout.com/address/0xEc7d54eF36dA5cbdf5249Ba30683259009eb69ed)
- **Verified:** [Sourcify](https://sourcify.dev/#/lookup/0xEc7d54eF36dA5cbdf5249Ba30683259009eb69ed)

### SprinkleDataRegistry
On-chain registry that anchors keccak256 hashes of messages, files, and tasks. Content stays in the private database; the hash on-chain is the immutable proof of existence.

- **Mainnet:** [`0xB32fcAFaD834a9Ef952A2108be0EFFA62B99F582`](https://robinhoodchain.blockscout.com/address/0xB32fcAFaD834a9Ef952A2108be0EFFA62B99F582)
- **Verified:** [Sourcify](https://sourcify.dev/#/lookup/0xB32fcAFaD834a9Ef952A2108be0EFFA62B99F582)

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
