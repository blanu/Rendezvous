//
//  ServerConnection.swift
//  
//
//  Created by Dr. Brandon Wiley on 10/24/22.
//

import Foundation

import Foundation
import Logging

import Chord
import Datable
import Keychain
import Nametag
import Rendezvous
import ShadowSwift
import Straw
import Transmission

// A connection to a server
public actor ServerConnection: RendezvousConnection
{
    public let clientIdentity: PublicKey
    
    let network: Transmission.Connection
    let logger: Logger

    let nametag: Nametag
    var open = true

    public init(network: Transmission.Connection, logger: Logger) throws
    {
        self.network = network
        self.logger = logger

        guard let nametag = Nametag() else
        {
            throw ClientConnectionError.nametagInitFailed
        }
        self.nametag = nametag

        try self.nametag.proveLive(connection: self.network)

        self.clientIdentity = try self.nametag.checkLive(connection: self.network)
    }

    public func write(message: EndorsedTypedDocument<Message>) -> Bool
    {
        guard self.open else
        {
            return false
        }

        return self.network.writeWithLengthPrefix(data: message.data, prefixSizeInBits: Rendezvous.prefixSize)
    }

    public func read() throws -> EndorsedTypedDocument<Message>
    {
        guard self.open else
        {
            throw ClientConnectionError.closed
        }

        guard let data = self.network.readWithLengthPrefix(prefixSizeInBits: Rendezvous.prefixSize) else
        {
            throw ClientConnectionError.readFailed
        }

        guard let document = EndorsedTypedDocument<Message>(data: data) else
        {
            throw ClientConnectionError.couldNotLoadDocument
        }

        return document
    }

    public func close() throws
    {
        guard self.open else
        {
            throw ClientConnectionError.closed
        }

        self.network.close()
    }
}

public enum ClientConnectionError: Error
{
    case readFailed
    case couldNotLoadDocument
    case keyEncodingFailed
    case nametagInitFailed
    case connectionFailed
    case serverSigningKeyMismatch
    case writeFailed
    case closed
}
