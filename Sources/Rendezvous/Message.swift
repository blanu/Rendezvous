//
//  Message.swift
//  
//
//  Created by Dr. Brandon Wiley on 10/4/22.
//

import Foundation

import Keychain
import Nametag

public enum Message: Codable
{
    case reachable(Reachable)
    case routedDocument(RoutedDocument)
}

extension Message
{
    public func verify(signature: SignaturePage) throws
    {
        switch self
        {
            case .reachable(let message):
                try message.verify(signature: signature)

            case .routedDocument(let message):
                try message.verify(signature: signature)
        }
    }
}

extension Message: Equatable
{
    public static func == (lhs: Message, rhs: Message) -> Bool
    {
        switch lhs
        {
            case .reachable(let lm):
                switch rhs
                {
                    case .reachable(let rm):
                        return lm == rm

                    default:
                        return false
                }

            case .routedDocument(let lm):
                switch rhs
                {
                    case .routedDocument(let rm):
                        return lm == rm

                    default:
                        return false
                }
        }
    }
}

public struct Reachable: Codable, Equatable
{
    static public let day: TimeInterval = 60 * 60 * 24 // 60 seconds * 60 minutes * 24 hours = 1 day (86400)

    public let identity: PublicKey
    public let location: PublicKey
    public let timestamp: Date

    public func verify(signature: SignaturePage) throws
    {
        guard signature.publicKey == self.identity else
        {
            throw RendezvousMessageError.badReachableMessage
        }

        let now = Date()
        guard now.timeIntervalSince(self.timestamp) < Reachable.day else
        {
            throw RendezvousMessageError.badReachableMessage
        }
    }
}

public struct RoutedDocument: Codable, Equatable
{
    public let from: PublicKey
    public let to: PublicKey
    public let data: Data

    public init(from: PublicKey, to: PublicKey, data: Data)
    {
        self.from = from
        self.to = to
        self.data = data
    }

    public func verify(signature: SignaturePage) throws
    {
        guard signature.publicKey == from else
        {
            throw RendezvousMessageError.badRoutedDocument
        }
    }
}

public enum RendezvousMessageError: Error
{
    case badReachableMessage
    case badRoutedDocument
}
