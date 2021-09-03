
import path from "path";
import { emulator, init, getAccountAddress, shallPass, shallResolve, shallRevert } from "flow-js-testing";
import {
	deployGametvNFT,
	getCollectionLength,
	getGametvNFTById,
	getGametvNFTSupply,
	setupGametvNFTOnAccount,
	transferGametvNFT,
	typeID1,
	typeID2,
  getGametvAdminAddress,
	mintAlreadyRegisteredNFT,
	registerType,
	getNftTypeDetails,
	getHistoricNftTypeDetails
} from "../helpers/gametv-nft";
import { expect } from "@jest/globals";

jest.setTimeout(50000);

describe("Contract tests", () => {
	beforeEach(async () => {
		const basePath = path.resolve(__dirname, "../cadence");
		const port = 8085;
		init(basePath, port);
		return emulator.start(port, false);
	});

	// Stop emulator, so it could be restarted
	afterEach(async () => {
		return emulator.stop();
	});

  it("shall deploy GametvNFT contract", async () => {
		await shallPass(deployGametvNFT());
	});

	it("supply shall be 0 after contract is deployed", async () => {
		// Setup
		await deployGametvNFT();
		const GametvAdmin = await getGametvAdminAddress();
		await shallPass(setupGametvNFTOnAccount(GametvAdmin));

		await shallResolve(async () => {
			const supply = await getGametvNFTSupply();
			expect(supply).toBe(0);
		});
	});

	it("shall be able to mint a GametvNFT", async () => {
		// Setup
		await deployGametvNFT();
		const Admin = await getGametvAdminAddress();
		const Alice = await getAccountAddress("Alice");
		await setupGametvNFTOnAccount(Alice);
		const itemIdToMint = typeID1;
		const maxCount = 4;

		await shallPass(registerType(itemIdToMint, maxCount));
		const typeDetails = await getNftTypeDetails(Admin, itemIdToMint);
		expect(typeDetails.typeId).toBe(itemIdToMint);
		expect(typeDetails.maxCount).toBe(maxCount);
		expect(typeDetails.currentCount).toBe(0);
		await shallPass(mintAlreadyRegisteredNFT(itemIdToMint, Alice))

		await shallResolve(async () => {
			const nftCount = await getCollectionLength(Alice);
			expect(nftCount).toBe(1);

			const metadata = await getGametvNFTById(Alice, 0);
			expect(metadata.maxCount).toBe(maxCount);
			expect(metadata.test).toBe("test1");
			expect(metadata.copyNumber).toBe(1);
		});
	});

	it("shall be able to create a new empty NFT Collection", async () => {
		// Setup
		await deployGametvNFT();
		const Alice = await getAccountAddress("Alice");
		await setupGametvNFTOnAccount(Alice);

		// shall be able te read Alice collection and ensure it's empty
		await shallResolve(async () => {
			const length = await getCollectionLength(Alice);
			expect(length).toBe(0);
		});
	});

	it("shall not be able to withdraw an NFT that doesn't exist in a collection", async () => {
		// Setup
		await deployGametvNFT();
		const Alice = await getAccountAddress("Alice");
		const Bob = await getAccountAddress("Bob");
		await setupGametvNFTOnAccount(Alice);
		await setupGametvNFTOnAccount(Bob);

		// Transfer transaction shall fail for non-existent item
		await shallRevert(transferGametvNFT(Alice, Bob, 1337));
	});

	it("shall be able to withdraw an NFT and deposit to another accounts collection", async () => {
		await deployGametvNFT();
		const Alice = await getAccountAddress("Alice");
		const Bob = await getAccountAddress("Bob");
		const maxCount = 4
		await setupGametvNFTOnAccount(Alice);
		await setupGametvNFTOnAccount(Bob);

		// Mint instruction for Alice account shall be resolved
		await shallPass(registerType(typeID1, maxCount));
		await shallPass(mintAlreadyRegisteredNFT(typeID1, Alice))

		// Transfer transaction shall pass
		await shallPass(transferGametvNFT(Alice, Bob, 0));
	});

	it("should painc after trying to mint a type that doesnot exist", async () => {
		await deployGametvNFT();
		const Alice = await getAccountAddress("Alice");
		await setupGametvNFTOnAccount(Alice);
		const itemIdToMint = typeID1;
		const invalidItemId = "test"
		const maxCount = 2;
		await shallPass(registerType(itemIdToMint, maxCount));
		await shallPass(mintAlreadyRegisteredNFT(itemIdToMint, Alice))
		await shallRevert(mintAlreadyRegisteredNFT(invalidItemId, Alice));
	})

	it("should painc after minting more than max count of NFTs", async () => {
		await deployGametvNFT();
		const Alice = await getAccountAddress("Alice");
		await setupGametvNFTOnAccount(Alice);
		const itemIdToMint = typeID1;
		const maxCount = 2;

		// Mint instruction for Alice account shall be resolved
		await shallPass(registerType(itemIdToMint, maxCount));
		await shallPass(mintAlreadyRegisteredNFT(itemIdToMint, Alice))
		await shallPass(mintAlreadyRegisteredNFT(itemIdToMint, Alice));
		await shallRevert(mintAlreadyRegisteredNFT(itemIdToMint, Alice));
	})

	it("should panic after registering same type again", async () => {
		await deployGametvNFT();
		const Alice = await getAccountAddress("Alice");
		await setupGametvNFTOnAccount(Alice);
		const maxCount = 4;

		await shallPass(registerType(typeID1, maxCount));

		await shallPass(registerType(typeID2, maxCount));

		await shallRevert(registerType(typeID2, maxCount));
	})

	it("should be able to get details of an active and historic NFT", async () => {
		await deployGametvNFT();
		const maxCount = 2;

		const Admin = await getGametvAdminAddress();


		await shallPass(registerType(typeID1, maxCount));

		let typeDetails = await getNftTypeDetails(Admin, typeID1);
		expect(typeDetails.typeId).toBe(typeID1);
		expect(typeDetails.maxCount).toBe(maxCount);
		expect(typeDetails.currentCount).toBe(0);

		const Alice = await getAccountAddress("Alice");
		await setupGametvNFTOnAccount(Alice);

		await shallPass(mintAlreadyRegisteredNFT(typeID1, Alice))

		typeDetails = await getNftTypeDetails(Admin, typeID1);
		expect(typeDetails.typeId).toBe(typeID1);
		expect(typeDetails.maxCount).toBe(maxCount);
		expect(typeDetails.currentCount).toBe(1);

		await shallPass(mintAlreadyRegisteredNFT(typeID1, Alice))

		await shallRevert(getNftTypeDetails(Admin, typeID1));

		typeDetails = await getHistoricNftTypeDetails(Admin, typeID1);
		expect(typeDetails.typeId).toBe(typeID1);
		expect(typeDetails.maxCount).toBe(maxCount);
		expect(typeDetails.currentCount).toBe(2);

	})
 })
