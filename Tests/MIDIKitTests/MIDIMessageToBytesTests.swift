//
//  MIDIMessageToBytesTests.swift
//  MIDIKitTests
//
//  Created by David Nadoba on 01.04.19.
//  Copyright © 2019 David Nadoba. All rights reserved.
//

import XCTest
@testable import MIDIKit

fileprivate func makeMessages(channel: UInt8, data0: UInt8, data1: UInt8) -> [MIDIMessage] {
    let channelMessages: [MIDIChannelMessage.Kind] = [
        .noteOffEvent(key: data0, velocity: data1),
        .noteOnEvent(key: data0, velocity: data1),
        .polyphonicKeyPressure(key: data0, pressure: data1),
        .controlChange(controller: data0, value: data1),
        .programChange(programmNumber: data0),
        .channelPressure(pressure: data1),
        .pitchBendChange(value: UInt16(data0) + UInt16(data1)),
    ]
    let systemExclusivMessages: [MIDIMessage] = [
        // empty exclusiv message
        .systemExclusivMessage([0xF0, 0xF7]),
        // just some random data
        .systemExclusivMessage([0xF0, channel, data0, data1, 0xF7]),
    ]
    let systemCommonMessages: [MIDISystemCommonMessage] = [
        .midiTimeCodeQuarterFrame(messageType: (data0 & 0b0111_0000) >> 4, values: data0 & 0b0000_0111),
        .songPositionPointer(value: UInt16(data0) + UInt16(data1)),
        .songSelect(value: data0),
        .undefined1,
        .undefined2,
        .tuneRequest,
    ]
    let systemRealtimeMessages = MIDISystemRealtimeMessage.allCases
    return [
        channelMessages.map { .channelMessage(.init(channel: channel, kind: $0)) },
        systemExclusivMessages,
        systemCommonMessages.map { .systemCommonMessage($0) },
        systemRealtimeMessages.map { .systemRealtimeMessage($0) },
    ].flatMap({$0})
    
}

class MIDIMessageToBytesTests: XCTestCase {
    func testWriteAndReadAllMessages() {
        func testWriteAndParserMessages(_ messages: [MIDIMessage]) {
            let buffer = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: messages.size)
            defer { buffer.deallocate() }
            messages.write(to: buffer.baseAddress!)
            var parser = MIDIParser()
            XCTAssertEqual(messages, try parser.parse(data: buffer))
        }
        testWriteAndParserMessages(makeMessages(channel: 0,     data0: 0,   data1: 0))
        testWriteAndParserMessages(makeMessages(channel: 1,     data0: 0,   data1: 0))
        testWriteAndParserMessages(makeMessages(channel: 0,     data0: 1,   data1: 0))
        testWriteAndParserMessages(makeMessages(channel: 0,     data0: 0,   data1: 1))
        testWriteAndParserMessages(makeMessages(channel: 15,    data0: 0,   data1: 0))
        testWriteAndParserMessages(makeMessages(channel: 0,     data0: 127, data1: 0))
        testWriteAndParserMessages(makeMessages(channel: 0,     data0: 0,   data1: 127))
        testWriteAndParserMessages(makeMessages(channel: 15,    data0: 0,   data1: 127))
        testWriteAndParserMessages(makeMessages(channel: 15,    data0: 127, data1: 0))
        testWriteAndParserMessages(makeMessages(channel: 0,     data0: 127, data1: 127))
        testWriteAndParserMessages(makeMessages(channel: 15,    data0: 127, data1: 127))
    }
}
