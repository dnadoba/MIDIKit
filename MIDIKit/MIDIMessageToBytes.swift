//
//  MIDIMessageToBytes.swift
//  MIDIKit
//
//  Created by David Nadoba on 01.04.19.
//  Copyright © 2019 David Nadoba. All rights reserved.
//

import Foundation

// MARK: calulating the size of a midi message
extension MIDIMessage {
    /// size of message in bytes
    public var size: Int {
        switch self {
        case let .channelMessage(m): return m.size
        case let .systemExclusivMessage(m): return m.count
        case let .systemCommonMessage(m): return m.size
        case let .systemRealtimeMessage(m): return m.size
        }
    }
}
extension MIDIChannelMessage {
    /// size of message in bytes
    var size: Int { return 1 + kind.size }
}
extension MIDIChannelMessage.Kind {
    /// size of message in bytes
    var size: Int {
        switch self {
        case .noteOffEvent: return 2
        case .noteOnEvent: return 2
        case .polyphonicKeyPressure: return 2
        case .controlChange: return 2
        case .programChange: return 1
        case .channelPressure: return 1
        case .pitchBendChange: return 2
        }
    }
}
extension MIDISystemCommonMessage {
    /// size of message in bytes
    var size: Int {
        switch self {
        case .midiTimeCodeQuarterFrame: return 2
        case .songPositionPointer: return 3
        case .songSelect: return 2
        case .undefined1: return 1
        case .undefined2: return 1
        case .tuneRequest: return 1
        }
    }
}
extension MIDISystemRealtimeMessage {
    /// size of message in bytes
    var size: Int { return 1 }
}
extension Sequence where Element == MIDIMessage {
    
    /// size of all messages in bytes
    public var size: Int {
        return reduce(0, { $0 + $1.size })
    }
}

// MARK: write messages to buffer

extension Sequence where Element == MIDIMessage {
    public func write(to pointer: UnsafeMutablePointer<UInt8>) {
        var pointerHead = pointer
        for message in self {
            let size = message.size
            let buffer = UnsafeMutableBufferPointer<UInt8>(start: pointerHead, count: size)
            message.write(to: buffer)
            pointerHead += message.size
        }
    }
}
extension MIDIMessage {
    public func write(to buffer: UnsafeMutableBufferPointer<UInt8>) {
        switch self {
        case let .channelMessage(m): m.write(to: buffer)
        case let .systemExclusivMessage(m): m.copyBytes(to: buffer)
        case let .systemCommonMessage(m): m.write(to: buffer)
        case let .systemRealtimeMessage(m): m.write(to: buffer)
        }
    }
}
extension MIDIChannelMessage {
    var commandByteWithChannel: UInt8 {
        assert(channel & 0b1111_0000 == 0)
        return kind.commandByteWithZeroChannel | channel
    }
    func write(to buffer: UnsafeMutableBufferPointer<UInt8>) {
        buffer[0] = commandByteWithChannel
        kind.write(to: UnsafeMutableBufferPointer(start: buffer.baseAddress?.advanced(by: 1),
                                                  count: buffer.count - 1))
    }
}
extension MIDIChannelMessage.Kind {
    var commandByteWithZeroChannel: UInt8 {
        switch self {
        case .noteOffEvent: return 0b1000_0000
        case .noteOnEvent: return 0b1001_0000
        case .polyphonicKeyPressure: return 0b1010_0000
        case .controlChange: return 0b1011_0000
        case .programChange: return 0b1100_0000
        case .channelPressure: return 0b1101_0000
        case .pitchBendChange: return 0b1110_0000
        }
    }
    func write(to buffer: UnsafeMutableBufferPointer<UInt8>) {
        switch self {
        case .noteOffEvent(let firstByte, let secondByte),
             .noteOnEvent(let firstByte, let secondByte),
             .polyphonicKeyPressure(let firstByte, let secondByte),
             .controlChange(let firstByte, let secondByte):
            buffer[0] = firstByte._escapedValueByteWithAssertion
            buffer[1] = secondByte._escapedValueByteWithAssertion
        case .programChange(let firstByte),
             .channelPressure(let firstByte):
            buffer[0] = firstByte._escapedValueByteWithAssertion
        case .pitchBendChange(let value):
            let leastSignificantByte = UInt8(value.littleEndian & 0b0000_0000_0111_1111)
            let mostSignificantByte = UInt8(value.littleEndian >> 7 & 0b0000_0000_0111_1111)
            buffer[0] = leastSignificantByte
            buffer[1] = mostSignificantByte
        }
    }
}

extension MIDISystemCommonMessage {
    var commandByte: UInt8 {
        switch self {
        case .midiTimeCodeQuarterFrame: return 0b1111_0001
        case .songPositionPointer: return 0b1111_0010
        case .songSelect: return 0b1111_0011
        case .undefined1: return 0b1111_0100
        case .undefined2: return 0b1111_0101
        case .tuneRequest: return 0b1111_0110
        }
    }
    func write(to buffer: UnsafeMutableBufferPointer<UInt8>) {
        buffer[0] = commandByte
        switch self {
        case .midiTimeCodeQuarterFrame(let messageType, let values):
            assert(messageType & 0b1111_1000 == 0,
                   "messageType \(messageType) of midiTimeCodeQuarterFrame is out of allowed range")
            assert(values & 0b1111_0000 == 0,
                   "values \(messageType) of midiTimeCodeQuarterFrame is out of allowed range")
            let value = messageType << 4 + values
            buffer[1] = value
        case .songPositionPointer(let value):
            let leastSignificantByte = UInt8(value.littleEndian & 0b0000_0000_0111_1111)
            let mostSignificantByte = UInt8(value.littleEndian >> 7 & 0b0000_0000_0111_1111)
            buffer[1] = leastSignificantByte
            buffer[2] = mostSignificantByte
        case .songSelect(let value):
            buffer[1] = value._escapedValueByteWithAssertion
        case .undefined1: break
        case .undefined2: break
        case .tuneRequest: break
        }
    }
}
extension MIDISystemRealtimeMessage {
    func write(to buffer: UnsafeMutableBufferPointer<UInt8>) {
        buffer[0] = self.rawValue
    }
}
extension UInt8 {
    fileprivate var _escapedValueByteWithAssertion: UInt8 {
        assert(self & 0b1000_0000 == 0)
        return escapedValueByte
    }
    internal var escapedValueByte: UInt8 {
        return self & 0b0111_1111
    }
}


