//
//  MIDIKit.swift
//  MIDIKit
//
//  Created by David Nadoba on 30.03.19.
//  Copyright © 2019 David Nadoba. All rights reserved.
//

import Foundation
import Darwin
import CoreMIDI

extension MIDINotificationMessageID: CustomStringConvertible {
    public var description: String {
        switch self {
        case .msgSetupChanged: return "msgSetupChanged"
        case .msgObjectAdded: return "msgObjectAdded"
        case .msgObjectRemoved: return "msgObjectRemoved"
        case .msgPropertyChanged: return "msgPropertyChanged"
        case .msgThruConnectionsChanged: return "msgThruConnectionsChanged"
        case .msgSerialPortOwnerChanged: return "msgSerialPortOwnerChanged"
        case .msgIOError: return "msgIOError"
        @unknown default: return "unknown"
        }
    }
}

extension MIDIObjectType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .other: return "other"
        case .device: return "device"
        case .entity: return "entity"
        case .source: return "source"
        case .destination: return "destination"
        case .externalDevice: return "externalDevice"
        case .externalEntity: return "externalEntity"
        case .externalSource: return "externalSource"
        case .externalDestination: return "externalDestination"
        @unknown default: return "unknown"
        }
    }
}

public enum MIDIError: String, Error {
    case midiInvalidClient = "An invalid MIDIClientRef was passed."
    case midiInvalidPort = "An invalid MIDIPortRef was passed."
    case midiWrongEndpointType = "A source endpoint was passed to a function expecting a destination, or vice versa."
    case midiNoConnection = "Attempt to close a non-existant connection."
    case midiUnknownEndpoint = "An invalid MIDIEndpointRef was passed."
    case midiUnknownProperty = "Attempt to query a property not set on the object."
    case midiWrongPropertyType = "Attempt to set a property with a value not of the correct type."
    case midiNoCurrentSetup = "Internal error; there is no current MIDI setup object."
    case midiMessageSendErr = "Communication with MIDIServer failed."
    case midiServerStartErr = "Unable to start MIDIServer."
    case midiSetupFormatErr = "Unable to read the saved state."
    case midiWrongThread = "A driver is calling a non-I/O function in the server from a thread other than the server's main thread."
    case midiObjectNotFound = "The requested object does not exist."
    case midiIDNotUnique = "Attempt to set a non-unique kMIDIPropertyUniqueID on an object."
    case midiNotPermitted = "The process does not have privileges for the requested operation."
    case midiUnknownError = "Internal error; unable to perform the requested operation."
    public init(_ error: OSStatus) {
        switch error {
        case kMIDIInvalidClient: self = .midiInvalidClient
        case kMIDIInvalidPort: self = .midiInvalidPort
        case kMIDIWrongEndpointType: self = .midiWrongEndpointType
        case kMIDINoConnection: self = .midiNoConnection
        case kMIDIUnknownEndpoint: self = .midiUnknownEndpoint
        case kMIDIUnknownProperty: self = .midiUnknownProperty
        case kMIDIWrongPropertyType: self = .midiWrongPropertyType
        case kMIDINoCurrentSetup: self = .midiNoCurrentSetup
        case kMIDIMessageSendErr: self = .midiMessageSendErr
        case kMIDIServerStartErr: self = .midiServerStartErr
        case kMIDISetupFormatErr: self = .midiSetupFormatErr
        case kMIDIWrongThread: self = .midiWrongThread
        case kMIDIObjectNotFound: self = .midiObjectNotFound
        case kMIDIIDNotUnique: self = .midiIDNotUnique
        case kMIDINotPermitted: self = .midiNotPermitted
        case kMIDIUnknownError: self = .midiUnknownError
        default: self = .midiUnknownError
        }
    }
}

extension MIDIError {
    public static func validateNoError(_ status: OSStatus) throws {
        guard status == noErr else {
            throw MIDIError(status)
        }
    }
}

fileprivate enum MIDIObjectProperty {
    
}

public protocol MIDIObjectProtocol {
    var ref: MIDIObjectRef { get }
}

// MAKR: Utility functions
extension MIDIObjectProtocol {
    public func getProperty(for key: CFString) throws -> String {
        var param: Unmanaged<CFString>?
        let err: OSStatus = MIDIObjectGetStringProperty(ref, key, &param)
        guard err == noErr else {
            throw MIDIError(err)
        }
        return param!.takeRetainedValue() as String
    }
    public func getProperty(for key: CFString) throws -> Int32 {
        var param: MIDIUniqueID = 0
        let err: OSStatus = MIDIObjectGetIntegerProperty(ref, key, &param)
        guard err == noErr else {
            throw MIDIError(err)
        }
        return param
    }
}

