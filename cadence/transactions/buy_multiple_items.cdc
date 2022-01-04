import FungibleToken from "../contracts/FungibleToken.cdc"
import NonFungibleToken from "../contracts/NonFungibleToken.cdc"
import FlowToken from "../contracts/FlowToken.cdc"
import NowggNFT from "../contracts/NowggNFT.cdc"
import NFTStoreFront from "../contracts/NFTStoreFront.cdc"

transaction(saleOfferResourceIDs: [UInt64], storefrontAddress: Address) {

    let paymentVault: @FungibleToken.Vault
    let NowggNFTCollection: &NowggNFT.Collection{NonFungibleToken.Receiver}
    let storefront: &NFTStoreFront.Storefront{NFTStoreFront.StorefrontPublic}
    let saleOffers: [&NFTStoreFront.Listing{NFTStoreFront.ListingPublic}]

    prepare(account: AuthAccount) {
        self.storefront = getAccount(storefrontAddress)
            .getCapability<&NFTStoreFront.Storefront{NFTStoreFront.StorefrontPublic}>(
                NFTStoreFront.StorefrontPublicPath
            )!
            .borrow()
            ?? panic("Could not borrow Storefront from provided address")
        
        var price : UFix64 = 0.0

        self.saleOffers = []

        let mainFlowTokenVault = account.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)
            ?? panic("Cannot borrow FlowToken vault from account storage")
        

        for saleOfferResourceID in saleOfferResourceIDs {
            let saleOffer = self.storefront.borrowListing(listingResourceID: saleOfferResourceID)
            ?? panic("No Offer with that ID in Storefront")
            price = price + saleOffer.getDetails().salePrice
            self.saleOffers.append(saleOffer)
        }

        self.paymentVault <- mainFlowTokenVault.withdraw(amount: price)


        self.NowggNFTCollection = account.borrow<&NowggNFT.Collection{NonFungibleToken.Receiver}>(
            from: NowggNFT.CollectionStoragePath
        ) ?? panic("Cannot borrow NowggNFT collection receiver from account")
    }

    execute {
        var index = 0
        for saleOffer in self.saleOffers {

            let tempVault <- self.paymentVault.withdraw(amount: saleOffer.getDetails().salePrice)
            let item <- saleOffer.purchase(payment: <-tempVault)

            self.NowggNFTCollection.deposit(token: <-item)

            self.storefront.cleanup(listingResourceID: saleOfferResourceIDs[index])
            index = index + 1
        }
        destroy self.paymentVault


    }
}
