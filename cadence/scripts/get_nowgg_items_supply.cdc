import NowggNFT from "../contracts/NowggNFT.cdc"


// This scripts returns the number of NowggNFTs currently in existence.

pub fun main(): UInt64 {    
    return NowggNFT.totalSupply
}
