import NonFungibleToken from "../contracts/NonFungibleToken.cdc"
import NowggNFT from "../contracts/NowggNFT.cdc"

// This transction uses the NFTMinter resource to register and mint a new NFT.
//
// It must be run with the account that has the minter resource
// stored at path /storage/NFTMinter.

transaction(metadata: {String : AnyStruct}, recipient: Address, typeID: String, maxCount: UInt64) {
    
    // local variable for storing the minter reference
    let minter: &NowggNFT.NFTMinter

    prepare(signer: AuthAccount) {

        // borrow a reference to the NFTMinter resource in storage
        assert(
            signer.type(at: NowggNFT.MinterStoragePath) != nil,
            message: "Could not borrow a reference to the NFT minter"
        )
        self.minter = signer.borrow<&NowggNFT.NFTMinter>(from: NowggNFT.MinterStoragePath)
    }

    execute {
        // get the public account object for the recipient
        let recipient = getAccount(recipient)

        // borrow the recipient's public NFT collection reference
        let receiver = recipient
            .getCapability(NowggNFT.CollectionPublicPath)!
            .borrow<&{NonFungibleToken.CollectionPublic}>()
            ?? panic("Could not get receiver reference to the NFT Collection")
          
        self.minter.registerType(typeId: typeID, maxCount: maxCount)

        // mint the NFT and deposit it to the recipient's collection
        self.minter.mintNFT(recipient: receiver, typeId: typeID, metaData: metadata)
    }
}
