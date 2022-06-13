import FungibleToken from "../contracts/FungibleToken.cdc"
import FlowToken from "../contracts/FlowToken.cdc"

transaction(amount: UFix64, to: Address) {
  let sentVault: @FungibleToken.Vault

  prepare(signer: AuthAccount) {
    assert(signer.type(at: /storage/flowTokenVault) != nil, message: "Cannot borrow reference to owner's vault")
    let vaultRef = signer.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)
    self.sentVault <- vaultRef.withdraw(amount: amount)
  }

  execute {
    let recipient = getAccount(to)
    let receiverRef = recipient.getCapability(/public/flowTokenReceiver).borrow<&{FungibleToken.Receiver}>()
      ?? panic("Could not borrow receiver reference to the recipient's Vault")
    receiverRef.deposit(from: <-self.sentVault)
  }
}
