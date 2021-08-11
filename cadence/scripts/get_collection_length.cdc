import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import GametvNFT from "../../contracts/GametvNFT.cdc"

// This script returns the size of an account's GametvNFT collection.

pub fun main(address: Address): Int {
    let account = getAccount(address)

    let collectionRef = account.getCapability(GametvNFT.CollectionPublicPath)!
        .borrow<&{NonFungibleToken.CollectionPublic}>()
        ?? panic("Could not borrow capability from public collection")
    
    return collectionRef.getIDs().length
}
