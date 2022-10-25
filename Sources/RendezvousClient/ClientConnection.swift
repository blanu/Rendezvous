//
//  RendezvousClientConnection.swift
//  
//
//  Created by Dr. Brandon Wiley on 10/4/22.
//

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
public actor ClientConnection: RendezvousConnection
{
    let logger: Logger
    let nametag: Nametag
    let network: Transmission.Connection
    let straw = Straw()
    var open = true

    public init(config: Config, logger: Logger) throws
    {
        self.logger = logger

        guard let keyData = config.identity.signed.publicKey.data else
        {
            throw ClientConnectionError.keyEncodingFailed
        }

        guard let nametag = Nametag() else
        {
            throw ClientConnectionError.nametagInitFailed
        }
        self.nametag = nametag

        let port16 = UInt16(config.port)
        let shadowConfig = ShadowConfig(key: keyData.hex, serverIP: config.host, port: port16, mode: .DARKSTAR)
        guard let network = ShadowTransmissionClientConnection(host: config.host, port: config.port, config: shadowConfig, logger: logger) else
        {
            throw ClientConnectionError.connectionFailed
        }
        self.network = network

        guard try self.nametag.checkLive(connection: self.network) == config.identity.signed.publicKey else
        {
            throw ClientConnectionError.serverSigningKeyMismatch
        }

        try self.nametag.proveLive(connection: self.network)
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
