//
//  MIDIParser.swift
//  MIDIKit
//
//  Created by David Nadoba on 30.03.19.
//  Copyright © 2019 David Nadoba. All rights reserved.
//

import Foundation

extension MIDIOneByteMessage {
    internal func parseMessage(commandByte: UInt8) -> MIDIMessage {
        switch self {
        // System Common
        case .systemCommonUndefined1:
            return .systemCommonMessage(.undefined1)
        case .systemCommonUndefined2:
            return .systemCommonMessage(.undefined2)
        case .systemCommonTuneRequest:
            return .systemCommonMessage(.tuneRequest)
        // Real-time
        case .realTimeTimeClock:
            return .systemRealtimeMessage(.timeClock)
        case .realTimeUndefined1:
            return .systemRealtimeMessage(.undefined1)
        case .realTimeStart:
            return .systemRealtimeMessage(.start)
        case .realTimeContinue:
            return .systemRealtimeMessage(.continue)
        case .realTimeStop:
            return .systemRealtimeMessage(.stop)
        case .realTimeUndefined2:
            return .systemRealtimeMessage(.undefined2)
        case .realTimeActiveSensing:
            return .systemRealtimeMessage(.activeSensing)
        case .realTimeReset:
            return .systemRealtimeMessage(.reset)
        }
    }
}

extension MIDITwoByteMessage {
    internal func parseMessage(commandByte: UInt8, dataByte: UInt8) -> MIDIMessage {
        switch self {
        case .channelProgramChange:
            let channel = MIDIChannelMessage.getChannel(commandByte)
            return .channelMessage(.programChange(channel: channel, programmNumber: dataByte))
        case .channelPressure:
            let channel = MIDIChannelMessage.getChannel(commandByte)
            return .channelMessage(.channelPressure(channel: channel, pressure: dataByte))
        case .systemCommonMidiTimeCodeQuarterFrame:
            return .systemCommonMessage(
                .midiTimeCodeQuarterFrame(messageType: dataByte >> 4,
                                          values: dataByte & 0b0000_1111))
        case .systemCommonSongSelect:
            return .systemCommonMessage(.songSelect(value: dataByte))
        }
    }
}

extension MIDIThreeByteMessage {
    internal func parseMessage(commandByte: UInt8, dataByte0: UInt8, dataByte1: UInt8) -> MIDIMessage {
        let channel = MIDIChannelMessage.getChannel(commandByte)
        switch self {
        case .noteOffEvent:
            return .channelMessage(.noteOffEvent(channel: channel,
                                                 key: dataByte0,
                                                 velocity: dataByte1))
        case .noteOnEvent:
            return .channelMessage(.noteOnEvent(channel: channel,
                                                key: dataByte0,
                                                velocity: dataByte1))
        case .polyphonicKeyPressure:
            return .channelMessage(.polyphonicKeyPressure(channel: channel,
                                                          key: dataByte0,
                                                          pressure: dataByte1))
        case .controlChange:
            return .channelMessage(.controlChange(channel: channel,
                                                  controller: dataByte0,
                                                  value: dataByte1))
        case .pitchBendChange:
            let (leastSignificant, mostSignificant) = (dataByte0, dataByte1)
            let value: UInt16 = (UInt16(mostSignificant) << 7) + UInt16(leastSignificant)
            return .channelMessage(.pitchBendChange(channel: channel,
                                                    value: value))
        case .systemCommonSongPositionPointer:
            let (leastSignificant, mostSignificant) = (dataByte0, dataByte1)
            let value: UInt16 = (UInt16(mostSignificant) << 7) + UInt16(leastSignificant)
            return .systemCommonMessage(.songPositionPointer(value: value))
        }
    }
}

