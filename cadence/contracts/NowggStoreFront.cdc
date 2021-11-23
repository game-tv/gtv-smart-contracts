import NonFungibleToken from "./NonFungibleToken.cdc"

// NFTStorefront
//
// A general purpose sale support contract for Flow NonFungibleTokens.
// 
// Each account that wants to list NFTs for sale installs a Storefront,
// and lists individual sales within that Storefront as Listings.
// There is one Storefront per account, it handles sales of all NFT types
// for that account.
//
// Payments for the nfts listed will be managed by off the chain tools.
// This contract primarily helps in providing access to a given account
// to withdraw the nft which is listed for selling when a buyer requests it

// Each NFT may be listed in one or more Listings, the validity of each
// Listing can easily be checked.
// 
// Purchasers can watch for Listing events and check the NFT Contract type and
// ID to see if they wish to buy the listed item.
//
pub contract NFTStorefront {
    // NFTStorefrontInitialized
    // This contract has been deployed.
    // Event consumers can now expect events from this contract.
    //
    pub event NFTStorefrontInitialized()

    // StorefrontInitialized
    // A Storefront resource has been created.
    //
    pub event StorefrontInitialized(storefrontResourceID: UInt64)

    // StorefrontDestroyed
    // A Storefront has been destroyed.
    //
    pub event StorefrontDestroyed(storefrontResourceID: UInt64)

    // ListingAvailable
    // A listing has been created and added to a Storefront resource.
    // The Address values here are valid when the event is emitted, but
    // the state of the accounts they refer to may be changed outside of the
    // NFTStorefront workflow, so be careful to check when using them.
    //
    pub event ListingAvailable(
        storefrontAddress: Address,
        listingResourceID: UInt64,
        nftContractType: Type,
        nftID: UInt64
    )

    // ListingCompleted
    // The listing has been resolved. It has either been purchased, or removed and destroyed.
    //
    pub event ListingCompleted(listingResourceID: UInt64, storefrontResourceID: UInt64, purchased: Bool)

    // StorefrontStoragePath
    // The location in storage that a Storefront resource should be located.
    pub let StorefrontStoragePath: StoragePath

    // StorefrontPublicPath
    // The public location for a Storefront link.
    pub let StorefrontPublicPath: PublicPath



    // ListingDetails
    // A struct containing a Listing's data.
    //
    pub struct ListingDetails {
        // The Storefront that the Listing is stored in.
        pub var storefrontID: UInt64
        // Whether this listing has been purchased or not.
        pub var purchased: Bool
        // The Type of the NonFungibleToken.NFT that is being listed.
        pub let nftContractType: Type
        // The ID of the NFT within that type.
        pub let nftID: UInt64
        // Address of the account to which the owner is giving permission to withdraw the NFT
        pub let accessorAddress: Address

        // setToPurchased
        //
        access(contract) fun setToPurchased() {
            self.purchased = true
        }

        // initializer
        //
        init (
            nftContractType: Type,
            nftID: UInt64,
            storefrontID: UInt64,
            accessorAddress: Address
        ) {
            self.storefrontID = storefrontID
            self.purchased = false
            self.nftContractType = nftContractType
            self.nftID = nftID
            self.accessorAddress = accessorAddress
        }
    }


    // ListingPublic
    // An interface providing a useful public interface to a Listing.
    //
    pub resource interface ListingPublic {
        // borrowNFT
        // This will assert in the same way as the NFT standard borrowNFT()
        // if the NFT is absent, for example if it has been sold via another listing.
        //
        pub fun borrowNFT(): &NonFungibleToken.NFT

        // purchase
        // Purchase the listing, buying the token.
        //
        pub fun purchase(accessor: AuthAccount): @NonFungibleToken.NFT

        // getDetails
        //
        pub fun getDetails(): ListingDetails
    }


    // Listing
    // A resource that allows an NFT to be transferred by giving access to withdraw NFT
    // to a particular account.
    // 
    pub resource Listing: ListingPublic {
        // The simple (non-Capability, non-complex) details of the sale
        access(self) let details: ListingDetails

        // A capability allowing this resource to withdraw the NFT with the given ID from its collection.
        access(contract) let nftProviderCapability: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>

        // borrowNFT
        // This will assert in the same way as the NFT standard borrowNFT()
        // if the NFT is absent, for example if it has been sold via another listing.
        //
        pub fun borrowNFT(): &NonFungibleToken.NFT {
            let ref = self.nftProviderCapability.borrow()!.borrowNFT(id: self.getDetails().nftID)
            assert(ref.isInstance(self.getDetails().nftContractType), message: "token has wrong type")
            assert(ref.id == self.getDetails().nftID, message: "token has wrong ID")
            return ref as &NonFungibleToken.NFT
        }

        // getDetails
        // Get the details of the current state of the Listing as a struct.
        //
        pub fun getDetails(): ListingDetails {
            return self.details
        }

        // purchase
        // Purchase the listing, buying the token.
        //
        pub fun purchase(accessor: AuthAccount): @NonFungibleToken.NFT {
            pre {
                self.details.purchased == false: "listing has already been purchased"
                accessor.address == self.details.accessorAddress: "Invalid accessor"
            }

            // Make sure the listing cannot be purchased again.
            self.details.setToPurchased()

            // Fetch the token to return to the purchaser.
            let nft <-self.nftProviderCapability.borrow()!.withdraw(withdrawID: self.details.nftID)

            assert(nft.isInstance(self.details.nftContractType), message: "withdrawn NFT is not of specified type")
            assert(nft.id == self.details.nftID, message: "withdrawn NFT does not have specified ID")

            // If the listing is purchased, we regard it as completed here.
            emit ListingCompleted(
                listingResourceID: self.uuid,
                storefrontResourceID: self.details.storefrontID,
                purchased: self.details.purchased
            )

            return <-nft
        }

        // destructor
        //
        destroy () {
            if !self.details.purchased {
                emit ListingCompleted(
                    listingResourceID: self.uuid,
                    storefrontResourceID: self.details.storefrontID,
                    purchased: self.details.purchased
                )
            }
        }

        // initializer
        //
        init (
            nftProviderCapability: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>,
            nftContractType: Type,
            nftID: UInt64,
            storefrontID: UInt64,
            accessorAddress: Address
        ) {
            // Store the sale information
            self.details = ListingDetails(
                nftContractType: nftContractType,
                nftID: nftID,
                storefrontID: storefrontID,
                accessorAddress: accessorAddress

            )

            // Store the NFT provider
            self.nftProviderCapability = nftProviderCapability

            // Check that the provider contains the NFT.
            let provider = self.nftProviderCapability.borrow()
            assert(provider != nil, message: "cannot borrow nftProviderCapability")

            // This will precondition assert if the token is not available.
            let nft = provider!.borrowNFT(id: self.details.nftID)
            assert(nft.isInstance(self.details.nftContractType), message: "token is not of specified type")
            assert(nft.id == self.details.nftID, message: "token does not have specified ID")
        }
    }

    // StorefrontManager
    // An interface for adding and removing Listings within a Storefront,
    // intended for use by the Storefront's own
    //
    pub resource interface StorefrontManager {
        // createListing
        // Allows the Storefront owner to create and insert Listings.
        //
        pub fun createListing(
            nftProviderCapability: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>,
            nftContractType: Type,
            nftID: UInt64,
            accessorAddress: Address
        ): UInt64
        // removeListing
        // Allows the Storefront owner to remove any sale listing, acepted or not.
        //
        pub fun removeListing(listingResourceID: UInt64)
    }

    // StorefrontPublic
    // An interface to allow listing and borrowing Listings, and purchasing items via Listings
    // in a Storefront.
    //
    pub resource interface StorefrontPublic {
        pub fun getListingIDs(): [UInt64]
        pub fun borrowListing(listingResourceID: UInt64): &Listing{ListingPublic}?
        pub fun cleanup(listingResourceID: UInt64)
   }

    // Storefront
    // A resource that allows its owner to manage a list of Listings, and anyone to interact with them
    // in order to query their details and purchase the NFTs that they represent.
    //
    pub resource Storefront : StorefrontManager, StorefrontPublic {
        // The dictionary of Listing uuids to Listing resources.
        access(self) var listings: @{UInt64: Listing}

        // insert
        // Create and publish a Listing for an NFT.
        //
         pub fun createListing(
            nftProviderCapability: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>,
            nftContractType: Type,
            nftID: UInt64,
            accessorAddress: Address
         ): UInt64 {
            let listing <- create Listing(
                nftProviderCapability: nftProviderCapability,
                nftContractType: nftContractType,
                nftID: nftID,
                storefrontID: self.uuid,
                accessorAddress: accessorAddress
            )

            let listingResourceID = listing.uuid

            // Add the new listing to the dictionary.
            let oldListing <- self.listings[listingResourceID] <- listing
            // Note that oldListing will always be nil, but we have to handle it.
            destroy oldListing

            emit ListingAvailable(
                storefrontAddress: self.owner?.address!,
                listingResourceID: listingResourceID,
                nftContractType: nftContractType,
                nftID: nftID
            )

            return listingResourceID
        }

        // removeListing
        // Remove a Listing that has not yet been purchased from the collection and destroy it.
        //
        pub fun removeListing(listingResourceID: UInt64) {
            let listing <- self.listings.remove(key: listingResourceID)
                ?? panic("missing Listing")
    
            // This will emit a ListingCompleted event.
            destroy listing
        }

        // getListingIDs
        // Returns an array of the Listing resource IDs that are in the collection
        //
        pub fun getListingIDs(): [UInt64] {
            return self.listings.keys
        }

        // borrowSaleItem
        // Returns a read-only view of the SaleItem for the given listingID if it is contained by this collection.
        //
        pub fun borrowListing(listingResourceID: UInt64): &Listing{ListingPublic}? {
            if self.listings[listingResourceID] != nil {
                return &self.listings[listingResourceID] as! &Listing{ListingPublic}
            } else {
                return nil
            }
        }

        // cleanup
        // Remove an listing *if* it has been purchased.
        //
        pub fun cleanup(listingResourceID: UInt64) {
            pre {
                self.listings[listingResourceID] != nil: "could not find listing with given id"
            }

            let listing <- self.listings.remove(key: listingResourceID)!
            assert(listing.getDetails().purchased == true, message: "listing is not purchased, only admin can remove")
            destroy listing
        }

        // destructor
        //
        destroy () {
            destroy self.listings

            // Let event consumers know that this storefront will no longer exist
            emit StorefrontDestroyed(storefrontResourceID: self.uuid)
        }

        // constructor
        //
        init () {
            self.listings <- {}

            // Let event consumers know that this storefront exists
            emit StorefrontInitialized(storefrontResourceID: self.uuid)
        }
    }

    // createStorefront
    // Make creating a Storefront publicly accessible.
    //
    pub fun createStorefront(): @Storefront {
        return <-create Storefront()
    }

    init () {
        self.StorefrontStoragePath = /storage/NFTStorefront
        self.StorefrontPublicPath = /public/NFTStorefront

        emit NFTStorefrontInitialized()
    }
}