const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying from:", deployer.address);
  console.log("Account balance:", ethers.formatEther(await ethers.provider.getBalance(deployer.address)), "ETH\n");

  // ── 1. Deploy PropToken ──────────────────────────────────────
  const INITIAL_SUPPLY = 5_000_000; // 5 million PROP tokens

  const PropToken = await ethers.getContractFactory("PropToken");
  const propToken = await PropToken.deploy(INITIAL_SUPPLY);
  await propToken.waitForDeployment();

  const tokenAddress = await propToken.getAddress();
  console.log("PropToken deployed to:        ", tokenAddress);

  // ── 2. Deploy PropertyManagement ────────────────────────────
  const PropertyManagement = await ethers.getContractFactory("PropertyManagement");
  const propertyMgmt = await PropertyManagement.deploy(tokenAddress);
  await propertyMgmt.waitForDeployment();

  const pmAddress = await propertyMgmt.getAddress();
  console.log("PropertyManagement deployed to:", pmAddress);

  // ── 3. Quick sanity checks ───────────────────────────────────
  const deployerBalance = await propToken.balanceOf(deployer.address);
  console.log("\nDeployer PROP balance:", ethers.formatEther(deployerBalance), "PROP");

  const [isDefaultAdmin, isAdmin] = await propertyMgmt.getUserRoles(deployer.address);
  console.log("Deployer is DEFAULT_ADMIN:", isDefaultAdmin);
  console.log("Deployer is ADMIN:        ", isAdmin);

  // ── 4. Print summary ────────────────────────────────────────
  console.log("\n─────────────────────────────────────────");
  console.log("Deployment complete. Save these addresses:");
  console.log("PROP_TOKEN_ADDRESS=", tokenAddress);
  console.log("PROPERTY_MGMT_ADDRESS=", pmAddress);
  console.log("─────────────────────────────────────────");
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error(err);
    process.exit(1);
  });
