// const { expect } = require("chai");
const { ethers } = require("hardhat");
// const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");

async function deployControllerFixture() {
  // Get the ContractFactory and Signers here.
  const Local = await ethers.getContractFactory("Token");
  const Treasury = await ethers.getContractFactory("CentauriTreasury");
  const Property = await ethers.getContractFactory("Property");
  const Controller = await ethers.getContractFactory("RentController");

  const [
    owner,
    operator,
    alice,
    bob,
    carl
  ] = await ethers.getSigners();

  const initialSupply = ethers.utils.parseEther("20000000");
  const LocalContract = await Local.connect(owner).deploy(
    initialSupply,
    "MXN Dummy Token",
    "MXN",
    owner.address
  );
  await LocalContract.deployed();

  const TreasuryContract = await Treasury.connect(owner).deploy(
    operator.address,
    LocalContract.address,
    "Centauri Token",
    "CENT"
  );
  await TreasuryContract.deployed();

  const ControllerContract = await Controller.connect(owner).deploy(
    ethers.utils.parseEther("100"),  // Creating a new accord costs 100 MXN.
    0,
    LocalContract.address,
    TreasuryContract.address,
    [[3000, 1500], [6000, 2000]]
  );
  await ControllerContract.deployed();

  /// ****************
  /// * 3 Properties *
  /// ****************

  const SantaFeContract = await Property.connect(owner).deploy(
    4000,                         // 40 % for the property
    24 * 60 * 60,                 // 1 day
    24 * 60 * 60 * 30 * 3,        // 3 months (30 days)
    24 * 60 * 60 * 30 * 6,        // 6 months (30 days)
    ControllerContract.address,
    operator.address
  );
  await SantaFeContract.deployed();

  // const IndependenciaContract = await Property.connect(owner).deploy(
  //   4000,                         // 40 % for the property
  //   24 * 60 * 60,                 // 1 day
  //   24 * 60 * 60 * 365,           // 1 year (365 days)
  //   24 * 60 * 60 * 30 * 6,        // 6 months (30 days)
  //   ControllerContract.address,
  //   operator.address
  // );
  // await IndependenciaContract.deployed();

  // const SpaceProbeContract = await Property.connect(owner).deploy(
  //   4000,                         // 40 % for the property
  //   24 * 60 * 60,                 // 1 day
  //   24 * 60 * 60 * 30 * 3,        // 3 months (30 days)
  //   24 * 60 * 60 * 30 * 6,        // 6 months (30 days)
  //   ControllerContract.address,
  //   operator.address
  // );
  // await SpaceProbeContract.deployed();

  // Fixtures can return anything you consider useful for your tests
  return {
    ControllerContract,
    // IndependenciaContract,
    LocalContract,
    SantaFeContract,
    // SpaceProbeContract,
    TreasuryContract,
    owner,
    operator,
    alice,
    bob,
    carl,
  };
}

module.exports = {
  deployControllerFixture
};