extension MIDIObjectProtocol {
    public var name: String? { return try? getProperty(for: kMIDIPropertyName) }
    fileprivate var uniqueID: MIDIUniqueID? { return try? getProperty(for: kMIDIPropertyUniqueID) }
}


public struct MIDIDevice: MIDIObjectProtocol, Hashable {
    public struct Identifier: Hashable, Codable {
        private let uniqueID: MIDIUniqueID
        public init(uniqueID: MIDIUniqueID) { self.uniqueID = uniqueID }
    }
    public let ref: MIDIDeviceRef
    public init?(_ ref: MIDIEntityRef) {
        guard ref != 0 else { return nil }
        self.ref = ref
    }
}

extension MIDIDevice {
    public static func getAll() -> [MIDIDevice] {
        return (0..<MIDIGetNumberOfDevices())
            .map(MIDIGetDevice)
            .compactMap(MIDIDevice.init)
    }
    public func getEntities() -> [MIDIEntity] {
        return (0..<MIDIDeviceGetNumberOfEntities(ref))
            .map { MIDIDeviceGetEntity(ref, $0) }
            .compactMap(MIDIEntity.init)
    }
}

extension MIDIDevice {
    public var identifier: Identifier? {
        return uniqueID.map(Identifier.init)
    }
}

public struct MIDIEntity: MIDIObjectProtocol, Hashable {
    public let ref: MIDIEntityRef
    public init?(_ ref: MIDIEntityRef) {
        guard ref != 0 else { return nil }
        self.ref = ref
    }
}

extension MIDIEntity {
    public var device: MIDIDevice? {
        var deviceRef: MIDIDeviceRef = 0
        guard MIDIEntityGetDevice(ref, &deviceRef) == noErr else { return nil }
        return MIDIDevice(deviceRef)
    }
    public func getSources() -> [MIDIEndpoint] {
        return (0..<MIDIEntityGetNumberOfSources(ref))
            .map{ MIDIEntityGetSource(ref, $0) }
            .compactMap(MIDIEndpoint.init)
    }
    public func getDestinations() -> [MIDIEndpoint] {
        return (0..<MIDIEntityGetNumberOfDestinations(ref))
            .map{ MIDIEntityGetDestination(ref, $0) }
            .compactMap(MIDIEndpoint.init)
    }
}

public struct MIDIEndpoint: MIDIObjectProtocol, Hashable {
    public let ref: MIDIEndpointRef
    public init?(_ ref: MIDIEndpointRef) {
        guard ref != 0 else { return nil }
        self.ref = ref
    }
}

extension MIDIEndpoint {
    public static func getAllSources() -> [MIDIEndpoint] {
        return (0..<MIDIGetNumberOfSources())
            .map(MIDIGetSource)
            .compactMap(MIDIEndpoint.init)
    }
    public static func getAllDestinations() -> [MIDIEndpoint] {
        return (0..<MIDIGetNumberOfDestinations())
            .map(MIDIGetDestination)
            .compactMap(MIDIEndpoint.init)
    }
}

extension MIDIEndpoint {
    public var displayName: String? { return try? getProperty(for: kMIDIPropertyDisplayName)}
    
    public var entity: MIDIEntity? {
        var entityRef = MIDIEndpointRef()
        guard MIDIEndpointGetEntity(ref, &entityRef) == noErr else { return nil }
        return MIDIEntity(entityRef)
    }
}

public enum MIDIObject {
    case other(MIDIObjectRef)
    case device(MIDIDevice)
    case entity(MIDIEntity)
    case source(MIDIEndpoint)
    case destination(MIDIEndpoint)
    case externalDevice(MIDIObjectRef)
    case externalEntity(MIDIObjectRef)
    case externalSource(MIDIObjectRef)
    case externalDestination(MIDIObjectRef)
}

