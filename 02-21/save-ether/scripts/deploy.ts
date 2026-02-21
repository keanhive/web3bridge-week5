import { ethers } from "hardhat";

async function main() {
    const SaveEther = await ethers.getContractFactory("SaveEther");

    const saveEther = await SaveEther.deploy();

    await saveEther.waitForDeployment();

    console.log("SaveEther deployed to:", await saveEther.getAddress());
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
