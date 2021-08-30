import NonFungibleToken from "../contracts/NonFungibleToken.cdc"
import GametvNFT from "../contracts/GametvNFT.cdc"

// This transaction configures an account to hold Kitty Items.

transaction {
    prepare(signer: AuthAccount) {
        // if the account doesn't already have a collection
        if signer.borrow<&GametvNFT.Collection>(from: GametvNFT.CollectionStoragePath) == nil {

            // create a new empty collection
            let collection <- GametvNFT.createEmptyCollection()
            
            // save it to the account
            signer.save(<-collection, to: GametvNFT.CollectionStoragePath)

            // create a public capability for the collection
            signer.link<&GametvNFT.Collection{NonFungibleToken.CollectionPublic, GametvNFT.GametvNFTCollectionPublic}>(GametvNFT.CollectionPublicPath, target: GametvNFT.CollectionStoragePath)
        }
    }
}
