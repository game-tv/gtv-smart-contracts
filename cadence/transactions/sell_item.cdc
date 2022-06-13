import FungibleToken from "../contracts/FungibleToken.cdc"
import NonFungibleToken from "../contracts/NonFungibleToken.cdc"
import FlowToken from "../contracts/FlowToken.cdc"
import NFTStoreFront from "../contracts/NFTStoreFront.cdc"
import NowggNFT from "../contracts/NowggNFT.cdc"

transaction(saleItemID: UInt64, saleItemPrice: UFix64) {

    let flowReceiver: Capability<&FlowToken.Vault{FungibleToken.Receiver}>
    let NowggNFTProvider: Capability<&NowggNFT.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>
    let storefront: &NFTStoreFront.Storefront

    prepare(account: AuthAccount) {
        // We need a provider capability, but one is not provided by default so we create one if needed.
        let NowggNFTCollectionProviderPrivatePath = /private/NowggNFTCollectionProvider

        self.flowReceiver = account.getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(/public/flowTokenReceiver)!
        
        assert(self.flowReceiver.borrow() != nil, message: "Missing or mis-typed Flow token receiver")

        if !account.getCapability<&NowggNFT.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(NowggNFTCollectionProviderPrivatePath)!.check() {
            account.link<&NowggNFT.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(NowggNFTCollectionProviderPrivatePath, target: NowggNFT.CollectionStoragePath)
        }

        self.NowggNFTProvider = account.getCapability<&NowggNFT.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(NowggNFTCollectionProviderPrivatePath)!
        
        assert(self.NowggNFTProvider.borrow() != nil, message: "Missing or mis-typed FlowToken.Collection provider")

        self.storefront = account.borrow<&NFTStoreFront.Storefront>(from: NFTStoreFront.StorefrontStoragePath)
            ?? panic("Missing or mis-typed NFTStorefront Storefront")
    }

    execute {
        let saleCut = NFTStoreFront.SaleCut(
            receiver: self.flowReceiver,
            amount: saleItemPrice
        )
        self.storefront.createListing(
            nftProviderCapability: self.NowggNFTProvider,
            nftType: Type<@NowggNFT.NFT>(),
            nftID: saleItemID,
            salePaymentVaultType: Type<@FlowToken.Vault>(),
            saleCuts: [saleCut]
        )
    }
}
