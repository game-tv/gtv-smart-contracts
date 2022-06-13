  
import NonFungibleToken from "../contracts/NonFungibleToken.cdc"
import NowggNFT from "../contracts/NowggNFT.cdc"

// This transaction transfers a Nowgg NFT from one account to another.

transaction(recipient: Address, withdrawID: UInt64) {
    prepare(signer: AuthAccount) {
        // get the recipients public account object
        let recipient = getAccount(recipient)

        // borrow a reference to the signer's NFT collection
        assert(
            signer.type(at: NowggNFT.CollectionStoragePath) != nil,
            message: "Could not borrow a reference to the owner's collection"
        )
        let collectionRef = signer.borrow<&NowggNFT.Collection>(from: NowggNFT.CollectionStoragePath)

        // borrow a public reference to the receivers collection
        let depositRef = recipient.getCapability(NowggNFT.CollectionPublicPath)!.borrow<&{NonFungibleToken.CollectionPublic}>()!

        // withdraw the NFT from the owner's collection
        let nft <- collectionRef.withdraw(withdrawID: withdrawID)

        // Deposit the NFT in the recipient's collection
        depositRef.deposit(token: <-nft)
    }
}
