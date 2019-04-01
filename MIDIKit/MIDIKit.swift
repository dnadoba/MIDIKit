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

fileprivate enum MIDIObjectProperty {
    
}

public protocol MIDIObject {
    var ref: MIDIObjectRef { get }
}

// MAKR: Utility functions
extension MIDIObject {
    public func getProperty(for key: CFString) throws -> String {
        var param: Unmanaged<CFString>?
        let err: OSStatus = MIDIObjectGetStringProperty(ref, key, &param)
        guard err == noErr else {
            throw MIDIError(err)
        }
        return param!.takeRetainedValue() as String
    }
}

extension MIDIObject {
    public var name: String? { return try? getProperty(for: kMIDIPropertyName) }
}


public struct MIDIDevice: MIDIObject, Hashable {
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
}

extension MIDIDevice {
    public func getEntities() -> [MIDIEntity] {
        return (0..<MIDIDeviceGetNumberOfEntities(ref))
            .map { MIDIDeviceGetEntity(ref, $0) }
            .compactMap(MIDIEntity.init)
    }
}

public struct MIDIEntity: MIDIObject, Hashable {
    public let ref: MIDIEntityRef
    public init?(_ ref: MIDIEntityRef) {
        guard ref != 0 else { return nil }
        self.ref = ref
    }
}

extension MIDIEntity {
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

public struct MIDIEndpoint: MIDIObject, Hashable {
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
}

public class MIDIClient {
    private(set) var midiClient: MIDIClientRef = 0
    public init(name: String) {
        //MIDIClientCreate(c as CFString, nil, nil, &midiClient)
        MIDIClientCreateWithBlock(name as CFString, &midiClient) { (notificationPointer) in
            let notification = notificationPointer.pointee
            debugPrint(notification.messageID)
            if notification.messageID == .msgObjectAdded ||
                notification.messageID == .msgObjectRemoved {
                let removeOrAddedNotification = notificationPointer.withMemoryRebound(to: MIDIObjectAddRemoveNotification.self, capacity: 1, { (addOrRemove) in
                    return addOrRemove.pointee
                })
                dump(removeOrAddedNotification)
            }
            if notification.messageID == .msgPropertyChanged {
                let propertyChangedNotification = notificationPointer.withMemoryRebound(to: MIDIObjectPropertyChangeNotification.self, capacity: 1, { (notification) in
                    return notification.pointee
                })
                dump(propertyChangedNotification)
            }
        }
    }
    deinit {
        MIDIClientDispose(midiClient)
    }
}


