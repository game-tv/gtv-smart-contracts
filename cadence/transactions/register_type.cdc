import NonFungibleToken from "../contracts/NonFungibleToken.cdc"
import NowggNFT from "../contracts/NowggNFT.cdc"

// This transction uses the NFTMinter resource to register a NFT type.
//
// It must be run with the account that has the minter resource
// stored at path /storage/NFTMinter.

transaction(typeID: String, maxCount: UInt64) {
    // local variable for storing the minter reference
    let minter: &NowggNFT.NFTMinter

    prepare(signer: AuthAccount) {

        assert(
            signer.type(at: NowggNFT.MinterStoragePath) != nil,
            message: "Could not borrow a reference to the NFT minter"
        )
        self.minter = signer.borrow<&NowggNFT.NFTMinter>(from: NowggNFT.MinterStoragePath)
    }

    execute {
        self.minter.registerType(typeId: typeID, maxCount: maxCount)
    }
}