internal enum MIDIOneByteMessage: UInt8 {
    // System Common
    case systemCommonUndefined1 =               0b1111_0100
    case systemCommonUndefined2 =               0b1111_0101
    case systemCommonTuneRequest =              0b1111_0110
    // Real time
    case realTimeTimeClock =                    0b1111_1000
    case realTimeUndefined1 =                   0b1111_1001
    case realTimeStart =                        0b1111_1010
    case realTimeContinue =                     0b1111_1011
    case realTimeStop =                         0b1111_1100
    case realTimeUndefined2 =                   0b1111_1101
    case realTimeActiveSensing =                0b1111_1110
    case realTimeReset =                        0b1111_1111
}

internal enum MIDITwoByteMessage: UInt8 {
    case channelProgramChange =                 0b1100_0000
    case channelPressure =                      0b1101_0000
    case systemCommonMidiTimeCodeQuarterFrame = 0b1111_0001
    case systemCommonSongSelect =               0b1111_0011
}

internal enum MIDIThreeByteMessage: UInt8 {
    case noteOffEvent =                         0b1000_0000
    case noteOnEvent =                          0b1001_0000
    case polyphonicKeyPressure =                0b1010_0000
    case controlChange =                        0b1011_0000
    case pitchBendChange =                      0b1110_0000
    case systemCommonSongPositionPointer =      0b1111_0010
}

internal enum MIDIMessageKind {
    case oneByte(MIDIOneByteMessage)
    case twoByte(MIDITwoByteMessage)
    case threeByte(MIDIThreeByteMessage)
    case arbitary
}

extension MIDIMessageKind {
    internal init?(rawValue: UInt8) {
        switch rawValue {
        case 0b0000_0000...0b0111_1111:
            return nil
        case 0b1000_0000...0b1110_1111:
            switch rawValue & 0b1111_0000 {
            case 0b1000_0000: //noteOffEvent
                self = .threeByte(.noteOffEvent)
            case 0b1001_0000: //noteOnEvent
                self = .threeByte(.noteOnEvent)
            case 0b1010_0000: //polyphonicKeyPressure
                self = .threeByte(.polyphonicKeyPressure)
            case 0b1011_0000: //controlChange
                self = .threeByte(.controlChange)
            case 0b1100_0000: //programChange
                self = .twoByte(.channelProgramChange)
            case 0b1101_0000: //channelPressure
                self = .twoByte(.channelPressure)
            case 0b1110_0000: //pitchBendChange
                self = .threeByte(.pitchBendChange)
            default: fatalError("unreachable")
            }
        case 0b1111_0000: // system exclusiv start
            self = .arbitary
        case 0b1111_0001: // midiTimeCodeQuarterFrame
            self = .twoByte(.systemCommonMidiTimeCodeQuarterFrame)
        case 0b1111_0010: // songPositionPointer
            self = .threeByte(.systemCommonSongPositionPointer)
        case 0b1111_0011: // songSelect
            self = .twoByte(.systemCommonSongSelect)
        case 0b1111_0100: // undefined1
            self = .oneByte(.systemCommonUndefined1)
        case 0b1111_0101: // undefined2
            self = .oneByte(.systemCommonUndefined2)
        case 0b1111_0110: // tuneRequest
            self = .oneByte(.systemCommonTuneRequest)
        case 0b1111_0111: // system exclusive end
            return nil
        case 0b1111_1000: // timeClock
            self = .oneByte(.realTimeTimeClock)
        case 0b1111_1001: // undefined1
            self = .oneByte(.realTimeUndefined1)
        case 0b1111_1010: // start
            self = .oneByte(.realTimeStart)
        case 0b1111_1011: // `continue`
            self = .oneByte(.realTimeContinue)
        case 0b1111_1100: // stop
            self = .oneByte(.realTimeStop)
        case 0b1111_1101: // undefined2
            self = .oneByte(.realTimeUndefined2)
        case 0b1111_1110: // activeSensing
            self = .oneByte(.realTimeActiveSensing)
        case 0b1111_1111: // reset
            self = .oneByte(.realTimeReset)
        default: fatalError("unreachable")
        }
    }
    internal var size: Int? {
        switch self {
        case .oneByte: return 1
        case .twoByte: return 2
        case .threeByte: return 3
        case .arbitary: return nil
        }
    }
}