extension MIDIObject {
    init(ref: MIDIObjectRef, type: MIDIObjectType) {
        switch type {
        case .other:
            self = .other(ref)
        case .device:
            self = .device(MIDIDevice(ref)!)
        case .entity:
            self = .entity(MIDIEntity(ref)!)
        case .source:
            self = .source(MIDIEndpoint(ref)!)
        case .destination:
            self = .destination(MIDIEndpoint(ref)!)
        case .externalDevice:
            self = .externalDevice(ref)
        case .externalEntity:
            self = .externalEntity(ref)
        case .externalSource:
            self = .externalSource(ref)
        case .externalDestination:
            self = .externalDestination(ref)
        @unknown default:
            self = .other(ref)
        }
    }
}
extension MIDIClient.Notification {
    init(_ message: UnsafePointer<MIDINotification>) {
        let messageID = message.pointee.messageID
        switch messageID {
        case .msgSetupChanged:
            self = .setupChanged
        case .msgObjectAdded,
             .msgObjectRemoved:
            self = message.withMemoryRebound(to: MIDIObjectAddRemoveNotification.self, capacity: 1) { (message) in
                let m = message.pointee
                let parent = MIDIObject(ref: m.parent, type: m.parentType)
                let child = MIDIObject(ref: m.child, type: m.childType)
                if messageID == .msgObjectAdded {
                    return .added(parent: parent, child: child)
                } else {
                    return .removed(parent: parent, child: child)
                }
            }
        case .msgPropertyChanged:
            self = message.withMemoryRebound(to: MIDIObjectPropertyChangeNotification.self, capacity: 1) { (message) in
                let m = message.pointee
                return .propertyChanged(of: .init(ref: m.object, type: m.objectType),
                                        propertyName: m.propertyName.takeRetainedValue() as String)
            }
        case .msgThruConnectionsChanged:
            self = .thruConnectionChanged
        case .msgSerialPortOwnerChanged:
            self = .serialPortOwnerChanged
        case .msgIOError:
            self = message.withMemoryRebound(to: MIDIIOErrorNotification.self, capacity: 1) { (message) in
                let m = message.pointee
                return .ioError(device: MIDIDevice(m.driverDevice)!,
                                error: MIDIError(m.errorCode))
            }
        @unknown default:
            fatalError("unknow MIDI message ID")
        }
    }
}


public protocol MIDIClientDelegate: AnyObject {
    func midiClient(_ client: MIDIClient, didRecieve notification: MIDIClient.Notification)
}

public class MIDIClient {
    public enum Notification {
        case setupChanged
        case added(parent: MIDIObject, child: MIDIObject)
        case removed(parent: MIDIObject, child: MIDIObject)
        case propertyChanged(of: MIDIObject, propertyName: String)
        case thruConnectionChanged
        case serialPortOwnerChanged
        case ioError(device: MIDIDevice, error: MIDIError)
    }
    public private(set) var ref: MIDIClientRef = 0
    public let name: String
    public weak var delegate: MIDIClientDelegate?
    public init(name: String) {
        self.name = name
    }
    public func start() throws {
        let status = MIDIClientCreateWithBlock(name as CFString, &ref) { [weak self] (notificationPointer) in
            guard let self = self else { return }
            let notification = MIDIClient.Notification(notificationPointer)
            self.delegate?.midiClient(self, didRecieve: notification)
        }
        guard status == noErr else {
            throw MIDIError(status)
        }
    }
    deinit {
        MIDIClientDispose(ref)
    }
}

extension MIDIClient {
    public func makeOutputPort(name: String) throws -> MIDIOutputPort {
        return try MIDIOutputPort(client: self, name: name)
    }
    public func makeInputPort(name: String, callback: @escaping MIDIInputPort.ReadBlock) throws -> MIDIInputPort {
        return try MIDIInputPort(client: self, name: name, callback: callback)
    }
}

public class MIDIOutputPort {
    public private(set) var ref: MIDIPortRef = 0
    public init(client: MIDIClient, name: String) throws {
        let status = MIDIOutputPortCreate(client.ref, name as CFString, &ref)
        try MIDIError.validateNoError(status)
    }
    deinit {
        MIDIPortDispose(ref)
    }
}

extension Sequence where Element == MIDIMessage {
    public func allocatePackageList(timeStamp: MIDITimeStamp = 0) -> UnsafePointer<MIDIPacketList> {
        let sizeOfAlleMessages = self.size
        assert(sizeOfAlleMessages <= Int(UInt16.max), "allocatePackageList does not support messages bigger than \(UInt16.max)")
        let packetListSize = MemoryLayout<MIDIPacketList>
            .offset(of: \MIDIPacketList.packet.data) ?? 0 + sizeOfAlleMessages
        
        let packetListPointer = UnsafeMutableRawPointer
            .allocate(byteCount: packetListSize,
                      alignment: MemoryLayout<MIDIPacketList>.alignment)
        defer { packetListPointer.deallocate() }
        let packetList = packetListPointer.assumingMemoryBound(to: MIDIPacketList.self)
        packetList.pointee.numPackets = 1
        
        let packetPointer = packetListPointer
            .advanced(by: MemoryLayout<MIDIPacketList>.offset(of: \MIDIPacketList.packet)!)
        let packet = packetPointer.assumingMemoryBound(to: MIDIPacket.self)
        
        packet.pointee.timeStamp = timeStamp
        packet.pointee.length = UInt16(sizeOfAlleMessages)
        
        let data = packetPointer
            .advanced(by: MemoryLayout<MIDIPacket>.offset(of: \MIDIPacket.data)!)
            .assumingMemoryBound(to: UInt8.self)
        
        write(to: data)
        return UnsafePointer(packetList)
    }
}


