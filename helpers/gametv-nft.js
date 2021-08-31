import { deployContractByName, executeScript, mintFlow, sendTransaction, getAccountAddress } from "flow-js-testing";
import * as t from "@onflow/types"


const UFIX64_PRECISION = 8;

// UFix64 values shall be always passed as strings
export const toUFix64 = (value) => value.toFixed(UFIX64_PRECISION);

export const getGametvAdminAddress = async () => getAccountAddress("GametvAdmin");

// 
export const typeID1 = "1000";
export const typeID2 = "2000";

/*
 * Deploys NonFungibleToken and GametvNFT contracts to Gametvadmin.
 * @throws Will throw an error if transaction is reverted.
 * @returns {Promise<*>}
 * */
export const deployGametvNFT = async () => {
	const GametvAdmin = await getGametvAdminAddress();
	await mintFlow(GametvAdmin, "10.0");

	await deployContractByName({ to: GametvAdmin, name: "NonFungibleToken" });

	const addressMap = { NonFungibleToken: GametvAdmin };
	return deployContractByName({ to: GametvAdmin, name: "GametvNFT", addressMap });
};

/*
 * Setups GametvNFT collection on account and exposes public capability.
 * @param {string} account - account address
 * @throws Will throw an error if transaction is reverted.
 * @returns {Promise<*>}
 * */
export const setupGametvNFTOnAccount = async (account) => {
	const name = "setup_account";
	const signers = [account];

	return sendTransaction({ name, signers });
};

/*
 * Returns GametvNFTs supply.
 * @throws Will throw an error if execution will be halted
 * @returns {UInt64} - number of NFT minted so far
 * */
export const getGametvNFTSupply = async () => {
	const name = "get_gametv_items_supply";

	return executeScript({ name });
};

/*
 * Mints GametvNFT of a specific **itemType** and sends it to **recipient**.
 * @param {string} itemType - type of NFT to mint
 * @param {string} recipient - recipient account address
 * @param {UInt64} maxCount - max count of nfts
 * @throws Will throw an error if execution will be halted
 * @returns {Promise<*>}
 * */
export const registerType = async (itemType, maxCount) => {
	const GametvAdmin = await getGametvAdminAddress();

	const name = "register_type";
	const args = [[itemType, t.String], [maxCount, t.UInt64]];
	const signers = [GametvAdmin];

	return sendTransaction({ name, args, signers });
};

/*
 * Mints GametvNFT of a specific **itemType** and sends it to **recipient**.
 * @param {string} itemType - type of NFT to mint
 * @param {string} recipient - recipient account address
 * @throws Will throw an error if execution will be halted
 * @returns {Promise<*>}
 * */
export const mintAlreadyRegisteredNFT = async (itemType, recipient) => {
	const GametvAdmin = await getGametvAdminAddress();

	const metadata = [
    [
      {key: "test", value: "test1"}
    ],
    t.Dictionary({key: t.String, value: t.String})
  ]

	const name = "mint_nft";
	const args = [metadata, [recipient, t.Address], [itemType, t.String]];
	const signers = [GametvAdmin];

	return sendTransaction({ name, args, signers });
}

/*
 * Transfers Gametv NFT with id equal **itemId** from **sender** account to **recipient**.
 * @param {string} sender - sender address
 * @param {string} recipient - recipient address
 * @param {UInt64} itemId - id of the item to transfer
 * @throws Will throw an error if execution will be halted
 * @returns {Promise<*>}
 * */
export const transferGametvNFT = async (sender, recipient, itemId) => {
	const name = "transfer_gametv_nft";
	const args = [recipient, itemId];
	const signers = [sender];

	return sendTransaction({ name, args, signers });
};

/*
 * Returns the type of GametvNFT with **id** in account collection.
 * @param {string} account - account address
 * @param {UInt64} id - NFT id
 * @throws Will throw an error if execution will be halted
 * @returns {UInt64}
 * */
export const getGametvNFTById = async (account, id) => {
	const name = "get_game_tv_nft_type_id";
	const args = [account, id];

	return executeScript({ name, args });
};

/*
 * Returns the length of account's GametvNFT collection.
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