//
//  MIDINetwork.swift
//  
//
//  Created by Michele Longhi on 28/10/2020.
//

import Foundation
import CoreMIDI

@available(iOS 4.2, macOS 10.15, *)
public class MIDINetworkClient: MIDIClient {
    
    public private(set) var networkSession: MIDINetworkSession?

    public init(name: String, connections: [MIDINetworkConnection], delegate: MIDIClientDelegate? = nil) {
        super.init(name: name)
        
        networkSession = MIDINetworkSession()

        self.delegate = delegate
        
        for connection in connections {
            addConnection(connection)
        }
    }
    
    public convenience init(name: String, connection: MIDINetworkConnection? = nil, delegate: MIDIClientDelegate? = nil) {
        if let connection = connection {
            self.init(name: name, connections: [connection], delegate: delegate)
        } else {
            self.init(name: name, connections: [], delegate: delegate)
        }
    }
    
    private var connections: Set<MIDINetworkConnection> {
        networkSession?.connections() ?? []
    }
    
    private func addConnection(_ connection: MIDINetworkConnection) {
        networkSession?.addConnection(connection)
    }

    private func removeConnection(_ connection: MIDINetworkConnection) {
        networkSession?.removeConnection(connection)
    }

    public func removeAllConnections() {
        for connection in connections {
            networkSession?.removeConnection(connection)
        }
    }

    public var sourceEndpoint: MIDIEndpoint? {
        if let endpoint = networkSession?.sourceEndpoint() {
            return MIDIEndpoint(endpoint)
        }
        return nil
    }
    
    public var destinationEndpoint: MIDIEndpoint? {
        if let endpoint = networkSession?.destinationEndpoint() {
            return MIDIEndpoint(endpoint)
        }
        return nil
    }
    
    deinit {
        removeAllConnections()
    }
}
