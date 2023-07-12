const { expect } = require("chai");
const { ethers } = require("hardhat");
const { loadFixture, time } = require("@nomicfoundation/hardhat-network-helpers");
const {
  deployControllerFixture
} = require("./test_setup");

describe("Rent Controller Constellation ✨: Controller-Properties-User", function () {
  describe("Deployment", function () {
    it("Should be deployed **Controller** with the correct params.", async function () {
      const {
        ControllerContract,
        LocalContract,
        TreasuryContract,
      } = await loadFixture(deployControllerFixture);

      /// ***********************
      /// * Controller contract *
      /// ***********************

      // hard
      expect(await ControllerContract.hardSoftPenalization(0, 0)).to.equal(0);
      expect(await ControllerContract.hardSoftPenalization(1, 0)).to.equal(3000);
      expect(await ControllerContract.hardSoftPenalization(2, 0)).to.equal(6000);
      expect(await ControllerContract.hardSoftPenalization(3, 0)).to.equal(10000);

      // soft
      expect(await ControllerContract.hardSoftPenalization(0, 1)).to.equal(0);
      expect(await ControllerContract.hardSoftPenalization(1, 1)).to.equal(1500);
      expect(await ControllerContract.hardSoftPenalization(2, 1)).to.equal(2000);
      expect(await ControllerContract.hardSoftPenalization(3, 1)).to.equal(10000);

      expect(await ControllerContract.local()).to.equal(LocalContract.address);
      expect(await ControllerContract.treasury()).to.equal(TreasuryContract.address);
      
      expect(await ControllerContract.totalBalance()).to.equal(0);
      expect(await ControllerContract.totalBalanceEth()).to.equal(0);
      expect(await ControllerContract.getTotalAccords()).to.equal(0);
    });
  });

  describe("Create, approve and reject Movements", function () {
    it("Should create a movement.", async function () {
      const {
        BondlyContract,
        bob,
        pizzaShop
      } = await loadFixture(basicBondlySetupFixture);

      await BondlyContract.connect(bob).createPayment(
        "Pay for the pizza in the event.",
        "Invoice number: WAP-123423432\nWe love pizza",
        MOVEMENT_SLUG_TEST,
        PROJECT_SLUG_TEST,
        PIZZA_PRICE,    // Amount in STABLE
        0,              // Amount in AVAX 🍒
        pizzaShop.address
      );

      expect(
        await BondlyContract.getProjectBalanceAvax(PROJECT_SLUG_TEST)
      ).to.equal(PROJECT_INITIAL_BALANCE_AVAX);
      expect(
        await BondlyContract.getProjectBalanceStable(PROJECT_SLUG_TEST)
      ).to.equal(PROJECT_INITIAL_BALANCE_STABLE.sub(PIZZA_PRICE));

      expect(await BondlyContract.getTotalMovements()).to.equal(1);
    });

    it("Should approve a movement.", async function () {
      const {
        USDTokenContract,
        BondlyContract,
        alice,
        bob,
        pizzaShop
      } = await loadFixture(basicBondlySetupFixture);

      await BondlyContract.connect(bob).createPayment(
        "Pay for the pizza in the event.",
        "Invoice number: WAP-123423432\nWe love pizza",
        MOVEMENT_SLUG_TEST,
        PROJECT_SLUG_TEST,
        PIZZA_PRICE,
        0,
        pizzaShop.address
      );

      await expect(
        BondlyContract.connect(bob).approveMovement(
          MOVEMENT_SLUG_TEST,
          PROJECT_SLUG_TEST
        )
      ).to.be.revertedWith("CANNOT_BE_PROPOSED_AND_APPROVED_BY_SAME_USER");

      expect(await USDTokenContract.balanceOf(pizzaShop.address)).to.equal(0);
      await BondlyContract.connect(alice).approveMovement(
        MOVEMENT_SLUG_TEST,
        PROJECT_SLUG_TEST
      );
      expect(await USDTokenContract.balanceOf(pizzaShop.address)).to.equal(PIZZA_PRICE);
    });

    it("Should reject a movement, but after 2nd approval, send the funds.", async function () {
      const {
        USDTokenContract,
        BondlyContract,
        alice,
        bob,
        carl,
        pizzaShop
      } = await loadFixture(basicBondlySetupFixture);

      await BondlyContract.connect(bob).createPayment(
        "Pay for the pizza in the event.",
        "Invoice number: WAP-123423432\nWe love pizza",
        MOVEMENT_SLUG_TEST,
        PROJECT_SLUG_TEST,
        PIZZA_PRICE,
        0,
        pizzaShop.address
      );

      await expect(
        BondlyContract.connect(bob).rejectMovement(
          MOVEMENT_SLUG_TEST,
          PROJECT_SLUG_TEST
        )
      ).to.be.revertedWith("CANNOT_BE_PROPOSED_AND_REJECTED_BY_SAME_USER");

      expect(await USDTokenContract.balanceOf(pizzaShop.address)).to.equal(0);
      await BondlyContract.connect(alice).rejectMovement(
        MOVEMENT_SLUG_TEST,
        PROJECT_SLUG_TEST
      );
      expect(await USDTokenContract.balanceOf(pizzaShop.address)).to.equal(0);
      await BondlyContract.connect(carl).approveMovement(
        MOVEMENT_SLUG_TEST,
        PROJECT_SLUG_TEST
      );
      expect(await USDTokenContract.balanceOf(pizzaShop.address)).to.equal(PIZZA_PRICE);
    });

    it("Should reject a movement altogether and return the funds to the Organization.", async function () {
      const {
        USDTokenContract,
        BondlyContract,
        alice,
        bob,
        carl,
        pizzaShop
      } = await loadFixture(basicBondlySetupFixture);

      await BondlyContract.connect(bob).createPayment(
        "Pay for the pizza in the event.",
        "Invoice number: WAP-123423432\nWe love pizza",
        MOVEMENT_SLUG_TEST,
        PROJECT_SLUG_TEST,
        PIZZA_PRICE,
        0,
        pizzaShop.address
      );

      const projectBalanceAvax = await BondlyContract.getProjectBalanceAvax(PROJECT_SLUG_TEST);
      const projectBalanceStable = await BondlyContract.getProjectBalanceStable(PROJECT_SLUG_TEST);

      expect(await USDTokenContract.balanceOf(pizzaShop.address)).to.equal(0);
      await BondlyContract.connect(alice).rejectMovement(
        MOVEMENT_SLUG_TEST,
        PROJECT_SLUG_TEST
      );
      expect(await USDTokenContract.balanceOf(pizzaShop.address)).to.equal(0);
      await BondlyContract.connect(carl).rejectMovement(
        MOVEMENT_SLUG_TEST,
        PROJECT_SLUG_TEST
      );
      expect(await USDTokenContract.balanceOf(pizzaShop.address)).to.equal(0);

      expect(
        await BondlyContract.getProjectBalanceAvax(PROJECT_SLUG_TEST)
      ).to.equal(
        projectBalanceAvax.add(0)
      );
      expect(
        await BondlyContract.getProjectBalanceStable(PROJECT_SLUG_TEST)
      ).to.equal(
        projectBalanceStable.add(PIZZA_PRICE)
      );
    });
  });

  describe("Funding project", function () {
    it("Should allow funding a project.", async function () {
      const {
        USDTokenContract,
        BondlyContract,
        alice,
        bob,
      } = await loadFixture(basicBondlySetupFixture);

      // console.log("NACIONES UNIDAS");
      // // const result = await BondlyContract.getOwnerProjects(alice.address, 5);
      // const result = await BondlyContract.projectOwners(alice.address, 0);
      // console.log(result);

    });
  });
});