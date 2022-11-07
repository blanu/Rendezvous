//
//  RendezvousServer.swift
//  
//
//  Created by Dr. Brandon Wiley on 10/4/22.
//

import Foundation
import Logging

import Chord
import Keychain
import Nametag
import Rendezvous
import ShadowSwift
import SwiftHexTools
import Transmission

public class RendezvousServer
{
    let config: Config
    let logger: Logger
    let server: ShadowServer
    let nametag: Nametag
    var connections: [UUID: ServerConnection] = [:]
    let multiqueue: MultiQueue<Message> = MultiQueue<Message>()
    let routing = RoutingController()
    var acceptLoop: Thread? = nil
    var readLoop: Thread? = nil

    public init(config: Config, logger: Logger) throws
    {
        self.config = config
        self.logger = logger

        guard let keyData = self.config.identity.object.data else
        {
            throw RendezvousServerError.couldNotEncodeKey
        }

        let config = ShadowConfig(key: keyData.hex, serverIP: self.config.host, port: UInt16(self.config.port), mode: .DARKSTAR)
        guard let server = ShadowServer(host: self.config.host, port: self.config.port, config: config, logger: logger) else
        {
            throw RendezvousServerError.listenFailed
        }
        self.server = server

        guard let nametag = Nametag() else
        {
            throw RendezvousServerError.nametagFailed
        }
        self.nametag = nametag
    }

    public func start()
    {
        self.acceptLoop = Thread
        {
            while true
            {
                do
                {
                    let connection = try self.server.accept()

                    do
                    {
                        let uuid = UUID()
                        let serverConnection = try ServerConnection(network: connection, logger: self.logger)
                        try self.routing.addDirect(identity: serverConnection.clientIdentity, connection: serverConnection)

                        let producer = MessageProducer(multi: self.multiqueue, connection: serverConnection)
                        self.multiqueue.add(producer)
                        self.connections[uuid] = serverConnection
                    }
                    catch
                    {
                        print("Error handling connection")
                        return
                    }
                }
                catch
                {
                    if let runloop = self.acceptLoop
                    {
                        runloop.cancel()
                        self.acceptLoop = nil
                    }
                }
            }
        }

        self.readLoop = Thread
        {
            while true
            {
                let message = self.multiqueue.dequeue()

                switch message
                {
                    case .reachable(let reachable):
                        self.routing.addIndirect(identity: reachable.identity, location: reachable.location)

                    case .routedDocument(let routed):
                        if let route = self.routing.find(identity: routed.to)
                        {
                            route.write(message: routed)
                        }
                        else
                        {
                            print("No know route for \(message.to)")
                            continue
                        }
                }
            }
        }
    }

    public func shutdown()
    {
        if let runloop = self.acceptLoop
        {
            runloop.cancel()
            self.acceptLoop = nil
        }
    }
}

public enum RendezvousServerError: Error
{
    case listenFailed
    case nametagFailed
    case couldNotEncodeKey
}
