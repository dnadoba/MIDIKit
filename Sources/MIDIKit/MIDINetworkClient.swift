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

    public override init(name: String) {
        networkSession = MIDINetworkSession()
        super.init(name: name)
        
        for connection in connections {
            addConnection(connection)
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
