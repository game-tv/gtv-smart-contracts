import { deployContractByName, executeScript, mintFlow, sendTransaction, getAccountAddress } from "flow-js-testing";
import * as t from "@onflow/types"


const UFIX64_PRECISION = 8;

// UFix64 values shall be always passed as strings
export const toUFix64 = (value) => value.toFixed(UFIX64_PRECISION);

export const getNowggAdminAddress = async () => getAccountAddress("NowggAdmin");

export const getStorefrontAdminAddress = async () => getAccountAddress("StorefrontAdmin")

// 
export const typeID1 = "1000";
export const typeID2 = "2000";

/*
 * Deploys NonFungibleToken and NowggNFT contracts to Nowggadmin.
 * @throws Will throw an error if transaction is reverted.
 * @returns {Promise<*>}
 * */
export const deployContracts = async () => {
	const NowggAdmin = await getNowggAdminAddress();
	const StorefrontAdmin = await getStorefrontAdminAddress();

	const tempAdmin = await getAccountAddress('TempAdmin')
	await mintFlow(NowggAdmin, "10.0");
	await mintFlow(tempAdmin, "10.0");
	await mintFlow(StorefrontAdmin, "10.0")
	await deployContractByName({ to: tempAdmin, name: "NonFungibleToken" });

	const addressMap = { NonFungibleToken: tempAdmin, FungibleToken: "0xee82856bf20e2aa6", NowggNFT: tempAdmin };
	await deployContractByName({ to: tempAdmin, name: "NowggNFT", addressMap });
	await deployContractByName({ to: tempAdmin, name: "NowggPuzzle", addressMap });
	await deployContractByName({ to: StorefrontAdmin, name: "NFTStoreFront", addressMap});
	const name = "transfer_resources"
	const signers = [tempAdmin, NowggAdmin];
	return sendTransaction({name, signers});
};

/*
 * Setups NowggNFT collection on account and exposes public capability.
 * @param {string} account - account address
 * @throws Will throw an error if transaction is reverted.
 * @returns {Promise<*>}
 * */
export const setupNowggNFTOnAccount = async (account) => {
	const name = "setup_account";
	const signers = [account];

	return sendTransaction({ name, signers });
};

/*
 * Returns NowggNFTs supply.
 * @throws Will throw an error if execution will be halted
 * @returns {UInt64} - number of NFT minted so far
 * */
export const getNowggNFTSupply = async () => {
	const name = "get_nowgg_items_supply";

	return executeScript({ name });
};


export const transferResources = async (account1, account2) => {
	const name = "transfer_resources"
	const signers = [account1, account2];

	return sendTransaction({name, signers});
}
/*
 * Mints NowggNFT of a specific **itemType** and sends it to **recipient**.
 * @param {string} itemType - type of NFT to mint
 * @param {string} recipient - recipient account address
 * @param {UInt64} maxCount - max count of nfts
 * @throws Will throw an error if execution will be halted
 * @returns {Promise<*>}
 * */
export const registerType = async (itemType, maxCount) => {
	const NowggAdmin = await getNowggAdminAddress();

	const name = "register_type";
	const args = [[itemType, t.String], [maxCount, t.UInt64]];
	const signers = [NowggAdmin];

	return sendTransaction({ name, args, signers });
};

/*
 * Mints NowggNFT of a specific **itemType** and sends it to **recipient**.
 * @param {string} itemType - type of NFT to mint
 * @param {string} recipient - recipient account address
 * @throws Will throw an error if execution will be halted
 * @returns {Promise<*>}
 * */
export const mintAlreadyRegisteredNFT = async (itemType, recipient) => {
	const NowggAdmin = await getNowggAdminAddress();

	const metadata = [
    [
      {key: "test", value: "test1"}
    ],
    t.Dictionary({key: t.String, value: t.String})
  ]

	const name = "mint_nft";
	const args = [[recipient, t.Address], [itemType, t.String], metadata];
	const signers = [NowggAdmin];

	return sendTransaction({ name, args, signers });
}

/*
 * Transfers Nowgg NFT with id equal **itemId** from **sender** account to **recipient**.
 * @param {string} sender - sender address
 * @param {string} recipient - recipient address
 * @param {UInt64} itemId - id of the item to transfer
 * @throws Will throw an error if execution will be halted
 * @returns {Promise<*>}
 * */