extension MIDIOutputPort {
    public func send(_ messages: [MIDIMessage], to destination: MIDIEndpoint, timeStamp: MIDITimeStamp = 0) throws {
        let packetList = messages.allocatePackageList(timeStamp: timeStamp)
        defer { packetList.deallocate() }
        try send(packetList, to: destination)
    }
}

extension MIDIOutputPort {
    public func send(_ packetList: UnsafePointer<MIDIPacketList>, to destination: MIDIEndpoint) throws {
        let status = MIDISend(self.ref, destination.ref, packetList)
        try MIDIError.validateNoError(status)
    }
}

public struct MIDIPackage {
    public var source: MIDIEndpoint
    public var timeStamp: MIDITimeStamp
    public var messages: [MIDIMessage]
}

fileprivate class MIDIInputConnection {
    let source: MIDIEndpoint
    var parser = MIDIParser()
    let pointer: UnsafeMutableRawPointer
    
    init(source: MIDIEndpoint) {
        self.source = source
        pointer = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<MIDIInputConnection>.size,
                                                   alignment: MemoryLayout<MIDIInputConnection>.alignment)
        pointer.initializeMemory(as: MIDIInputConnection.self, repeating: self, count: 1)
    }
    deinit {
        pointer.deallocate()
    }
}

extension MIDIInputConnection: Equatable {
    static func ==(lhs: MIDIInputConnection, rhs: MIDIInputConnection) -> Bool {
        return lhs.source == rhs.source
    }
}

extension MIDIInputConnection: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(source)
    }
}

public class MIDIInputPort {
    public typealias Value = MIDIPackage
    public typealias ReadBlock = (Result<Value, Error>) -> ()
    public private(set) var ref: MIDIPortRef = 0
    private var connections: Set<MIDIInputConnection> = []
    private let queue = DispatchQueue(label: "MIDIInputPort", qos: .userInteractive)
    public init(client: MIDIClient, name: String, callback: @escaping ReadBlock) throws {
        let queue = self.queue
        try queue.sync {
            let status = MIDIInputPortCreateWithBlock(client.ref, name as CFString, &ref) { (packetList, endpointRef) in
                guard let endpointRef = endpointRef else {
                    assertionFailure("endpointRef ist nil")
                    return
                }
                
                var packet = UnsafeRawPointer(packetList)
                    .advanced(by: MemoryLayout<MIDIPacketList>.offset(of: \MIDIPacketList.packet)!)
                    .assumingMemoryBound(to: MIDIPacket.self)
                let packetCount = packetList.pointee.numPackets
                let timeStamp = packet.pointee.timeStamp
                
                let parsedPacket = queue.sync { () -> [Result<[MIDIMessage], Error>] in
                    let connection = UnsafeRawPointer(endpointRef).assumingMemoryBound(to: MIDIInputConnection.self).pointee
                    return (0..<packetCount).map { _ -> Result<[MIDIMessage], Error> in
                        let data = UnsafeRawPointer(packet)
                            .advanced(by: MemoryLayout<MIDIPacket>.offset(of: \MIDIPacket.data)!)
                            .assumingMemoryBound(to: UInt8.self)
                        
                        let bytes = UnsafeBufferPointer<UInt8>(start: data, count: Int(packet.pointee.length))
                        
                        let result = Result { try connection.parser.parse(data: bytes) }
                        
                        packet = UnsafePointer(MIDIPacketNext(packet))
                        
                        return result
                    }
                }
                
                queue.async {
                    let source = UnsafeRawPointer(endpointRef).assumingMemoryBound(to: MIDIInputConnection.self).pointee.source
                    for messages in parsedPacket {
                        let packet = messages.map({ MIDIPackage(source: source, timeStamp: timeStamp, messages: $0) })
                        callback(packet)
                    }
                }
            }
            try MIDIError.validateNoError(status)
        }
    }
    deinit {
        MIDIPortDispose(ref)
    }
}

extension MIDIInputPort {
    public func connect(to source: MIDIEndpoint) throws {
        try queue.sync {
            let connection = MIDIInputConnection(source: source)
            
            
            guard !connections.contains(connection) else { return }
            
            try MIDIError.validateNoError(MIDIPortConnectSource(ref, source.ref, connection.pointer))
            
            
            connections.insert(connection)
        }
    }
    public func disconnect(from source: MIDIEndpoint) throws {
        try queue.sync {
            try MIDIError.validateNoError(MIDIPortDisconnectSource(ref, source.ref))
            let connection = MIDIInputConnection(source: source)
            connections.remove(connection)
        }
    }
}


