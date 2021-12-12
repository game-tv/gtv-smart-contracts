
import FungibleToken from "../contracts/FungibleToken.cdc"
import NonFungibleToken from "../contracts/NonFungibleToken.cdc"
import FlowToken from "../contracts/FlowToken.cdc"
import NowggNFT from "../contracts/NowggNFT.cdc"
import NFTStorefront from "../contracts/NFTStorefront.cdc"

transaction(saleOfferResourceID: UInt64, storefrontAddress: Address) {

    let paymentVault: @FungibleToken.Vault
    let NowggNFTCollection: &NowggNFT.Collection{NonFungibleToken.Receiver}
    let storefront: &NFTStorefront.Storefront{NFTStorefront.StorefrontPublic}
    let saleOffer: &NFTStorefront.Listing{NFTStorefront.ListingPublic}

    prepare(account: AuthAccount) {
        self.storefront = getAccount(storefrontAddress)
            .getCapability<&NFTStorefront.Storefront{NFTStorefront.StorefrontPublic}>(
                NFTStorefront.StorefrontPublicPath
            )!
            .borrow()
            ?? panic("Could not borrow Storefront from provided address")

        self.saleOffer = self.storefront.borrowListing(listingResourceID: saleOfferResourceID)
            ?? panic("No Offer with that ID in Storefront")
        
        let price = self.saleOffer.getDetails().salePrice

        let mainFlowTokenVault = account.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)
            ?? panic("Cannot borrow Kibble vault from account storage")
        
        self.paymentVault <- mainFlowTokenVault.withdraw(amount: price)

        self.NowggNFTCollection = account.borrow<&NowggNFT.Collection{NonFungibleToken.Receiver}>(
            from: NowggNFT.CollectionStoragePath
        ) ?? panic("Cannot borrow NowggNFT collection receiver from account")
    }

    execute {
        let item <- self.saleOffer.purchase(
            payment: <-self.paymentVault
        )

        self.NowggNFTCollection.deposit(token: <-item)

        self.storefront.cleanup(listingResourceID: saleOfferResourceID)
    }
}
