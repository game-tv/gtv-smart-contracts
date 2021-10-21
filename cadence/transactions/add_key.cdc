transaction(publicKeys: [String]) {
    prepare(signer: AuthAccount) {
        for publicKey in publicKeys {
            let key = PublicKey(
                publicKey: publicKey.decodeHex(),
                signatureAlgorithm: SignatureAlgorithm.ECDSA_P256
            )
            
            signer.keys.add(
                publicKey: key,
                hashAlgorithm: HashAlgorithm.SHA3_256,
                weight: 10.0 as UFix64
            )
        }
    }
}	
