import { ethers } from "hardhat";

async function main() {
    const Token = await ethers.getContractFactory("TestToken");
    const token = await Token.deploy();

    await token.waitForDeployment();

    console.log("TestToken deployed to:", await token.getAddress());
}

main().catch(console.error);
