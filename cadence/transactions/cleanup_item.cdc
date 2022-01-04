import NFTStoreFront from "../contracts/NFTStoreFront.cdc"
transaction(saleOfferResourceID: UInt64, storefrontAddress: Address) {
    let storefront: &NFTStoreFront.Storefront{NFTStoreFront.StorefrontPublic}

    prepare(acct: AuthAccount) {
        self.storefront = getAccount(storefrontAddress)
            .getCapability<&NFTStoreFront.Storefront{NFTStoreFront.StorefrontPublic}>(
                NFTStoreFront.StorefrontPublicPath
            )!
            .borrow()
            ?? panic("Cannot borrow Storefront from provided address")
    }

    execute {
        // Be kind and recycle
        self.storefront.cleanup(listingResourceID: saleOfferResourceID)
    }
}
