const { ethers } = require("hardhat");

// Paste your deployed addresses here after running deploy.js
const PROP_TOKEN_ADDRESS  = "0x5FbDB2315678afecb367f032d93F642f64180aa3";
const PROPERTY_MGMT_ADDR  = "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512";

async function main() {
  const signers = await ethers.getSigners();
  const admin   = signers[0];
  const agent   = signers[1];
  const tenant  = signers[2];

  console.log("Admin  :", admin.address);
  console.log("Agent  :", agent.address);
  console.log("Tenant :", tenant.address);

  const token = await ethers.getContractAt("PropToken",          PROP_TOKEN_ADDRESS,  admin);
  const pm    = await ethers.getContractAt("PropertyManagement", PROPERTY_MGMT_ADDR, admin);

  // ── Step 1: Grant roles ──────────────────────────────────────
  console.log("\n[1] Granting roles...");
  await (await pm.grantAgentRole(agent.address)).wait();
  await (await pm.grantTenantRole(tenant.address)).wait();
  console.log("Agent and Tenant roles granted.");

  // ── Step 2: Fund tenant with PROP tokens ────────────────────
  console.log("\n[2] Minting 1000 PROP to tenant...");
  await (await token.mint(tenant.address, 1000)).wait();
  const tenantBal = await token.balanceOf(tenant.address);
  console.log("Tenant PROP balance:", ethers.formatEther(tenantBal));

  // ── Step 3: Agent creates a property ────────────────────────
  console.log("\n[3] Creating property as Agent...");
  const pmAsAgent = pm.connect(agent);
  const tx = await pmAsAgent.createProperty(
    "Sunrise Apartments",   // name
    "Victoria Island, Lagos", // location
    0,                      // PropertyType.APARTMENT
    200,                    // 200 PROP/month rent
    5000                    // 5000 PROP sale price
  );
  const receipt = await tx.wait();

  // Pull property ID from event
  const event = receipt.logs
    .map(log => { try { return pm.interface.parseLog(log); } catch { return null; } })
    .find(e => e && e.name === "PropertyCreated");
  const propertyId = event.args.id;
  console.log("Property created with ID:", propertyId.toString());

  // ── Step 4: Tenant rents the property ───────────────────────
  console.log("\n[4] Tenant renting property...");
  const tokenAsTenant = token.connect(tenant);
  const pmAsTenant    = pm.connect(tenant);

  const rentAmount = ethers.parseEther("200"); // 200 PROP
  await (await tokenAsTenant.approve(PROPERTY_MGMT_ADDR, rentAmount)).wait();
  await (await pmAsTenant.rentProperty(propertyId)).wait();
  console.log("Property rented successfully.");

  // ── Step 5: Check property status ───────────────────────────
  console.log("\n[5] Fetching property details...");
  const prop = await pm.getProperty(propertyId);
  console.log("Name          :", prop.name);
  console.log("Location      :", prop.location);
  console.log("Status        :", ["AVAILABLE","RENTED","SOLD","REMOVED"][prop.status]);
  console.log("Current Tenant:", prop.currentTenant);
  console.log("Last Payment  :", new Date(Number(prop.lastPaymentAt) * 1000).toUTCString());

  // ── Step 6: Pay next month's rent ───────────────────────────
  console.log("\n[6] Paying next month's rent...");
  await (await tokenAsTenant.approve(PROPERTY_MGMT_ADDR, rentAmount)).wait();
  await (await pmAsTenant.payRent(propertyId)).wait();
  console.log("Rent paid.");

  // ── Step 7: Admin evicts tenant ─────────────────────────────
  console.log("\n[7] Admin evicting tenant...");
  await (await pm.evictTenant(propertyId)).wait();
  const updated = await pm.getProperty(propertyId);
  console.log("Status after eviction:", ["AVAILABLE","RENTED","SOLD","REMOVED"][updated.status]);

  // ── Step 8: Remove property ─────────────────────────────────
  console.log("\n[8] Removing property...");
  await (await pm.removeProperty(propertyId)).wait();
  console.log("Property removed.");

  console.log("\nAll interactions completed successfully.");
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error(err);
    process.exit(1);
  });
