import NonFungibleToken from "./NonFungibleToken.cdc"


pub contract GametvNFT: NonFungibleToken {

    // Events
    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)
    pub event Minted(id: UInt64, typeId: String)
    pub event TypeRegistered(typeId: String)
    pub event TypeMoved(typeId: String)

    // Named Paths
    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath
    pub let MinterStoragePath: StoragePath
    pub let NftTypeHelperStoragePath: StoragePath
    pub let NFTtypeHelperPublicPath: PublicPath

    // totalSupply
    // The total number of GametvNFTs that have been minted
    pub var totalSupply: UInt64
    
    // NFT type
    // It is used to keep a check on the current NFTs minted and the total number of NFTs that can be minted
    // for a given type
    pub struct NftType {
        pub let typeId : String

        pub var currentCount : UInt64

        pub let maxCount : UInt64

        pub fun updateCount(count : UInt64) {
            self.currentCount = count
        }

        init(typeId: String, maxCount: UInt64) {

            if (GametvNFT.activeNftTypes.keys.contains(typeId)) {
                panic("Type is already registered")
            }

            self.typeId = typeId
            self.maxCount = maxCount
            self.currentCount = 0

        }
    }

    // NFT types registered which can be minted
    pub var activeNftTypes: {String : NftType}

    // NFT types registered which have reached the max limit for minting
    pub var historicNftTypes: {String : NftType}


    // NFT
    pub resource NFT: NonFungibleToken.INFT {
        // The token's ID
        pub let id: UInt64
        pub let metadata: {String : AnyStruct}

        // initializer
        //
        init(initID: UInt64, metadata: {String : AnyStruct}) {
            self.id = initID
            self.metadata = metadata
        }
    }

    // This is the interface that users can cast their GametvNFTs Collection as
    // to allow others to deposit GametvNFTs into their Collection. It also allows for reading
    // the details of GametvNFTs in the Collection.
    pub resource interface GametvNFTCollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowGametvNFT(id: UInt64): &GametvNFT.NFT? {
            // If the result isn't nil, the id of the returned reference
            // should be the same as the argument to the function
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow GametvNFT reference: The ID of the returned reference is incorrect"
            }
        }
    }


    // Interface that allows other users to access details of the NFTtypes
    // by providing the IDs for them
    pub resource interface NftTypeHelperPublic {
        pub fun borrowNFTtype(id: String): NftType? {
            post {
                (result == nil) || (result?.typeId == id):
                    "Cannot borrow NftType reference: The ID of the returned reference is incorrect"
            }
        }
    }

    // Collection
    // A collection of GametvItem NFTs owned by an account
    pub resource Collection: GametvNFTCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic {
        // dictionary of NFT conforming tokens
        // NFT is a resource type with an `UInt64` ID field
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        // withdraw
        // Removes an NFT from the collection and moves it to the caller
        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")

            emit Withdraw(id: token.id, from: self.owner?.address)

            return <-token
        }

        // deposit
        // Takes a NFT and adds it to the collections dictionary
        // and adds the ID to the id array
        pub fun deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @GametvNFT.NFT

            let id: UInt64 = token.id

            // add the new token to the dictionary which removes the old one
            let oldToken <- self.ownedNFTs[id] <- token

            emit Deposit(id: id, to: self.owner?.address)

            destroy oldToken
        }

        // getIDs
        // Returns an array of the IDs that are in the collection
        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        // borrowNFT
        // Gets a reference to an NFT in the collection
        // so that the caller can read its metadata and call its methods
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return &self.ownedNFTs[id] as &NonFungibleToken.NFT
        }

        // borrowGametvNFT
        // Gets a reference to an NFT in the collection as a GametvItem,
        // exposing all of its fields (including the typeID).
        // This is safe as there are no functions that can be called on the GametvItem.
        pub fun borrowGametvNFT(id: UInt64): &GametvNFT.NFT? {
            if self.ownedNFTs[id] != nil {
                let ref = &self.ownedNFTs[id] as auth &NonFungibleToken.NFT
                return ref as! &GametvNFT.NFT
            } else {
                return nil
            }
        }

        // destructor
        destroy() {
            destroy self.ownedNFTs
        }

        // initializer
        init () {
            self.ownedNFTs <- {}
        }
    }

    // createEmptyCollection
    // public function that anyone can call to create a new empty collection
    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create Collection()
    }


    // Resource that allows other users to access details of the NFTtypes
    // by providing the IDs for them
    pub resource NftTypeHelper : NftTypeHelperPublic {
        // public function to borrow details of NFTtype
        pub fun borrowNFTtype(id: String): NftType? {
            if GametvNFT.activeNftTypes[id] != nil {
                let ref = GametvNFT.activeNftTypes[id]
                return ref
            } else {
                return nil
            }
        }

        pub fun borrowStaleNFTtype(id: String): NftType? {
            if GametvNFT.historicNftTypes[id] != nil {
                let ref = GametvNFT.historicNftTypes[id]
                return ref
            } else {
                return nil
            }
        }
    }


    // NFTMinter
    // Resource that an admin or something similar would own to be
    // able to mint new NFTs
	pub resource NFTMinter {
	    // mintNFT
        // Mints a new NFT with a new ID
		// and deposit it in the recipients collection using their collection reference
        pub fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, typeId: String, metaData: {String : AnyStruct}) {

            if (!GametvNFT.activeNftTypes.keys.contains(typeId)) {
                panic("Invalid typeId")
            }
            let nftType = GametvNFT.activeNftTypes[typeId]!
            let currentCount = nftType.currentCount

            if (currentCount >= nftType.maxCount) {
                panic("NFT mint limit exceeded")
            }

            let updateCount = currentCount + (1 as UInt64);

            // Adding copy number to metadata
            metaData["copyNumber"] = updateCount;

            metaData["maxCount"] = nftType.maxCount;
            
            // Create and deposit NFT in recipent's account
            recipient.deposit(token: <-create GametvNFT.NFT(initID: GametvNFT.totalSupply, metadata: metaData))

            // Increment count for NFT of particular type
            nftType.updateCount(count: updateCount)

            if (updateCount < nftType.maxCount) {
                GametvNFT.activeNftTypes[typeId] = nftType
            } else {
                GametvNFT.historicNftTypes[typeId] = nftType
                GametvNFT.activeNftTypes.remove(key: typeId)
                emit TypeMoved(typeId: typeId)
            }

            // Increment total supply of NFTs
            GametvNFT.totalSupply = GametvNFT.totalSupply + (1 as UInt64)

            // emit event
            emit Minted(id: GametvNFT.totalSupply, typeId: typeId)
        }

        pub fun registerType(typeId: String, maxCount: UInt64) {
            let nftType = NftType(typeId: typeId, maxCount: maxCount)
            GametvNFT.activeNftTypes[typeId] = nftType
            emit TypeRegistered(typeId: typeId)
        }
	}

    // fetch
    // Get a reference to a GametvNFT from an account's Collection, if available.
    // If an account does not have a GametvNFT.Collection, panic.
    // If it has a collection but does not contain the itemID, return nil.
    // If it has a collection and that collection contains the itemID, return a reference to that.
    pub fun fetch(_ from: Address, itemID: UInt64): &GametvNFT.NFT? {
        let collection = getAccount(from)
            .getCapability(GametvNFT.CollectionPublicPath)!
            .borrow<&GametvNFT.Collection{GametvNFT.GametvNFTCollectionPublic}>()
            ?? panic("Couldn't get collection")
        // We trust GametvNFT.Collection.borrowGametvNFT to get the correct itemID
        // (it checks it before returning it).
        return collection.borrowGametvNFT(id: itemID)
    }

    // initializer
	init() {
        // Set our named paths
        self.CollectionStoragePath = /storage/GametvNFTsCollection
        self.CollectionPublicPath = /public/GametvNFTsCollection
        self.MinterStoragePath = /storage/GametvNFTMinter
        self.NftTypeHelperStoragePath = /storage/GametvNftTypeHelperStoragePath
        self.NFTtypeHelperPublicPath = /public/GametvNftNFTtypeHelperPublicPath

        // Initialize the total supply
        self.totalSupply = 0

        // Initialize active NFT types
        self.activeNftTypes = {}

        // Initialize historic NFT types
        self.historicNftTypes = {}

        // Create a Minter resource and save it to storage
        let minter <- create NFTMinter()
        self.account.save(<-minter, to: self.MinterStoragePath)

        // Create an empty collection
        let emptyCollection <- self.createEmptyCollection()
        self.account.save(<-emptyCollection, to: self.CollectionStoragePath)
        self.account.unlink(self.CollectionPublicPath)
        self.account.link<&GametvNFT.Collection{NonFungibleToken.CollectionPublic, GametvNFT.GametvNFTCollectionPublic}>(
            self.CollectionPublicPath, target: self.CollectionStoragePath
        )

        // Create helper for getting details of NftTypes
        let nftTypehelper <- create NftTypeHelper()
        self.account.save(<-nftTypehelper, to: self.NftTypeHelperStoragePath)
        self.account.unlink(self.NFTtypeHelperPublicPath)
        self.account.link<&GametvNFT.NftTypeHelper{GametvNFT.NftTypeHelperPublic}>(
            self.NFTtypeHelperPublicPath, target: self.NftTypeHelperStoragePath
        )

        // Emit event for contract initialized
        emit ContractInitialized()
	}
}
