//
//  Config.swift
//  
//
//  Created by Dr. Brandon Wiley on 10/16/22.
//

import Foundation

import Datable
import Keychain
import Net

public struct Config: Codable
{
    public let name: String
    public let host: String
    public let port: Int
    public let identity: PublicIdentity

//    public var compact: Data
//    {
//        let ipv4 = IPv4Address(string: host)
//        let port16 = UInt16(port)
//    }

    public init(name: String, host: String, port: Int, identity: PublicIdentity)
    {
        self.name = name
        self.host = host
        self.port = port
        self.identity = identity
    }
}

