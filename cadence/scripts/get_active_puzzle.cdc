
import NowggPuzzle from "../contracts/NowggPuzzle.cdc"


pub fun main(address: Address, puzzleId: String): AnyStruct {

    // get the public account object for the token owner
    let owner = getAccount(address)

    let puzzleHelper = owner.getCapability(NowggPuzzle.PuzzleHelperPublicPath)!
        .borrow<&{NowggPuzzle.PuzzleHelperPublic}>()
        ?? panic("Could not borrow PuzzleHelperPublic")

    let puzzle = puzzleHelper.borrowActivePuzzle(puzzleId: puzzleId)
        ?? panic("No such puzzle id in the collection")

    return puzzle
}
