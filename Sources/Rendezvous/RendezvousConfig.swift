//
//  RendezvousConfig.swift
//  
//
//  Created by Dr. Brandon Wiley on 10/16/22.
//

import Foundation

import Keychain

public struct RendezvousConfig: Codable
{
    public let host: String
    public let port: Int
    public let publicKey: PublicKey

    public init(host: String, port: Int, publicKey: PublicKey)
    {
        self.host = host
        self.port = port
        self.publicKey = publicKey
    }
}

