import NFTStoreFront from "../contracts/NFTStorefront.cdc"

transaction(saleOfferResourceID: UInt64) {
    let storefront: &NFTStoreFront.Storefront{NFTStoreFront.StorefrontManager}

    prepare(acct: AuthAccount) {
        self.storefront = acct.borrow<&NFTStoreFront.Storefront{NFTStoreFront.StorefrontManager}>(from: NFTStoreFront.StorefrontStoragePath)
            ?? panic("Missing or mis-typed NFTStoreFront.Storefront")
    }

    execute {
        self.storefront.removeListing(listingResourceID: saleOfferResourceID)
    }
}