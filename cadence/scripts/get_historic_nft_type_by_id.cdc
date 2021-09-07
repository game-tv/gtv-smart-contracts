
import NonFungibleToken from "../contracts/NonFungibleToken.cdc"
import NowggNFT from "../contracts/NowggNFT.cdc"

// This script returns the data for a historic NFT type.

pub fun main(address: Address, itemID: String): AnyStruct {

    // get the public account object for the token owner
    let owner = getAccount(address)

    let nftTypeHelper = owner.getCapability(NowggNFT.NFTtypeHelperPublicPath)!
        .borrow<&{NowggNFT.NftTypeHelperPublic}>()
        ?? panic("Could not borrow NFTtypePublic")

    // borrow a reference to a specific NFT in the collection
    let NowggNftType = nftTypeHelper.borrowHistoricNFTtype(id: itemID)
        ?? panic("No such itemID in that collection")

    return NowggNftType
}
