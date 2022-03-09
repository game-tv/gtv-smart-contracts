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
        // We need a provider capability, but one is not provided by default so we create one if needed.
        let nowggNftsCollectionProviderPrivatePath = /private/NowggNFTsCollectionProvider

        // borrow a reference to the NFTMinter resource in storage
        self.minter = adminAccount.borrow<&NowggNFT.NFTMinter>(from: NowggNFT.MinterStoragePath)
            ?? panic("Could not borrow a reference to the NFT minter")
        self.puzzleHelper = adminAccount.borrow<&NowggPuzzle.PuzzleHelper>(from: NowggPuzzle.PuzzleHelperStoragePath)
            ?? panic("Could not borrow a reference to the Puzzle Helper")

        if !recipientAccount.getCapability
        <&NowggNFT.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NowggNFT.NowggNFTCollectionPublic}>
        (nowggNftsCollectionProviderPrivatePath)!.check() {
            recipientAccount.link
            <&NowggNFT.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NowggNFT.NowggNFTCollectionPublic}>
            (nowggNftsCollectionProviderPrivatePath, target: NowggNFT.CollectionStoragePath)
        }
        self.nowggNftProvider = (recipientAccount!.getCapability
        <&NowggNFT.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NowggNFT.NowggNFTCollectionPublic}>
        (nowggNftsCollectionProviderPrivatePath)!).borrow()!

        assert(self.nowggNftProvider != nil, message: "Missing or mis-typed NowggNFT.Collection provider")
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
