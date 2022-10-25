//
//  RendezvousServerCommandLine.swift
//  
//
//  Created by Dr. Brandon Wiley on 10/4/22.
//

import ArgumentParser
import Lifecycle
import Foundation

#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
#else
import FoundationNetworking
#endif

import Logging
import NIO

import Gardener
import Keychain
import Nametag
import Rendezvous
import Transmission

@main
struct RendezvousServerCommandLine: ParsableCommand
{
    static let configuration = CommandConfiguration(
        commandName: "rendezvous-server",
        subcommands: [New.self, Run.self]
    )
}

struct New: ParsableCommand
{
    @Argument(help: "Human-readable name for your server to use in invites")
    var name: String

    @Argument(help: "Port on which to run the server")
    var port: Int

    mutating public func run() throws
    {
        let ip: String = try Ipify.getPublicIP()

        if let test = TransmissionConnection(host: ip, port: port)
        {
            test.close()

            throw NewCommandError.portInUse
        }

        #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
        let keychain = Keychain()
        #else
        guard let keychain = Keychain(baseDirectory: File.homeDirectory().appendingPathComponent(".rendezvous-server")) else
        {
            throw NewCommandError.couldNotLoadKeychain
        }
        #endif

        guard let privateKeyKeyAgreement = keychain.generateAndSavePrivateKey(label: "Rendezvous.KeyAgreement", type: .P256KeyAgreement) else
        {
            throw NewCommandError.couldNotGeneratePrivateKey
        }

        guard let nametag = Nametag() else
        {
            throw NewCommandError.nametagError
        }

        let privateIdentity = try PrivateIdentity(keyAgreement: privateKeyKeyAgreement, nametag: nametag)
        let publicIdentity = privateIdentity.publicIdentity

        let config = Config(name: name, host: ip, port: port, identity: publicIdentity)
        let encoder = JSONEncoder()
        let configData = try encoder.encode(config)
        let configURL = URL(fileURLWithPath: File.currentDirectory()).appendingPathComponent("rendezvous-config.json")
        try configData.write(to: configURL)
        print("Wrote config to \(configURL.path)")
    }
}

struct Run: ParsableCommand
{
    mutating func run() throws
    {
        let logger = Logger(label: "Rendezvous")

        let configURL = URL(fileURLWithPath: File.currentDirectory()).appendingPathComponent("rendezvous-config.json")
        let configData = try Data(contentsOf: configURL)
        let decoder = JSONDecoder()
        let config = try decoder.decode(Config.self, from: configData)
        print("Read config from \(configURL.path)")

        let lifecycle = ServiceLifecycle()

        let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        lifecycle.registerShutdown(label: "eventLoopGroup", .sync(eventLoopGroup.syncShutdownGracefully))

        let server = try RendezvousServer(config: config, logger: logger)
        lifecycle.register(label: "server", start: .sync(server.start), shutdown: .sync(server.shutdown))

        lifecycle.start
        {
            error in

            if let error = error
            {
                logger.error("failed starting rendezvous-server ☠️: \(error)")
            }
            else
            {
                logger.info("rendezvous-server started successfully 🚀")
            }
        }

        lifecycle.wait()
    }
}

public enum NewCommandError: Error
{
    case portInUse
    case couldNotGeneratePrivateKey
    case couldNotLoadKeychain
    case nametagError
}
