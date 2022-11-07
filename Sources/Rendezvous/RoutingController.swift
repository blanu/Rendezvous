//
//  RoutingController.swift
//  
//
//  Created by Dr. Brandon Wiley on 10/16/22.
//

import Foundation

import Abacus
import Chord
import Keychain
import Nametag
import Transmission

public actor RoutingController
{
    var direct: [PublicKey: RendezvousConnection] = [:]
    var indirect: [PublicKey: PublicKey] = [:]

    public init()
    {
    }

    public func addDirect(identity: PublicKey, connection: RendezvousConnection) async throws
    {
        if let oldConnection = self.direct[identity]
        {
            try await oldConnection.close()

            self.remove(identity: identity)
        }

        self.direct[identity] = connection
    }

    public func addIndirect(identity: PublicKey, location: PublicKey)
    {
        guard self.direct[identity] == nil else
        {
            return
        }

        guard self.direct[location] != nil else
        {
            return
        }

        self.indirect[identity] = location
    }

    public func find(identity: PublicKey) -> RendezvousConnection?
    {
        if let result = self.direct[identity]
        {
            return result
        }
        else
        {
            if let location = self.indirect[identity]
            {
                if let result = self.direct[location]
                {
                    return result
                }
            }
        }

        return nil
    }

    public func remove(identity: PublicKey)
    {
        guard self.direct[identity] != nil else
        {
            return
        }

        self.direct.removeValue(forKey: identity)
        self.indirect = self.indirect.filter { $0.value != identity }
    }
}
