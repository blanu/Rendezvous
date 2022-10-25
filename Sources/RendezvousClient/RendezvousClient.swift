//
//  RendezvousClient.swift
//  
//
//  Created by Dr. Brandon Wiley on 10/17/22.
//

import Foundation
import Logging

import Nametag
import Rendezvous
import Transmission

public actor RendezvousClient
{
    let logger: Logger
    let nametag: Nametag
    let routing: RoutingController

    public init?(logger: Logger)
    {
        self.logger = logger

        guard let nametag = Nametag() else
        {
            return nil
        }
        self.nametag = nametag

        self.routing = RoutingController()
    }

    public func connect(config: Config) async throws -> ClientConnection
    {
        let connection = try ClientConnection(config: config,logger: self.logger)
        try await self.routing.addDirect(identity: config.identity.object, connection: connection)
        return connection
    }

    public func read(connection: ClientConnection) async throws -> RoutedDocument
    {
        do
        {
            return try await self.readMessage(connection: connection)
        }
        catch
        {
            do
            {
                try await connection.close()
            }
            catch
            {
                print("Failed to close network connection")
            }

            throw RendezvousClientError.readFailed
        }
    }

    func readMessage(connection: ClientConnection) async throws -> RoutedDocument
    {
        let document = try await connection.read()
        let message = document.object
        try message.verify(signature: document.signed)

        switch message
        {
            case .reachable:
                throw RendezvousClientError.unhandledMessage

            case .routedDocument(let document):
                guard document.to == self.nametag.publicKey else
                {
                    print("Misrouted message is not for me")
                    throw RendezvousClientError.misroutedMessage
                }

                return document
        }
    }
}

public enum RendezvousClientError: Error
{
    case unhandledMessage
    case misroutedMessage
    case readFailed
}
