import { ethers } from "hardhat";
import * as dotenv from "dotenv";

dotenv.config();

async function main() {
    console.log("Deploying 2-of-3 Multisig Wallet to Lisk Sepolia...");

    // Get the deployer's account
    const [deployer] = await ethers.getSigners();
    console.log("Deploying from:", deployer.address);

    // Check balance
    const balance = await ethers.provider.getBalance(deployer.address);
    console.log("Account balance:", ethers.formatEther(balance), "ETH");

    if (balance < ethers.parseEther("0.001")) {
        console.log("Low balance! Get test ETH from faucet first.");
        console.log("Try: https://console.optimism.io/faucet");
        console.log("Or: https://thirdweb.com/lisk-sepolia-testnet");
        return;
    }

    // FIX: Get addresses as strings first, then create the array
    const owner1 = deployer.address;

    // Replace these with your other two owner addresses
    // You can get these from MetaMask or other wallets you control
    const owner2 = "0x70997970C51812dc3A010C7d01b50e0d17dc79C8"; // CHANGE THIS
    const owner3 = "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC"; // CHANGE THIS

    // Create the owners array as a tuple
    const owners: [string, string, string] = [owner1, owner2, owner3];

    console.log("\n Setting owners:");
    console.log(`1: ${owners[0]}`);
    console.log(`2: ${owners[1]}`);
    console.log(`3: ${owners[2]}`);
    console.log("Required signatures: 2");

    // Get contract factory
    const MultisigWallet = await ethers.getContractFactory("MultisigWallet");

    // Deploy - passing the owners array directly
    console.log("\n⏳ Deploying...");
    const multisigWallet = await MultisigWallet.deploy(owners);

    // Wait for deployment
    await multisigWallet.waitForDeployment();

    // Get the address
    const address = await multisigWallet.getAddress();

    console.log("\n Multisig Wallet deployed to:", address);
    console.log("BlockScout:", `https://sepolia-blockscout.lisk.com/address/${address}`);

    // Get and display the contract balance
    const contractBalance = await ethers.provider.getBalance(address);
    console.log("Contract balance:", ethers.formatEther(contractBalance), "ETH");

    // Get the owners from the contract to verify
    const storedOwners = await multisigWallet.getOwners();
    console.log("\n Verified owners on contract:");
    console.log(`1: ${storedOwners[0]}`);
    console.log(`2: ${storedOwners[1]}`);
    console.log(`3: ${storedOwners[2]}`);
}

// Handle errors
main().catch((error) => {
    console.error("\n Deployment failed:");
    console.error(error);
    process.exitCode = 1;
});