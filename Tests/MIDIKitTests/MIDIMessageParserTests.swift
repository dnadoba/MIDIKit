//
//  MIDIKitTests.swift
//  MIDIKitTests
//
//  Created by David Nadoba on 30.03.19.
//  Copyright © 2019 David Nadoba. All rights reserved.
//

import XCTest
@testable import MIDIKit

/// The same test cases as in `MIDIMessageParserTests` but instead of using
/// a new parser for every test case, reuse the same parser for all test cases
class MIDIMessageParserReuseTests: MIDIMessageParserTests {
    override func setUp() {
        // reuse the same parser
    }
}

class MIDIMessageParserTests: XCTestCase {
    var parser = MIDIParser()
    override func setUp() {
        parser = MIDIParser()
    }
    override func tearDown() {
        XCTAssertFalse(parser.hasIncompleteMessageInBuffer())
    }
    // MARK: Test all channel messages
    func testNoteOff() {
        XCTAssertEqual(
            try parser.parse(data: [0b1000_0001, 2, 3]),
            [MIDIMessage.noteOffEvent(channel: 1, key: 2, velocity: 3)])
    }
    func testNoteOn() {
        XCTAssertEqual(
            try parser.parse(data: [0b1001_0001, 2, 3]),
            [MIDIMessage.noteOnEvent(channel: 1, key: 2, velocity: 3)])
    }
    func testPolyphonicKeyPressure() {
        XCTAssertEqual(
            try parser.parse(data: [0b1010_0001, 2, 3]),
            [MIDIMessage.polyphonicKeyPressure(channel: 1, key: 2, pressure: 3)])
    }
    func testControlChange() {
        XCTAssertEqual(
            try parser.parse(data: [0b1011_0001, 2, 3]),
            [MIDIMessage.controlChange(channel: 1, controller: 2, value: 3)])
    }
    func testProgramChange() {
        XCTAssertEqual(
            try parser.parse(data: [0b1100_0001, 2]),
            [MIDIMessage.programChange(channel: 1, programmNumber: 2)])
    }
    func testChannelPressure() {
        XCTAssertEqual(
            try parser.parse(data: [0b1101_0001, 2]),
            [MIDIMessage.channelPressure(channel: 1, pressure: 2)])
    }
    func testPitchBendChange() {
        XCTAssertEqual(
            try parser.parse(data: [0b1110_0001, 2, 3]),
            [MIDIMessage.pitchBendChange(channel: 1, value: (3 << 7) + 2)])
    }
    // MARK: Test all system exclusiv message
    func testSystemExclusivMessageWithZeroDataBytes() {
        XCTAssertEqual(
            try parser.parse(data:
                [systemExclusivStartByte, systemExclusivEndByte]),
            [MIDIMessage.systemExclusivMessage(
                [systemExclusivStartByte, systemExclusivEndByte])])
    }
    func testSystemExclusivMessageWithOneDataByte() {
        XCTAssertEqual(
            try parser.parse(data:
                [systemExclusivStartByte, 0, systemExclusivEndByte]),
            [MIDIMessage.systemExclusivMessage(
                [systemExclusivStartByte, 0, systemExclusivEndByte])])
    }
    func testSystemExclusivMessageWithManyDataBytes() {
        XCTAssertEqual(
            try parser.parse(data:
                [systemExclusivStartByte] + Array(0...127) + [systemExclusivEndByte]),
            [MIDIMessage.systemExclusivMessage(
                [systemExclusivStartByte] + Array(0...127) + [systemExclusivEndByte])])
    }
    func testSystemCommonMIDITimeCodeQuarterFrame() {
        XCTAssertEqual(
            try parser.parse(data: [0b1111_0001, 0b0_111_1111]),
            [MIDIMessage.systemCommonMessage(.midiTimeCodeQuarterFrame(messageType: 7, values: 15))])
        XCTAssertEqual(
            try parser.parse(data: [0b1111_0001, 0b0_000_0000]),
            [MIDIMessage.systemCommonMessage(.midiTimeCodeQuarterFrame(messageType: 0, values: 0))])
        XCTAssertEqual(
            try parser.parse(data: [0b1111_0001, 0b0_000_1000]),
            [MIDIMessage.systemCommonMessage(.midiTimeCodeQuarterFrame(messageType: 0, values: 8))])
        XCTAssertEqual(
            try parser.parse(data: [0b1111_0001, 0b0_100_0000]),
            [MIDIMessage.systemCommonMessage(.midiTimeCodeQuarterFrame(messageType: 4, values: 0))])
    }
    func testSystemCommonSongPositionPointer() {
        XCTAssertEqual(
            try parser.parse(data: [0b1111_0010, 0b0_100_1000, 0b0_000_0001]),
            [MIDIMessage.systemCommonMessage(.songPositionPointer(value: 200))])
        XCTAssertEqual(
            try parser.parse(data: [0b1111_0010, 0b0_000_0000, 0b0_000_0000]),
            [MIDIMessage.systemCommonMessage(.songPositionPointer(value: 0))])
    }
    func testSystemCommonSongSelect() {
        XCTAssertEqual(
            try parser.parse(data: [0b1111_0011, 0b0_000_0000]),
            [MIDIMessage.systemCommonMessage(.songSelect(value: 0))])
        XCTAssertEqual(
            try parser.parse(data: [0b1111_0011, 0b0_111_1111]),
            [MIDIMessage.systemCommonMessage(.songSelect(value: 127))])
    }
    func testSystemCommonUndefined1() {
        XCTAssertEqual(
            try parser.parse(data: [0b1111_0100]),
            [MIDIMessage.systemCommonMessage(.undefined1)])
    }
    func testSystemCommonUndefined2() {
        XCTAssertEqual(
            try parser.parse(data: [0b1111_0101]),
            [MIDIMessage.systemCommonMessage(.undefined2)])
    }
    func testSystemCommonTuneRequest() {
        XCTAssertEqual(
            try parser.parse(data: [0b1111_0110]),
            [MIDIMessage.systemCommonMessage(.tuneRequest)])
    }
    func testSystemExclusivEndShouldThrowAndFollowingPackagesGetSucessfullyParsed() {
        XCTAssertThrowsError(try parser.parse(data: [0b1111_0111]))
        testNoteOn()
        
        XCTAssertThrowsError(try parser.parse(data: [0b1111_0111]))
        testSystemCommonSongSelect()
        
        XCTAssertThrowsError(try parser.parse(data: [0b1111_0111]))
        testSystemExclusivMessageWithZeroDataBytes()
        
        XCTAssertThrowsError(try parser.parse(data: [0b1111_0111]))
        testSystemExclusivMessageWithOneDataByte()
        
        XCTAssertThrowsError(try parser.parse(data: [0b1111_0111]))
        testSystemExclusivMessageWithManyDataBytes()
        
        XCTAssertThrowsError(try parser.parse(data: [0b1111_0111]))
        XCTAssertThrowsError(try parser.parse(data: [0b1111_0111]))
        XCTAssertThrowsError(try parser.parse(data: [0b1111_0111]))
    }
    // MARK: Test all Real-time messages
    func testRealTimeTimeClock() {
        XCTAssertEqual(
            try parser.parse(data: [0b1111_1000]),
            [MIDIMessage.systemRealtimeMessage(.timeClock)])
    }
    func testRealTimeUndefined1() {
        XCTAssertEqual(
            try parser.parse(data: [0b1111_1001]),
            [MIDIMessage.systemRealtimeMessage(.undefined1)])
    }
    func testRealTimeStart() {
        XCTAssertEqual(
            try parser.parse(data: [0b1111_1010]),
            [MIDIMessage.systemRealtimeMessage(.start)])
    }
    func testRealTimeContinue() {
        XCTAssertEqual(
            try parser.parse(data: [0b1111_1011]),
            [MIDIMessage.systemRealtimeMessage(.continue)])
    }
    func testRealTimeStop() {
        XCTAssertEqual(
            try parser.parse(data: [0b1111_1100]),
            [MIDIMessage.systemRealtimeMessage(.stop)])
    }
    func testRealTimeUndefined2() {
        XCTAssertEqual(
            try parser.parse(data: [0b1111_1101]),
            [MIDIMessage.systemRealtimeMessage(.undefined2)])
    }
    func testRealTimeActiveSensing() {
        XCTAssertEqual(
            try parser.parse(data: [0b1111_1110]),
            [MIDIMessage.systemRealtimeMessage(.activeSensing)])
    }
    func testRealTimeReset() {
        XCTAssertEqual(
            try parser.parse(data: [0b1111_1111]),
            [MIDIMessage.systemRealtimeMessage(.reset)])
    }
    
    
    func testSendDataByteBeforeControlByte() {
        XCTAssertThrowsError(try parser.parse(data: [0b0000_0000]))
    }
    func testSendControllByteBeforePreviousMessageIsComplete() {
        XCTAssertThrowsError(try parser.parse(data: [
            // note off event
            0b1000_0000,
            // note on event
            0b1001_0000]))
        XCTAssertThrowsError(try parser.parse(data: [
            // note off event
            0b1000_0000,
            // key
            0b0000_0010,
            // note on event
            0b1001_0000]))
        
    }
}
