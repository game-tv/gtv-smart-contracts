import NonFungibleToken from "../contracts/NonFungibleToken.cdc"
import GametvNFT from "../contracts/GametvNFT.cdc"

// This transction uses the NFTMinter resource to register a NFT type.
//
// It must be run with the account that has the minter resource
// stored at path /storage/NFTMinter.

transaction(typeID: String, maxCount: UInt64) {
    // local variable for storing the minter reference
    let minter: &GametvNFT.NFTMinter

    prepare(signer: AuthAccount) {

        // borrow a reference to the NFTMinter resource in storage
        self.minter = signer.borrow<&GametvNFT.NFTMinter>(from: GametvNFT.MinterStoragePath)
            ?? panic("Could not borrow a reference to the NFT minter")
    }

    execute {
        self.minter.registerType(typeId: typeID, maxCount: maxCount)
    }
}
