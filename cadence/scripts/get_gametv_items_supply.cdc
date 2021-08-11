import GametvNFT from "../contracts/GametvNFT.cdc"


// This scripts returns the number of GametvNFTs currently in existence.

pub fun main(): UInt64 {    
    return GametvNFT.totalSupply
}
