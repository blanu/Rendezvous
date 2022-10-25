//
//  RendezvousServer.swift
//  
//
//  Created by Dr. Brandon Wiley on 10/4/22.
//

import Foundation
import Logging

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
    var runloop: Thread? = nil
    let server: ShadowServer
    let nametag: Nametag
    let routing = RoutingController()
    var threads: [UUID: ServerConnection] = [:]

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
        self.runloop = Thread
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
                        self.threads[uuid] = serverConnection
                    }
                    catch
                    {
                        print("Error handling connection")
                        return
                    }
                }
                catch
                {
                    if let runloop = self.runloop
                    {
                        runloop.cancel()
                        self.runloop = nil
                    }
                }
            }
        }
    }

    public func shutdown()
    {
        if let runloop = self.runloop
        {
            runloop.cancel()
            self.runloop = nil
        }
    }
}

public enum RendezvousServerError: Error
{
    case listenFailed
    case nametagFailed
    case couldNotEncodeKey
}
