import NonFungibleToken from "../contracts/NonFungibleToken.cdc"
import NowggNFT from "../contracts/NowggNFT.cdc"
import NowggPuzzle from "../contracts/NowggPuzzle.cdc"

// This transction uses the NFTMinter resource and puzzle helper to register NFTs as well as Puzzle.
//
// It must be run with the account that has minter stored at path /storage/NftMinter
// and puzzle helper resource stored at /storage/NowggPuzzleHelperStorage
transaction(puzzleId: String, parentNftTypeId: String, childNftIds: [UInt64], metadata: {String: AnyStruct}) {
    
    let minter: &NowggNFT.NFTMinter
    let puzzleHelper: &NowggPuzzle.PuzzleHelper
    let nowggNftProvider: &NowggNFT.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NowggNFT.NowggNFTCollectionPublic}

    prepare(adminAccount: AuthAccount, recipientAccount: AuthAccount) {
        assert(
            adminAccount.type(at: NowggNFT.MinterStoragePath) != nil,
            message: "Could not borrow a reference to the NFT minter"
        )
        self.minter = adminAccount.borrow<&NowggNFT.NFTMinter>(from: NowggNFT.MinterStoragePath)

        assert(
            adminAccount.type(at: NowggPuzzle.PuzzleHelperStoragePath) != nil,
            message: "Could not borrow a reference to the Puzzle Helper"
        )
        self.puzzleHelper = adminAccount.borrow<&NowggPuzzle.PuzzleHelper>(from: NowggPuzzle.PuzzleHelperStoragePath)

        assert(
            recipientAccount.type(at: NowggNFT.CollectionStoragePath),
            message: "Missing or mis-typed NowggNFT.Collection provider"
        )
        self.nowggNftProvider = recipientAccount!.borrow
        <&NowggNFT.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NowggNFT.NowggNFTCollectionPublic}>
        (from: NowggNFT.CollectionStoragePath)
    }

    execute {
        self.puzzleHelper.combinePuzzle(
            nftMinter: self.minter,
            nftProvider: self.nowggNftProvider,
            puzzleId: puzzleId,
            parentNftTypeId: parentNftTypeId,
            childNftIds: childNftIds,
            metadata: metadata
        )
    }}
