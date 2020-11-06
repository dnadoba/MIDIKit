//
//  MIDINetwork.swift
//  
//
//  Created by Michele Longhi on 28/10/2020.
//

import Foundation
import CoreMIDI

#if os(iOS)
public class MIDINetworkClient: MIDIClient {
    
    public private(set) var networkSession: MIDINetworkSession

    public init(name: String, connections: [MIDINetworkConnection]) {
        networkSession = MIDINetworkSession()
        super.init(name: name)
        
        for connection in connections {
            addConnection(connection)
        }
    }
    
    public convenience init(name: String, connection: MIDINetworkConnection? = nil) {
        if let connection = connection {
            self.init(name: name, connections: [connection])
        } else {
            self.init(name: name, connections: [])
        }
    }
    
    public var connections: Set<MIDINetworkConnection> {
        networkSession.connections()
    }
    
    @discardableResult
    public func addConnection(_ connection: MIDINetworkConnection) -> Bool {
        networkSession.addConnection(connection)
    }
    
    @discardableResult
    public func removeConnection(_ connection: MIDINetworkConnection) -> Bool {
        networkSession.removeConnection(connection)
    }

    public func removeAllConnections() {
        for connection in connections {
            networkSession.removeConnection(connection)
        }
    }

    public var sourceEndpoint: MIDIEndpoint? { MIDIEndpoint(networkSession.sourceEndpoint()) }
    public var destinationEndpoint: MIDIEndpoint? { MIDIEndpoint(networkSession.destinationEndpoint()) }
    
    deinit {
        removeAllConnections()
    }
}
#endif
