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
import ShadowSwift
import SwiftHexTools
import Transmission

public class RendezvousServer
{
    var runloop: Thread? = nil
    let server: ShadowServer
    let nametag: Nametag

    public init(host: String, port: Int, key: PublicKey, logger: Logger) throws
    {
        guard let keyData = key.data else
        {
            throw RendezvousServerError.couldNotEncodeKey
        }

        let config = ShadowConfig(key: keyData.hex, serverIP: host, port: UInt16(port), mode: .DARKSTAR)
        guard let server = ShadowServer(host: host, port: port, config: config, logger: logger) else
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

                    self.handleConnection(connection)
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

    func handleConnection(_ connection: Transmission.Connection)
    {

    }
}

public enum RendezvousServerError: Error
{
    case listenFailed
    case nametagFailed
    case couldNotEncodeKey
}
