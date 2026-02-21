import { ethers } from "hardhat";

async function main() {
    const tokenAddress = "0xB05562Af7Bf883AbB751219fa3EDa092bB756080";

    const School = await ethers.getContractFactory("SchoolManagement");

    const school = await School.deploy(
        tokenAddress,
        ethers.parseEther("1"), // 100 level fee
        ethers.parseEther("2"), // 200 level fee
        ethers.parseEther("3"), // 300 level fee
        ethers.parseEther("4")  // 400 level fee
    );

    await school.waitForDeployment();

    console.log("SchoolManagement deployed to:", await school.getAddress());
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
