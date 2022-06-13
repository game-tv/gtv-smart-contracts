import NonFungibleToken from "../contracts/NonFungibleToken.cdc"
import NowggNFT from "../contracts/NowggNFT.cdc"
import NowggPuzzle from "../contracts/NowggPuzzle.cdc"

// This transction uses the NFTMinter resource and puzzle helper to register NFTs as well as Puzzle.
//
// It must be run with the account that has minter stored at path /storage/NftMinter
// and puzzle helper resource stored at /storage/NowggPuzzleHelperStorage

transaction(puzzleId: String, parentNftTypeId: String, childNftTypeIds: [String], maxCount: UInt64) {
    
    let minter: &NowggNFT.NFTMinter
    let puzzleHelper: &NowggPuzzle.PuzzleHelper

    prepare(signer: AuthAccount) {
        assert(
            signer.type(at: NowggNFT.MinterStoragePath) != nil,
            message: "Could not borrow a reference to the NFT minter"
        )
        self.minter = signer.borrow<&NowggNFT.NFTMinter>(from: NowggNFT.MinterStoragePath)
        assert(
            signer.type(at: NowggPuzzle.PuzzleHelperStoragePath) != nil,
            message: "Could not borrow a reference to the Puzzle Helper"
        )
        self.puzzleHelper = signer.borrow<&NowggPuzzle.PuzzleHelper>(from: NowggPuzzle.PuzzleHelperStoragePath)
    }

    execute {
        self.puzzleHelper.registerPuzzle(
            nftMinter: self.minter,
            puzzleId: puzzleId,
            parentNftTypeId: parentNftTypeId,
            childNftTypeIds: childNftTypeIds,
            maxCount: maxCount
        )
    }
}
