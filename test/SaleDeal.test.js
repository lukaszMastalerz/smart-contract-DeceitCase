import { ethers } from "hardhat";
import { expect } from "chai";

describe("SaleDeal – base pentest scaffold", function () {
  // Rols
  let mastalerz;
  let kowalski;
  let attacker;
  let other;

  // Contract
  let saleDeal;

  // Constants
  const PRICE = ethers.parseEther("0.5");

  before(async function () {
    // Download testing accounts
    [mastalerz, kowalski, attacker, other] = await ethers.getSigners();
  });

  beforeEach(async function () {
    // Deploy contract as mastalerz
    const SaleDeal = await ethers.getContractFactory("SaleDeal", mastalerz);
    saleDeal = await SaleDeal.deploy();
    await saleDeal.waitForDeployment();
  });

  /****************************************************************
   * Helpers to testing
   ****************************************************************/

  async function listCar() {
    await saleDeal.connect(mastalerz).listForSale(PRICE);
  }

  async function buyCarAsKowalski() {
    await saleDeal.connect(kowalski).buy({ value: PRICE });
  }

  async function confirmSaleAsMastalerz() {
    await saleDeal.connect(mastalerz).confirmSale();
  }

  /****************************************************************
   * Future tests:
   ****************************************************************/

  /*
  describe("Happy path", function () {
    it("full sale flow", async function () {});
  });
  */

  /*
  describe("Access control", function () {
    it("only mastalerz can list", async function () {});
    it("only mastalerz can confirm sale", async function () {});
  });
  */

  /*
  describe("Deceit / fraud vectors (Art. 86 CC)", function () {
    it("buyer misrepresentation scenario", async function () {});
    it("seller strategic delist attempt", async function () {});
  });
  */

  /*
  describe("Reentrancy / pull-payment safety", function () {
    it("withdrawPayments cannot be reentered", async function () {});
  });
  */

  /*
  describe("Edge cases", function () {
    it("double buy attempt", async function () {});
    it("cancel after confirm should fail", async function () {});
  });
  */
});
