import NonFungibleToken from "../contracts/NonFungibleToken.cdc"
import NowggNFT from "../contracts/NowggNFT.cdc"

// This transaction configures an account to hold Nowgg NFTs.

transaction {
    prepare(signer: AuthAccount) {
        // if the account doesn't already have a collection
        if signer.borrow<&NowggNFT.Collection>(from: NowggNFT.CollectionStoragePath) == nil {

            // create a new empty collection
            let collection <- NowggNFT.createEmptyCollection()
            
            // save it to the account
            signer.save(<-collection, to: NowggNFT.CollectionStoragePath)

            // create a public capability for the collection
            signer.link<&NowggNFT.Collection{NonFungibleToken.CollectionPublic, NowggNFT.NowggNFTCollectionPublic}>(NowggNFT.CollectionPublicPath, target: NowggNFT.CollectionStoragePath)
        }
    }
}
