//
//  Identity.swift
//  
//
//  Created by Dr. Brandon Wiley on 10/17/22.
//

import Foundation

import Keychain
import Nametag

public typealias PublicIdentity = EndorsedTypedDocument<PublicKey>

public struct PrivateIdentity
{
    public let keyAgreement: PrivateKey
    public let nametag: Nametag
    public let publicIdentity: PublicIdentity

    public init(keyAgreement: PrivateKey, nametag: Nametag) throws
    {
        self.keyAgreement = keyAgreement
        self.nametag = nametag

        let publicKey = self.keyAgreement.publicKey
        self.publicIdentity = try self.nametag.endorse(object: publicKey)
    }
}
