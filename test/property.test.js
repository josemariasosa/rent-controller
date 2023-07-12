const { expect } = require("chai");
const { ethers } = require("hardhat");
const { loadFixture, time } = require("@nomicfoundation/hardhat-network-helpers");
const {
  deployControllerFixture
} = require("./test_setup");

describe("Property 🏡: v0.1.0", function () {
  describe("Deployment", function () {
    it("Should be deployed **Property** with the correct params.", async function () {
      const {
        ControllerContract,
        LocalContract,
        SantaFeContract,
        TreasuryContract,
      } = await loadFixture(deployControllerFixture);

      /// ***********************
      /// * Property contract *
      /// ***********************

      expect(await SantaFeContract.rentFee()).to.equal(4000);
      expect(await SantaFeContract.treasury()).to.equal(TreasuryContract.address);
      expect(await SantaFeContract.local()).to.equal(LocalContract.address);
      expect(await SantaFeContract.controller()).to.equal(ControllerContract.address);

      expect(await SantaFeContract.balanceEth()).to.equal(0);
      expect(await SantaFeContract.getTotalAccords()).to.equal(0);
      expect((await SantaFeContract.getTotalAccordsDetails())._proposed).to.equal(0);
      expect((await SantaFeContract.getTotalAccordsDetails())._approved).to.equal(0);
      expect((await SantaFeContract.getTotalAccordsDetails())._confirmed).to.equal(0);
    });
  });

  // describe("Create, approve and reject Movements", function () {
  //   it("Should create a movement.", async function () {
  //     const {
  //       BondlyContract,
  //       bob,
  //       pizzaShop
  //     } = await loadFixture(basicBondlySetupFixture);

  //     await BondlyContract.connect(bob).createPayment(
  //       "Pay for the pizza in the event.",
  //       "Invoice number: WAP-123423432\nWe love pizza",
  //       MOVEMENT_SLUG_TEST,
  //       PROJECT_SLUG_TEST,
  //       PIZZA_PRICE,    // Amount in STABLE
  //       0,              // Amount in AVAX 🍒
  //       pizzaShop.address
  //     );

  //     expect(
  //       await BondlyContract.getProjectBalanceAvax(PROJECT_SLUG_TEST)
  //     ).to.equal(PROJECT_INITIAL_BALANCE_AVAX);
  //     expect(
  //       await BondlyContract.getProjectBalanceStable(PROJECT_SLUG_TEST)
  //     ).to.equal(PROJECT_INITIAL_BALANCE_STABLE.sub(PIZZA_PRICE));

  //     expect(await BondlyContract.getTotalMovements()).to.equal(1);
  //   });

  //   it("Should approve a movement.", async function () {
  //     const {
  //       USDTokenContract,
  //       BondlyContract,
  //       alice,
  //       bob,
  //       pizzaShop
  //     } = await loadFixture(basicBondlySetupFixture);

  //     await BondlyContract.connect(bob).createPayment(
  //       "Pay for the pizza in the event.",
  //       "Invoice number: WAP-123423432\nWe love pizza",
  //       MOVEMENT_SLUG_TEST,
  //       PROJECT_SLUG_TEST,
  //       PIZZA_PRICE,
  //       0,
  //       pizzaShop.address
  //     );

  //     await expect(
  //       BondlyContract.connect(bob).approveMovement(
  //         MOVEMENT_SLUG_TEST,
  //         PROJECT_SLUG_TEST
  //       )
  //     ).to.be.revertedWith("CANNOT_BE_PROPOSED_AND_APPROVED_BY_SAME_USER");

  //     expect(await USDTokenContract.balanceOf(pizzaShop.address)).to.equal(0);
  //     await BondlyContract.connect(alice).approveMovement(
  //       MOVEMENT_SLUG_TEST,
  //       PROJECT_SLUG_TEST
  //     );
  //     expect(await USDTokenContract.balanceOf(pizzaShop.address)).to.equal(PIZZA_PRICE);
  //   });

  //   it("Should reject a movement, but after 2nd approval, send the funds.", async function () {
  //     const {
  //       USDTokenContract,
  //       BondlyContract,
  //       alice,
  //       bob,
  //       carl,
  //       pizzaShop
  //     } = await loadFixture(basicBondlySetupFixture);

  //     await BondlyContract.connect(bob).createPayment(
  //       "Pay for the pizza in the event.",
  //       "Invoice number: WAP-123423432\nWe love pizza",
  //       MOVEMENT_SLUG_TEST,
  //       PROJECT_SLUG_TEST,
  //       PIZZA_PRICE,
  //       0,
  //       pizzaShop.address
  //     );

  //     await expect(
  //       BondlyContract.connect(bob).rejectMovement(
  //         MOVEMENT_SLUG_TEST,
  //         PROJECT_SLUG_TEST
  //       )
  //     ).to.be.revertedWith("CANNOT_BE_PROPOSED_AND_REJECTED_BY_SAME_USER");

  //     expect(await USDTokenContract.balanceOf(pizzaShop.address)).to.equal(0);
  //     await BondlyContract.connect(alice).rejectMovement(
  //       MOVEMENT_SLUG_TEST,
  //       PROJECT_SLUG_TEST
  //     );
  //     expect(await USDTokenContract.balanceOf(pizzaShop.address)).to.equal(0);
  //     await BondlyContract.connect(carl).approveMovement(
  //       MOVEMENT_SLUG_TEST,
  //       PROJECT_SLUG_TEST
  //     );
  //     expect(await USDTokenContract.balanceOf(pizzaShop.address)).to.equal(PIZZA_PRICE);
  //   });

  //   it("Should reject a movement altogether and return the funds to the Organization.", async function () {
  //     const {
  //       USDTokenContract,
  //       BondlyContract,
  //       alice,
  //       bob,
  //       carl,
  //       pizzaShop
  //     } = await loadFixture(basicBondlySetupFixture);

  //     await BondlyContract.connect(bob).createPayment(
  //       "Pay for the pizza in the event.",
  //       "Invoice number: WAP-123423432\nWe love pizza",
  //       MOVEMENT_SLUG_TEST,
  //       PROJECT_SLUG_TEST,
  //       PIZZA_PRICE,
  //       0,
  //       pizzaShop.address
  //     );

  //     const projectBalanceAvax = await BondlyContract.getProjectBalanceAvax(PROJECT_SLUG_TEST);
  //     const projectBalanceStable = await BondlyContract.getProjectBalanceStable(PROJECT_SLUG_TEST);

  //     expect(await USDTokenContract.balanceOf(pizzaShop.address)).to.equal(0);
  //     await BondlyContract.connect(alice).rejectMovement(
  //       MOVEMENT_SLUG_TEST,
  //       PROJECT_SLUG_TEST
  //     );
  //     expect(await USDTokenContract.balanceOf(pizzaShop.address)).to.equal(0);
  //     await BondlyContract.connect(carl).rejectMovement(
  //       MOVEMENT_SLUG_TEST,
  //       PROJECT_SLUG_TEST
  //     );
  //     expect(await USDTokenContract.balanceOf(pizzaShop.address)).to.equal(0);

  //     expect(
  //       await BondlyContract.getProjectBalanceAvax(PROJECT_SLUG_TEST)
  //     ).to.equal(
  //       projectBalanceAvax.add(0)
  //     );
  //     expect(
  //       await BondlyContract.getProjectBalanceStable(PROJECT_SLUG_TEST)
  //     ).to.equal(
  //       projectBalanceStable.add(PIZZA_PRICE)
  //     );
  //   });
  // });

  // describe("Funding project", function () {
  //   it("Should allow funding a project.", async function () {
  //     const {
  //       USDTokenContract,
  //       BondlyContract,
  //       alice,
  //       bob,
  //     } = await loadFixture(basicBondlySetupFixture);

  //     // console.log("NACIONES UNIDAS");
  //     // // const result = await BondlyContract.getOwnerProjects(alice.address, 5);
  //     // const result = await BondlyContract.projectOwners(alice.address, 0);
  //     // console.log(result);

  //   });
  // });
});