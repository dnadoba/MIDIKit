//
//  MIDIMessageKindTests.swift
//  MIDIKitTests
//
//  Created by David Nadoba on 31.03.19.
//  Copyright © 2019 David Nadoba. All rights reserved.
//

import XCTest
@testable import MIDIKit

class MIDIMessageKindTests: XCTestCase {
    func testAllPosibleValues() {
        for byte in 0...Int(UInt8.max) {
            // should not trap
            _ = MIDIMessageKind(rawValue: UInt8(byte))
        }
    }
    func testAllValueBytes() {
        for byte in UInt8(0x00)...0x0F {
            XCTAssertNil(MIDIMessageKind(rawValue: byte))
        }
    }
}
