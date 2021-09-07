import NonFungibleToken from "../contracts/NonFungibleToken.cdc"
import NowggNFT from "../contracts/NowggNFT.cdc"

// This script returns the metadata for an NFT in an account's collection.

pub fun main(address: Address, itemID: UInt64): {String: AnyStruct} {

    // get the public account object for the token owner
    let owner = getAccount(address)

    let collectionBorrow = owner.getCapability(NowggNFT.CollectionPublicPath)!
        .borrow<&{NowggNFT.NowggNFTCollectionPublic}>()
        ?? panic("Could not borrow NowggNFTCollectionPublic")

    // borrow a reference to a specific NFT in the collection
    let NowggNFT = collectionBorrow.borrowNowggNFT(id: itemID)
        ?? panic("No such itemID in that collection")

    return NowggNFT.getMetadata()
}
