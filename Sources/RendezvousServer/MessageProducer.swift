//
//  MessageProducer.swift
//  
//
//  Created by Dr. Brandon Wiley on 10/25/22.
//

import Foundation

import Chord
import Nametag
import Rendezvous

public class MessageProducer: Producer<Message>
{
    let connection: RendezvousConnection

    public init(multi: MultiQueue<Message>, connection: RendezvousConnection)
    {
        self.connection = connection

        super.init(multi: multi)
    }

    override public func read() throws -> Message
    {
        let document: EndorsedTypedDocument<Message> = try AsyncAwaitThrowingSynchronizer<EndorsedTypedDocument<Message>>.sync(self.connection.read)
        let message = document.object
        try message.verify(signature: document.signed)
        return message
    }

    override public func cleanup()
    {
        AsyncAwaitThrowingEffectSynchronizer.sync(self.connection.close)
    }
}
