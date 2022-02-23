import NonFungibleToken from "./NonFungibleToken.cdc"
import NowggNFT from "./NowggNFT.cdc"


pub contract NowggPuzzle {

    pub event ContractInitialized()
    pub event PuzzleRegistered(puzzleId: String, childNftTypeIds: [String])
    pub event PuzzleCombined(puzzleId: String, by: Address)

    pub let PuzzleHelperStoragePath: StoragePath
    pub let PuzzleHelperPublicPath: PublicPath

    pub struct Puzzle {
        pub let puzzleId: String
        pub let childNftTypeIds: [String]

        init(puzzleId: String, childNftTypeIds: [String]) {
            if (NowggPuzzle.activePuzzles.keys.contains(puzzleId)) {
                panic("Puzzle is already registered")
            }
            self.puzzleId = puzzleId
            self.childNftTypeIds = childNftTypeIds
        }
    }

    access(contract) var activePuzzles: {String: Puzzle}

    pub resource interface PuzzleHelperPublic {
        pub fun borrowActivePuzzle(puzzleId: String): Puzzle? {
            post {
                (result == nil) || (result?.puzzleId == puzzleId):
                    "Cannot borrow puzzle reference: The ID of the returned reference is incorrect"
            }
        }
    }

    pub resource interface PuzzleHelperInterface {   
        pub fun registerPuzzle(
            nftMinter: &NowggNFT.NFTMinter,
            puzzleId: String,
            childNftTypeIds: [String],
            maxCount: UInt64,
        )
        pub fun combinePuzzle(
            nftMinter: &NowggNFT.NFTMinter,
            nftProvider: &{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NowggNFT.NowggNFTCollectionPublic},
            puzzleId: String,
            childNftIds: [UInt64],
            metadata: {String: AnyStruct}
        )
    }

    // Resource that allows other accounts to access the functionality related to puzzles
    pub resource PuzzleHelper: PuzzleHelperPublic, PuzzleHelperInterface {

        pub fun borrowActivePuzzle(puzzleId: String): Puzzle? {
            if NowggPuzzle.activePuzzles[puzzleId] != nil {
                return NowggPuzzle.activePuzzles[puzzleId]
            } else {
                return nil
            }
        }

        pub fun registerPuzzle(
            nftMinter: &NowggNFT.NFTMinter,
            puzzleId: String,
            childNftTypeIds: [String],
            maxCount: UInt64,
        ) {
            NowggPuzzle.activePuzzles[puzzleId] = Puzzle(puzzleId: puzzleId, childNftTypeIds: childNftTypeIds)
            nftMinter.registerType(typeId: puzzleId, maxCount: maxCount)
            emit PuzzleRegistered(puzzleId: puzzleId, childNftTypeIds: childNftTypeIds)
        }

        pub fun combinePuzzle(
            nftMinter: &NowggNFT.NFTMinter,
            nftProvider: &{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NowggNFT.NowggNFTCollectionPublic},
            puzzleId: String,
            childNftIds: [UInt64],
            metadata: {String: AnyStruct}
        ) {
            let puzzle = self.borrowActivePuzzle(puzzleId: puzzleId)!
            let childNftTypes = puzzle.childNftTypeIds

            for nftId in childNftIds {
                let nft = nftProvider.borrowNowggNFT(id: nftId)!
                let nftTypeId = nft.getMetadata()["nftTypeId"] as? String!
                assert(childNftTypes.contains(nftTypeId), message: "Incorrect puzzle child NFT provided")

                var index = 0
                for childNftType in childNftTypes {
                    if childNftType == nftTypeId {
                        break
                    }
                    index = index + 1
                }
                childNftTypes.remove(at: index)
            }
            assert(childNftTypes.length == 0, message: "All required puzzle child NFTs not provided")

            nftMinter.mintNFT(recipient: nftProvider, typeId: puzzleId, metaData: metadata)

            for nftId in childNftIds {
                destroy <-nftProvider.withdraw(withdrawID: nftId)
            }

            emit PuzzleCombined(puzzleId: puzzleId, by: nftProvider.owner?.address!)
        }
    }

    init() {
        self.PuzzleHelperStoragePath = /storage/NowggPuzzleHelperStorage
        self.PuzzleHelperPublicPath = /public/NowggPuzzleHelperPublic

        self.activePuzzles = {}

        let puzzleHelper <-create PuzzleHelper()
        self.account.save(<-puzzleHelper, to: self.PuzzleHelperStoragePath)
        self.account.unlink(self.PuzzleHelperPublicPath)
        self.account.link<&NowggPuzzle.PuzzleHelper{NowggPuzzle.PuzzleHelperPublic}>(
            self.PuzzleHelperPublicPath, target: self.PuzzleHelperStoragePath
        )

        emit ContractInitialized()
    }
}