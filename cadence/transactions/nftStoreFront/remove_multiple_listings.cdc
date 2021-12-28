import NFTStoreFront from "../../contracts/NFTStoreFront.cdc"

transaction(listingResourceIDs: [UInt64]) {
    let storefront: &NFTStoreFront.Storefront{NFTStoreFront.StorefrontManager}

    prepare(account: AuthAccount) {
        self.storefront = account.borrow<&NFTStoreFront.Storefront{NFTStoreFront.StorefrontManager}>(from: NFTStoreFront.StorefrontStoragePath)
            ?? panic("Missing or mis-typed NFTStoreFront.Storefront")
    }

    execute {
        for listingResourceID in listingResourceIDs {
            self.storefront.removeListing(listingResourceID: listingResourceID)
        }
    }
}
