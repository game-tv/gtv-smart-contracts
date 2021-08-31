import NonFungibleToken from "../contracts/NonFungibleToken.cdc"
import GametvNFT from "../contracts/GametvNFT.cdc"

// This script returns the data for a historic NFT type.

pub fun main(address: Address, itemID: String): AnyStruct {

    // get the public account object for the token owner
    let owner = getAccount(address)

    let nftTypeHelper = owner.getCapability(GametvNFT.NFTtypeHelperPublicPath)!
        .borrow<&{GametvNFT.NftTypeHelperPublic}>()
        ?? panic("Could not borrow NFTtypePublic")

    // borrow a reference to a specific NFT in the collection
    let gametvNftType = nftTypeHelper.borrowStaleNFTtype(id: itemID)
        ?? panic("No such itemID in that collection")

    return gametvNftType
}
