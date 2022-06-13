
import FungibleToken from "../contracts/FungibleToken.cdc"
import NonFungibleToken from "../contracts/NonFungibleToken.cdc"
import FlowToken from "../contracts/FlowToken.cdc"
import NowggNFT from "../contracts/NowggNFT.cdc"
import NFTStoreFront from "../contracts/NFTStoreFront.cdc"

transaction(saleOfferResourceID: UInt64, storefrontAddress: Address) {

    let paymentVault: @FungibleToken.Vault
    let NowggNFTCollection: &NowggNFT.Collection{NonFungibleToken.Receiver}
    let storefront: &NFTStoreFront.Storefront{NFTStoreFront.StorefrontPublic}
    let saleOffer: &NFTStoreFront.Listing{NFTStoreFront.ListingPublic}

    prepare(account: AuthAccount) {
        self.storefront = getAccount(storefrontAddress)
            .getCapability<&NFTStoreFront.Storefront{NFTStoreFront.StorefrontPublic}>(
                NFTStoreFront.StorefrontPublicPath
            )!
            .borrow()
            ?? panic("Could not borrow Storefront from provided address")

        self.saleOffer = self.storefront.borrowListing(listingResourceID: saleOfferResourceID)
            ?? panic("No Offer with that ID in Storefront")
        
        let price = self.saleOffer.getDetails().salePrice

        assert(
            account.type(at: /storage/flowTokenVault) != nil,
            message: "Cannot borrow FlowToken vault from account storage"
        )
        let mainFlowTokenVault = account.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)
        self.paymentVault <- mainFlowTokenVault.withdraw(amount: price)

        assert(
            account.type(at: NowggNFT.CollectionStoragePath) != nil,
            message: "Cannot borrow NowggNFT collection receiver from account"
        )
        self.NowggNFTCollection = account.borrow<&NowggNFT.Collection{NonFungibleToken.Receiver}>(
            from: NowggNFT.CollectionStoragePath
        )
    }

    execute {
        let item <- self.saleOffer.purchase(
            payment: <-self.paymentVault
        )

        self.NowggNFTCollection.deposit(token: <-item)

        self.storefront.cleanup(listingResourceID: saleOfferResourceID)
    }
}
