import NFTStoreFront from "../contracts/NFTStorefront.cdc"

// This transaction installs the Storefront ressource in an account.

transaction {
    prepare(acct: AuthAccount) {

        // If the account doesn't already have a Storefront
        if acct.borrow<&NFTStoreFront.Storefront>(from: NFTStoreFront.StorefrontStoragePath) == nil {

            // Create a new empty .Storefront
            let storefront <- NFTStoreFront.createStorefront() as @NFTStoreFront.Storefront
            
            // save it to the account
            acct.save(<-storefront, to: NFTStoreFront.StorefrontStoragePath)

            // create a public capability for the .Storefront
            acct.link<&NFTStoreFront.Storefront{NFTStoreFront.StorefrontPublic}>(NFTStoreFront.StorefrontPublicPath, target: NFTStoreFront.StorefrontStoragePath)
        }
    }
}