var systemExclusivStartByte: UInt8 = 0xF0
var systemExclusivEndByte:   UInt8 = 0xF7

enum MIDIParserError: Error {
    case dataByteBeforeReceivingControlByte
    case newControllByteBeforePreviousMessageCouldReadCompletely
    case unexpectedControllByte
}

fileprivate extension UInt8 {
    var isDataByte: Bool {
        return self & 0b1000_0000 == 0
    }
    var isSystemExclusivEndByte: Bool {
        return self == systemExclusivEndByte
    }
}

public struct MIDIParser {
    fileprivate var currentMessageKind: MIDIMessageKind?
    fileprivate var messageBuffer: [UInt8] = []
    fileprivate var runningMessagesCount = 0
    public init() {}
    public mutating func parse<T>(data: T) throws -> [MIDIMessage] where T: Sequence, T.Element == UInt8 {
        return try data.compactMap({ try parseNextByte($0) })
    }

    private mutating func parseNextByte(_ byte: UInt8) throws -> MIDIMessage? {
        if byte.isDataByte {
            guard let currentMessageSize = currentMessageKind else {
                throw MIDIParserError.dataByteBeforeReceivingControlByte
            }
            messageBuffer.append(byte)
            return interpretMessageBuffer()
        }
        if let currentMessageKind = currentMessageKind {
            if case MIDIMessageKind.arbitary = currentMessageKind,
                byte.isSystemExclusivEndByte {
                messageBuffer.append(byte)
                defer {
                    self.currentMessageKind = nil
                    messageBuffer.removeAll()
                }
                return .systemExclusivMessage(messageBuffer)
            } else {
                // check if we have succefully parsed the previous message
                guard !hasIncompleteMessageInBuffer() else {
                    self.resetInternalState()
                    throw MIDIParserError.newControllByteBeforePreviousMessageCouldReadCompletely
                }
            }
        }
        runningMessagesCount = 0
        currentMessageKind = nil
        messageBuffer.removeAll(keepingCapacity: true)
        guard let newMessageKind = MIDIMessageKind(rawValue: byte) else {
            throw MIDIParserError.unexpectedControllByte
        }
        messageBuffer.append(byte)
        currentMessageKind = newMessageKind
        return interpretMessageBuffer()
        
    }
    private mutating func interpretMessageBuffer() -> MIDIMessage? {
        if let messageKind = currentMessageKind,
            let maxMessageSize = messageKind.size,
            messageBuffer.count > maxMessageSize {
            fatalError("internal inconsistency. message buffer size \(messageBuffer.count) is larger than max message size \(maxMessageSize) of \(messageKind)")
        }
        switch currentMessageKind {
        case let .oneByte(kind)?:
            if messageBuffer.count == 1 {
                let message = kind.parseMessage(commandByte: messageBuffer[0])
                currentMessageKind = nil
                messageBuffer.removeLast()
                return message
            }
            return nil
        case let .twoByte(kind)?:
            if messageBuffer.count == 2 {
                let message = kind.parseMessage(commandByte: messageBuffer[0],
                                                    dataByte: messageBuffer[1])
                messageBuffer.removeLast()
                runningMessagesCount += 1
                return message
            }
            return nil
        case let .threeByte(kind)?:
            if messageBuffer.count == 3 {
                let message = kind.parseMessage(commandByte: messageBuffer[0],
                                                    dataByte0: messageBuffer[1],
                                                    dataByte1: messageBuffer[2])
                messageBuffer.removeLast(2)
                runningMessagesCount += 1
                return message
            }
            return nil
            
        // wait for end controll byte
        case .arbitary?: return nil
        case .none: return nil
        }
    }
    public func hasIncompleteMessageInBuffer() -> Bool {
        return currentMessageKind != nil && messageBuffer.count > 1 || (currentMessageKind?.size ?? 0 >= 2 &&
            runningMessagesCount < 1 && messageBuffer.count <= 1)
    }
    private mutating func resetInternalState() {
        currentMessageKind = nil
        messageBuffer.removeAll()
        runningMessagesCount = 0
    }
}
