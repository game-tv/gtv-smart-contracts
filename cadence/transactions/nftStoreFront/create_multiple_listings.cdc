import FungibleToken from "../../contracts/FungibleToken.cdc"
import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import FlowToken from "../../contracts/FlowToken.cdc"
import NowggNFT from "../../contracts/NowggNFT.cdc"
import NFTStoreFront from "../../contracts/NFTStoreFront.cdc"

pub fun getOrCreateStorefront(account: AuthAccount): &NFTStoreFront.Storefront {
    if let storefrontRef = account.borrow<&NFTStoreFront.Storefront>(from: NFTStoreFront.StorefrontStoragePath) {
        return storefrontRef
    }

    let storefront <- NFTStoreFront.createStorefront()

    let storefrontRef = &storefront as &NFTStoreFront.Storefront

    account.save(<-storefront, to: NFTStoreFront.StorefrontStoragePath)

    account.link<&NFTStoreFront.Storefront{NFTStoreFront.StorefrontPublic}>(NFTStoreFront.StorefrontPublicPath, target: NFTStoreFront.StorefrontStoragePath)

    return storefrontRef
}

transaction(saleItemIDs: [UInt64], saleItemPrices: [UFix64], platformAddress: Address, platformCutPercent: UFix64) {

    let flowReceiver: Capability<&FlowToken.Vault{FungibleToken.Receiver}>
    let nowggNftsProvider: Capability<&NowggNFT.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>
    let storefront: &NFTStoreFront.Storefront

    prepare(account: AuthAccount) {
        // We need a provider capability, but one is not provided by default so we create one if needed.
        let nowggNftsCollectionProviderPrivatePath = /private/NowggNFTsCollectionProvider

        self.flowReceiver = account.getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(/public/flowTokenReceiver)!

        assert(self.flowReceiver.borrow() != nil, message: "Missing or mis-typed FLOW receiver")

        if !account.getCapability<&NowggNFT.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(nowggNftsCollectionProviderPrivatePath)!.check() {
            account.link<&NowggNFT.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(nowggNftsCollectionProviderPrivatePath, target: NowggNFT.CollectionStoragePath)
        }

        self.nowggNftsProvider = account.getCapability<&NowggNFT.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(nowggNftsCollectionProviderPrivatePath)!

        assert(self.nowggNftsProvider.borrow() != nil, message: "Missing or mis-typed NowggNFT.Collection provider")

        self.storefront = getOrCreateStorefront(account: account)
    }

    execute {
        var index = 0
        let platformAccount = getAccount(platformAddress)
        let platformFlowReceiver = platformAccount.getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(/public/flowTokenReceiver)!

        for saleItemID in saleItemIDs {
            
            let saleCuts = [
                NFTStoreFront.SaleCut(receiver: platformFlowReceiver, amount: saleItemPrices[index] * platformCutPercent)
                NFTStoreFront.SaleCut(receiver: self.flowReceiver, amount: saleItemPrices[index] * (1.0 - platformCutPercent))
            ]

            self.storefront.createListing(
                nftProviderCapability: self.nowggNftsProvider,
                nftType: Type<@NowggNFT.NFT>(),
                nftID: saleItemID,
                salePaymentVaultType: Type<@FlowToken.Vault>(),
                saleCuts: saleCuts
            )
            index = index + 1
        }
    }
}
