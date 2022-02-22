import NonFungibleToken from "./NonFungibleToken.cdc"
import NowggNFT from "./NowggNFT.cdc"


pub contract NowggPuzzle {

    pub event ContractInitialized()
    pub event PuzzleRegistered(puzzleId: String, pieceNftTypeIds: [String])
    pub event PuzzleCombined(puzzleId: String, by: Address)

    pub let PuzzleHelperStoragePath: StoragePath
    pub let PuzzleHelperPublicPath: PublicPath

    pub struct Puzzle {
        pub let puzzleId: String
        pub let pieceNftTypeIds: [String]

        init(puzzleId: String, pieceNftTypeIds: [String]) {
            if (NowggPuzzle.activePuzzles.keys.contains(puzzleId)) {
                panic("Puzzle is already registered")
            }
            self.puzzleId = puzzleId
            self.pieceNftTypeIds = pieceNftTypeIds
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
            minter: &NowggNFT.NFTMinter,
            puzzleId: String,
            pieceNftTypeIds: [String],
            maxCount: UInt64,
        )
        pub fun combinePuzzle(
            minter: &NowggNFT.NFTMinter,
            recipient: &{NonFungibleToken.CollectionPublic},
            puzzleId: String,
            pieceNftIds: [UInt64],
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
            minter: &NowggNFT.NFTMinter,
            puzzleId: String,
            pieceNftTypeIds: [String],
            maxCount: UInt64,
        ) {
            NowggPuzzle.activePuzzles[puzzleId] = Puzzle(puzzleId: puzzleId, pieceNftTypeIds: pieceNftTypeIds)
            minter.registerType(typeId: puzzleId, maxCount: maxCount)
            emit PuzzleRegistered(puzzleId: puzzleId, pieceNftTypeIds: pieceNftTypeIds)
        }

        pub fun combinePuzzle(
            minter: &NowggNFT.NFTMinter,
            recipient: &{NonFungibleToken.CollectionPublic},
            puzzleId: String,
            pieceNftIds: [UInt64],
            metadata: {String: AnyStruct}
        ) {
            let puzzle = self.borrowActivePuzzle(puzzleId: puzzleId)
            let pieceNftTypes = puzzle.pieceNftTypeIds

            for nftId in pieceNftIds {
                let nft = recipient.borrowNFT(id: nftId)!
                let nftTypeId = nft.getMetadata()["nftTypeId"]
                assert(pieceNftTypes.contains(nftTypeId), message: "Incorrect puzzle piece NFT provided")

                var index = 0
                for pieceNftType in pieceNftTypes {
                    if pieceNftType == nftTypeId {
                        break
                    }
                    index = index + 1
                }
                pieceNftTypes.remove(at: index)
            }
            assert(pieceNftTypes.length == 0, message: "All required puzzle piece NFTs not provided")

            minter.mintNFT(recipient: recipient, typeId: puzzleId, metaData: metadata)

            for nftId in pieceNftIds {
                destroy <-recipent.withdraw(withdrawID: nftId)
            }

            emit PuzzleCombined(puzzleId: puzzleId, by: recipient.owner.address)
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