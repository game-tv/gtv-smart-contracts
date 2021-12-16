import NFTStoreFront from "../contracts/NFTStoreFront.cdc"

// This script returns the number of NFTs for sale in a given account's storefront.

pub fun main(account: Address): Int {
	let storefrontRef = getAccount(account)
		.getCapability<&NFTStoreFront.Storefront{NFTStoreFront.StorefrontPublic}>(
	  		NFTStoreFront.StorefrontPublicPath
		)
		.borrow()
		?? panic("Could not borrow public storefront from address")
  
  	return storefrontRef.getListingIDs().length
}
