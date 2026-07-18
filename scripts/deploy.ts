/**
 * Deploy SprinkleCredits + SprinkleDataRegistry to Robinhood Chain
 *
 * Usage:
 *   export DEPLOYER_PRIVATE_KEY=0x...
 *   export BACKEND_SIGNER_KEY=0x...     # derive address automatically
 *   export TREASURY_ADDRESS=0x...
 *   npx tsx contracts/deploy.ts
 *
 * After deploy, set:
 *   SPRINKLE_CREDITS_ADDRESS=<output>
 *   SPRINKLE_DATA_REGISTRY_ADDRESS=<output>
 */
import { ethers } from "ethers";
import { readFileSync } from "fs";
import { resolve } from "path";
// @ts-ignore
import solc from "solc";

const RHO_RPC = "https://rpc.mainnet.chain.robinhood.com";

function compile(filename: string, contractName: string) {
  const source = readFileSync(resolve(__dirname, filename), "utf8");
  const input = {
    language: "Solidity",
    sources: { [filename]: { content: source } },
    settings: { outputSelection: { "*": { "*": ["abi", "evm.bytecode.object"] } } },
  };
  const output = JSON.parse(solc.compile(JSON.stringify(input)));
  if (output.errors?.some((e: any) => e.severity === "error")) {
    console.error("Compilation errors:", output.errors);
    process.exit(1);
  }
  const c = output.contracts[filename][contractName];
  return { abi: c.abi, bytecode: "0x" + c.evm.bytecode.object };
}

async function main() {
  const deployerKey = process.env.DEPLOYER_PRIVATE_KEY;
  const backendKey  = process.env.BACKEND_SIGNER_KEY;
  const treasury    = process.env.TREASURY_ADDRESS;

  if (!deployerKey) throw new Error("DEPLOYER_PRIVATE_KEY required");
  if (!backendKey)  throw new Error("BACKEND_SIGNER_KEY required");
  if (!treasury)    throw new Error("TREASURY_ADDRESS required");

  // Derive backend signer address from key
  const backendSigner = new ethers.Wallet(backendKey).address;

  console.log("Backend signer address:", backendSigner);
  console.log("Treasury:", treasury);
  console.log("");

  const provider = new ethers.JsonRpcProvider(RHO_RPC);
  const wallet   = new ethers.Wallet(deployerKey, provider);

  console.log("Deployer:", wallet.address);
  const bal = await provider.getBalance(wallet.address);
  console.log("Balance:", ethers.formatEther(bal), "ETH\n");

  // ── 1. SprinkleCredits ───────────────────────────────────────────────────

  console.log("Compiling SprinkleCredits.sol...");
  const credits = compile("SprinkleCredits.sol", "SprinkleCredits");
  console.log("Deploying SprinkleCredits...");

  const creditsFactory  = new ethers.ContractFactory(credits.abi, credits.bytecode, wallet);
  const creditsDeployed = await creditsFactory.deploy(treasury, backendSigner);
  await creditsDeployed.waitForDeployment();
  const creditsAddress  = await creditsDeployed.getAddress();

  console.log("✅ SprinkleCredits deployed at:", creditsAddress);

  // ── 2. SprinkleDataRegistry ──────────────────────────────────────────────

  console.log("\nCompiling SprinkleDataRegistry.sol...");
  const registry = compile("SprinkleDataRegistry.sol", "SprinkleDataRegistry");
  console.log("Deploying SprinkleDataRegistry...");

  const registryFactory  = new ethers.ContractFactory(registry.abi, registry.bytecode, wallet);
  const registryDeployed = await registryFactory.deploy(backendSigner);
  await registryDeployed.waitForDeployment();
  const registryAddress  = await registryDeployed.getAddress();

  console.log("✅ SprinkleDataRegistry deployed at:", registryAddress);

  // ── Summary ──────────────────────────────────────────────────────────────

  console.log("\n════════════════════════════════════════");
  console.log("Set these environment variables:");
  console.log(`  SPRINKLE_CREDITS_ADDRESS=${creditsAddress}`);
  console.log(`  SPRINKLE_DATA_REGISTRY_ADDRESS=${registryAddress}`);
  console.log("════════════════════════════════════════\n");
}

main().catch(err => { console.error(err); process.exit(1); });
