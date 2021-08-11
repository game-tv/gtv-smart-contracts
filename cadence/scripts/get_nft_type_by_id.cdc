import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import GametvNFT from "../../contracts/GametvNFT.cdc"

// This script returns the metadata for an NFT in an account's collection.

pub fun main(address: Address, itemID: String): {String: AnyStruct} {

    // get the public account object for the token owner
    let owner = getAccount(address)

    let nftTypeHelper = owner.getCapability(GametvNFT.NFTtypeHelperPublicPath)!
        .borrow<&{GametvNFT.NftTypeHelperPublic}>()
        ?? panic("Could not borrow NFTtypePublic")

    // borrow a reference to a specific NFT in the collection
    let gametvNftType = nftTypeHelper.borrowNFTtype(id: itemID)
        ?? panic("No such itemID in that collection")

    return gametvNftType.metaData
}
