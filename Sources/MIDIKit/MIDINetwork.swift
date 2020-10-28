//
//  MIDINetwork.swift
//  
//
//  Created by Michele Longhi on 28/10/2020.
//

import Foundation
import CoreMIDI

extension MIDIClient {
    
    public convenience init(name: String, networkConnection connection: MIDINetworkConnection) {
        self.init(name: name)
        
        startWithNetworkConnection(connection)
    }
    
    public func startWithNetworkConnection(_ connection: MIDINetworkConnection) {
        
        removeAllNetworkConnections()
        
        networkSession = MIDINetworkSession()
        networkSession?.addConnection(connection)
        
        lastKnownConnection = connection
        
        try? start()
    }

    public func startWithFirstAvailableNetworkConnection(useLastKnownConnection: Bool = true, completion handler: ((_ connection: MIDINetworkConnection?)->Void)? = nil) {
        
        removeAllNetworkConnections()
        
        let networkSession = self.networkSession ?? MIDINetworkSession()
        
        if let connection = lastKnownConnection, useLastKnownConnection {
            networkSession.addConnection(connection)
            try? start()

            handler?(connection)
            return
        }
    
        bonjourService.findService(BonjourService.Services.Apple_Midi, domain: BonjourService.LocalDomain) { services in
            
            if let service = services.first, let hostName = service.hostName {
                
                let connection = MIDINetworkConnection(host: .init(name: service.name, address: hostName, port: service.port))
                networkSession.addConnection(connection)
                try? self.start()

                self.lastKnownConnection = connection
                handler?(connection)
            } else {
                handler?(nil)
            }
        }
    }
    
    public var networkSourceEndpoint: MIDIEndpoint? {
        if let endpoint = networkSession?.sourceEndpoint() {
            return MIDIEndpoint(endpoint)
        }
        return nil
    }
    
    public var networkDestinationEndpoint: MIDIEndpoint? {
        if let endpoint = networkSession?.destinationEndpoint() {
            return MIDIEndpoint(endpoint)
        }
        return nil
    }
    
    public func removeAllNetworkConnections() {
        for connection in networkSession?.connections() ?? [] {
            networkSession?.removeConnection(connection)
        }
    }
    
    public private(set) var lastKnownConnection: MIDINetworkConnection? {
        get {
            let ud = UserDefaults.standard
            
            if let name = ud.string(forKey: "MIDIKit-networkConnection-name"),
               let hostName  = ud.string(forKey: "MIDIKit-networkConnection-host-name") {
                
                let port = ud.integer(forKey: "MIDIKit-networkConnection-host-port")
                
                return MIDINetworkConnection(host: .init(name: name, address: hostName, port: port))
            }
            
            return nil
        }
        set {
            let ud = UserDefaults.standard
            if let connection = newValue {
                ud.setValue(connection.host.name, forKey: "MIDIKit-networkConnection-name")
                ud.setValue(connection.host.address, forKey: "MIDIKit-networkConnection-host-name")
                ud.setValue(connection.host.port, forKey: "MIDIKit-networkConnection-host-port")
            } else {
                ud.removeObject(forKey: "MIDIKit-networkConnection-name")
                ud.removeObject(forKey: "MIDIKit-networkConnection-host-name")
                ud.removeObject(forKey: "MIDIKit-networkConnection-host-port")
            }
            ud.synchronize()
        }
    }
}

public class BonjourService: NSObject, NetServiceBrowserDelegate, NetServiceDelegate {
    
    var timeout: TimeInterval = 1.0
    var serviceFoundClosure: (([NetService]) -> Void)!
    var domainFoundClosure: (([String]) -> Void)!

    public struct Services {
        public static let Apple_Midi: String = "_apple-midi._udp."
    }
    public static let LocalDomain: String = "local."

    public let serviceBrowser: NetServiceBrowser = NetServiceBrowser()
    public var services = [NetService]()
    public var domains = [String]()
    public var isSearching: Bool = false
    public var serviceTimeout: Timer = Timer()
    public var domainTimeout: Timer = Timer()
    
    var servicesToResolve = 0

    @discardableResult
    public func findService(_ identifier: String, domain: String, found: @escaping ([NetService]) -> Void) -> Bool {
        if !isSearching {
            serviceBrowser.delegate = self
            serviceTimeout = Timer.scheduledTimer(
                timeInterval: self.timeout,
                target: self,
                selector: #selector(BonjourService.noServicesFound),
                userInfo: nil,
                repeats: false)
            serviceBrowser.searchForServices(ofType: identifier, inDomain: domain)
            serviceFoundClosure = found
            isSearching = true
            return true
        }
        return false
    }

    public func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService,
                           moreComing: Bool) {
        serviceTimeout.invalidate()
        services.append(service)
        service.delegate = self
        service.resolve(withTimeout: 2)
        servicesToResolve += 1
        if !moreComing {
        }
    }
    
    public func netServiceDidResolveAddress(_ sender: NetService) {
        
        servicesToResolve -= 1

        if servicesToResolve == 0 {
            serviceFoundClosure(services)
            serviceBrowser.stop()
            isSearching = false
        }
    }
    
    public func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]) {
        
        servicesToResolve -= 1

        if servicesToResolve == 0 {
            serviceFoundClosure(services)
            serviceBrowser.stop()
            isSearching = false
        }
    }

    @objc func noServicesFound() {
        serviceFoundClosure([])
        serviceBrowser.stop()
        isSearching = false
    }

    public func netServiceBrowser(_ browser: NetServiceBrowser, didFindDomain domainString: String,
                           moreComing: Bool) {
        domainTimeout.invalidate()
        domains.append(domainString)
        if !moreComing {
            domainFoundClosure(domains)
            serviceBrowser.stop()
            isSearching = false
        }
    }
}

