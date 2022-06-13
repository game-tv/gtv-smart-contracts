import NFTStoreFront from "../contracts/NFTStoreFront.cdc"

transaction(listingResourceIDs: [UInt64]) {
    let storefront: &NFTStoreFront.Storefront{NFTStoreFront.StorefrontManager}

    prepare(account: AuthAccount) {
        assert(
            account.type(at: NFTStoreFront.StorefrontStoragePath) != nil,
            message: "Missing or mis-typed NFTStoreFront.Storefront"
        )
        self.storefront = account.borrow<&NFTStoreFront.Storefront{NFTStoreFront.StorefrontManager}>
        (from: NFTStoreFront.StorefrontStoragePath)
    }

    execute {
        for listingResourceID in listingResourceIDs {
            self.storefront.removeListing(listingResourceID: listingResourceID)
        }
    }
}
