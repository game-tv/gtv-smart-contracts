import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import GametvNFT from "../../contracts/GametvNFT.cdc"

// This script returns the metadata for an NFT in an account's collection.

pub fun main(address: Address, itemID: UInt64): {String: AnyStruct} {

    // get the public account object for the token owner
    let owner = getAccount(address)

    let collectionBorrow = owner.getCapability(GametvNFT.CollectionPublicPath)!
        .borrow<&{GametvNFT.GametvNFTCollectionPublic}>()
        ?? panic("Could not borrow GametvNFTCollectionPublic")

    // borrow a reference to a specific NFT in the collection
    let gametvNFT = collectionBorrow.borrowGametvNFT(id: itemID)
        ?? panic("No such itemID in that collection")

    return gametvNFT.metadata
}
