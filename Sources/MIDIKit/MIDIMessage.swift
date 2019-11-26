//
//  MIDIMessage.swift
//  MIDIKit
//
//  Created by David Nadoba on 01.04.19.
//  Copyright © 2019 David Nadoba. All rights reserved.
//

import Foundation

public enum MIDIMessage: Equatable {
    case channelMessage(MIDIChannelMessage)
    case systemExclusivMessage([UInt8])
    case systemCommonMessage(MIDISystemCommonMessage)
    case systemRealtimeMessage(MIDISystemRealtimeMessage)
}

extension MIDIMessage {
    static public func noteOffEvent(channel: UInt8, key: UInt8, velocity: UInt8) -> MIDIMessage {
        return .channelMessage(.noteOffEvent(channel: channel, key: key, velocity: velocity))
    }
    static public func noteOnEvent(channel: UInt8, key: UInt8, velocity: UInt8) -> MIDIMessage {
        return .channelMessage(.noteOnEvent(channel: channel, key: key, velocity: velocity))
    }
    static public func polyphonicKeyPressure(channel: UInt8, key: UInt8, pressure: UInt8) -> MIDIMessage {
        return .channelMessage(.polyphonicKeyPressure(channel: channel, key: key, pressure: pressure))
    }
    static public func controlChange(channel: UInt8, controller: UInt8, value: UInt8) -> MIDIMessage {
        return .channelMessage(.controlChange(channel: channel, controller: controller, value: value))
    }
    static public func programChange(channel: UInt8, programmNumber: UInt8) -> MIDIMessage {
        return .channelMessage(.programChange(channel: channel, programmNumber: programmNumber))
    }
    static public func channelPressure(channel: UInt8, pressure: UInt8) -> MIDIMessage {
        return .channelMessage(.channelPressure(channel: channel, pressure: pressure))
    }
    static public func pitchBendChange(channel: UInt8, value: UInt16) -> MIDIMessage {
        return .channelMessage(.pitchBendChange(channel: channel, value: value))
    }
}

public struct MIDIChannelMessage: Equatable {
    public static let channelRange: ClosedRange<UInt8> = 0...0b0000_1111
    public static let keyRange: ClosedRange<UInt8> = 0...0b0111_1111
    public static let controllerRange: ClosedRange<UInt8> = 0...0b0111_1111
    public static let programmNumberRange: ClosedRange<UInt8> = 0...0b0111_1111
    public static let byteRange: ClosedRange<UInt8> = 0b1000_0000...0b1110_1111
    public enum Kind: Equatable {
        case noteOffEvent(key: UInt8, velocity: UInt8)
        case noteOnEvent(key: UInt8, velocity: UInt8)
        case polyphonicKeyPressure(key: UInt8, pressure: UInt8)
        case controlChange(controller: UInt8, value: UInt8)
        case programChange(programmNumber: UInt8)
        case channelPressure(pressure: UInt8)
        case pitchBendChange(value: UInt16)
    }
    public var channel: UInt8
    public var kind: Kind
}

public extension MIDIChannelMessage {
    static func noteOffEvent(channel: UInt8, key: UInt8, velocity: UInt8) -> MIDIChannelMessage {
        return .init(channel: channel, kind: .noteOffEvent(key: key, velocity: velocity))
    }
    static func noteOnEvent(channel: UInt8, key: UInt8, velocity: UInt8) -> MIDIChannelMessage {
        return .init(channel: channel, kind: .noteOnEvent(key: key, velocity: velocity))
    }
    static func polyphonicKeyPressure(channel: UInt8, key: UInt8, pressure: UInt8) -> MIDIChannelMessage {
        return .init(channel: channel, kind: .polyphonicKeyPressure(key: key, pressure: pressure))
    }
    static func controlChange(channel: UInt8, controller: UInt8, value: UInt8) -> MIDIChannelMessage {
        return .init(channel: channel, kind: .controlChange(controller: controller, value: value))
    }
    static func programChange(channel: UInt8, programmNumber: UInt8) -> MIDIChannelMessage {
        return .init(channel: channel, kind: .programChange(programmNumber: programmNumber))
    }
    static func channelPressure(channel: UInt8, pressure: UInt8) -> MIDIChannelMessage {
        return .init(channel: channel, kind: .channelPressure(pressure: pressure))
    }
    static func pitchBendChange(channel: UInt8, value: UInt16) -> MIDIChannelMessage {
        return .init(channel: channel, kind: .pitchBendChange(value: value))
    }
}

extension MIDIChannelMessage {
    public static let significantChannelBits: UInt8 = 0b0000_1111
    public static func getChannel(_ byte: UInt8) -> UInt8 {
        return byte & significantChannelBits
    }
}

public enum MIDISystemCommonMessage: Equatable {
    public static let midiTimeCodeQuarterFrameMessageTypeRange: ClosedRange<UInt8> = 0...0b0000_0111
    case midiTimeCodeQuarterFrame(messageType: UInt8, values: UInt8)
    case songPositionPointer(value: UInt16)
    case songSelect(value: UInt8)
    case undefined1
    case undefined2
    case tuneRequest
}
public enum MIDISystemRealtimeMessage: UInt8, CaseIterable {
    public static let byteRange: ClosedRange<UInt8> = 0b1111_1000...0b1111_1111
    case timeClock =        0b1111_1000
    case undefined1 =       0b1111_1001
    case start =            0b1111_1010
    case `continue` =       0b1111_1011
    case stop =             0b1111_1100
    case undefined2 =       0b1111_1101
    case activeSensing =    0b1111_1110
    case reset =            0b1111_1111
}
