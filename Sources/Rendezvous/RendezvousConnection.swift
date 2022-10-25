//
//  RendezvousConnection.swift
//  
//
//  Created by Dr. Brandon Wiley on 10/24/22.
//

import Foundation

import Nametag

public protocol RendezvousConnection
{
    func write(message: EndorsedTypedDocument<Message>) async throws -> Bool
    func read() async throws -> EndorsedTypedDocument<Message>
    func close() async throws
}
