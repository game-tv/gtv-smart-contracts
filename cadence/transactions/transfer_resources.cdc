  
import NonFungibleToken from "../contracts/NonFungibleToken.cdc"
import NowggNFT from "../contracts/NowggNFT.cdc"
import NowggPuzzle from "../contracts/NowggPuzzle.cdc"

// This transaction transfers a Nowgg NFT Minter from one account to another.

transaction() {

    prepare(oldAdmin: AuthAccount, newAdmin: AuthAccount) {
        let minterStoragePath = NowggNFT.MinterStoragePath;
        let minter <- oldAdmin.load<@NowggNFT.NFTMinter>(from: minterStoragePath)
        newAdmin.save<@NowggNFT.NFTMinter>(<-minter, to: minterStoragePath)

        let collectionStoragePath = NowggNFT.CollectionStoragePath
        let collection <- oldAdmin.load<@NowggNFT.Collection>(from: collectionStoragePath)
        newAdmin.save<@NowggNFT.Collection>(<-collection, to: collectionStoragePath)
        newAdmin.link<&NowggNFT.Collection{NonFungibleToken.CollectionPublic, NowggNFT.NowggNFTCollectionPublic}>(
            NowggNFT.CollectionPublicPath, target: NowggNFT.CollectionStoragePath
        )

        let nftHelperPath = NowggNFT.NftTypeHelperStoragePath
        let typeHelper <- oldAdmin.load<@NowggNFT.NftTypeHelper>(from: nftHelperPath)

        newAdmin.save<@NowggNFT.NftTypeHelper>(<-typeHelper, to: nftHelperPath)
        newAdmin.link<&NowggNFT.NftTypeHelper{NowggNFT.NftTypeHelperPublic}>(
            NowggNFT.NFTtypeHelperPublicPath, target: NowggNFT.NftTypeHelperStoragePath
        )

        let puzzleHelperPath = NowggPuzzle.PuzzleHelperStoragePath
        let puzzleHelper <-oldAdmin.load<@NowggPuzzle.PuzzleHelper>(from: puzzleHelperPath)
        newAdmin.save<@NowggPuzzle.PuzzleHelper>(<-puzzleHelper, to: puzzleHelperPath)
        newAdmin.link<&NowggPuzzle.PuzzleHelper{NowggPuzzle.PuzzleHelperPublic}>(
            NowggPuzzle.PuzzleHelperPublicPath, target: puzzleHelperPath
        )
    }
}