export const transferNowggNFT = async (sender, recipient, itemId) => {
	const name = "transfer_nowgg_nft";
	const args = [recipient, itemId];
	const signers = [sender];

	return sendTransaction({ name, args, signers });
};

/*
 * Returns the type of NowggNFT with **id** in account collection.
 * @param {string} account - account address
 * @param {UInt64} id - NFT id
 * @throws Will throw an error if execution will be halted
 * @returns {UInt64}
 * */
export const getNowggNFTById = async (account, id) => {
	const name = "get_nowgg_nft_details";
	const args = [account, id];

	return executeScript({ name, args });
};

/*
 * Returns the length of account's NowggNFT collection.
 * @param {string} account - account address
 * @throws Will throw an error if execution will be halted
 * @returns {UInt64}
 * */
export const getCollectionLength = async (account) => {
	const name = "get_collection_length";
	const args = [account];

	return executeScript({ name, args });
};

/*
 * Returns the details of given NftType
 * @param {string} account - account address
 * @param {string} typeId - typeId of NFT
 * @throws Will throw an error if execution will be halted
 * @returns {String : AnyStruct}
 * */
export const getNftTypeDetails = async (account, typeId) => {
	const name = "get_nft_type_by_id";
	const args = [account, typeId];

	return executeScript({ name, args });
}


/*
 * Returns the details of given historic NftType
 * @param {string} account - account address
 * @param {string} typeId - typeId of NFT
 * @throws Will throw an error if execution will be halted
 * @returns {String : AnyStruct}
 * */
export const getHistoricNftTypeDetails = async (account, typeId) => {
	const name = "get_historic_nft_type_by_id";
	const args = [account, typeId];

	return executeScript({ name, args });
}


/*
 * Setup storefront
 * @param {string} account - account address
 * */
export const setupStorefrontOnAccount = async (account) => {
	await setupNowggNFTOnAccount(account);

	const name = "setup_storefront_account";
	const signers = [account];

	return sendTransaction({ name, signers });
};


/*
 * Sell Nft item
 * @param {string} seller - account address
 * @param {UInt64} itemId - id of NFT
 * @param {UFix64} price - price of NFT
 * @throws Will throw an error if execution will be halted
 * @returns {Promise<*>}
 * */
export const sellItem = async (seller, itemId, price) => {
	const name = "sell_item";
	const args = [itemId, price];
	const signers = [seller];

	return sendTransaction({ name, args, signers });
};


/*
 * Sell Nft item
 * @param {string} buyer - account address of buyer
 * @param {UInt64} resourceId - Listing Resource Id
 * @param {string} seller - account address of seller
 * @throws Will throw an error if execution will be halted
 * @returns {Promise<*>}
 * */
export const buyItem = async (buyer, resourceId, seller) => {
	const name = "buy_items_flow_token";
	const args = [resourceId, seller];
	const signers = [buyer];

	return sendTransaction({ name, args, signers });
};


/*
 * get total available listing count
 * @param {string} account - account address
 * @throws Will throw an error if execution will be halted
 * @returns {UInt64}
 * */
export const getSaleOfferCount = async (account) => {
	const name = "get_sale_offers_length";
	const args = [account];

	return executeScript({ name, args });
};


/*
 * Removes item with id equal to **item** from sale.
 * @param {string} owner - owner address
 * @param {UInt64} itemId - id of item to remove
 * @throws Will throw an error if transaction is reverted.
 * @returns {Promise<*>}
 * */
export const removeItem = async (owner, itemId) => {
	const name = "remove_multiple_listings";
	const signers = [owner];
	const args = [[itemId]];

	return sendTransaction({ name, args, signers });
};


/*
 * Update item with id equal to **item** from sale.
 * @param {string} owner - owner address
 * @param {UInt64} itemId - id of item to remove
 * @throws Will throw an error if transaction is reverted.
 * @returns {Promise<*>}
 * */
export const updateItem = async (owner, itemId, price, platformAddress, platformCut, royaltyAddress, royaltyCut, removeItemId) => {
	const name = "create_update_listings";
	const signers = [owner];
	const args = [[itemId], [price], platformAddress, platformCut, royaltyAddress, royaltyCut, [removeItemId]];

	return sendTransaction({ name, args, signers });
};
