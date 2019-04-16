import Foundation
import Darwin
import CoreMIDI
import MIDIKit
import PlaygroundSupport

let client = MIDIClient(name: "MidiTestClient")
try client.start()

// Keep playground running
PlaygroundPage.current.needsIndefiniteExecution = true

print("Devices:")
MIDIDevice.getAll().forEach {
    print("   \($0.name as Any)")
    print("   Entities:")
    $0.getEntities().forEach {
        print("      \($0.name as Any)")
        print("      Sources:")
        $0.getSources().forEach {
            print("         \($0.name as Any)")
        }
        print("      Destinations:")
        $0.getDestinations().forEach {
            print("         \($0.name as Any)")
        }
    }
}
let outputPort = try client.makeOutputPort(name: "MIDITest_outputPort")
func send(_ messages: [MIDIMessage]) throws {
    try MIDIEndpoint.getAllDestinations().forEach { (destination) in
        try outputPort.send(messages, to: destination)
    }
}
let inputPort = try client.makeInputPort(name: "MIDItest_inputPort") { (result) in
    do {
        let packet = try result.get()
        print("MIDI Received From Source: \(packet.source.displayName ?? "-") \(packet.source.entity?.device?.identifier)")
        for message in packet.messages {
            print(message)
            if case let .channelMessage(channelMessage) = message {
                switch channelMessage.kind {
                case let .noteOnEvent(key, velocity): break
                    //try send([.controlChange(channel: 0, controller: key, value: velocity)])
                default: break
                }
            }
        }
    } catch {
        print(error)
    }
    
}
var source = MIDIEndpoint.getAllSources().last
try inputPort.connect(to: source!)
print("sources", MIDIEndpoint.getAllSources().map{ $0.displayName })

//let channel: UInt8 = 0
//func turnAllLedsOff() throws {
//    for key in UInt8(0)...127 {
//        try send([.controlChange(channel: channel, controller: key, value: 0)])
//    }
//}
//try turnAllLedsOff()
//
//for key in UInt8(0)...127 {
//    try send([.controlChange(channel: channel, controller: key, value: 127)])
//}
//
//for _ in 0...10 {
//    for key in UInt8(70)...85 {
//        try send([.controlChange(channel: channel, controller: key, value: 127)])
//        try send([.controlChange(channel: channel, controller: key, value: 127)])
//        try send([.controlChange(channel: channel, controller: key, value: 127)])
//        try send([.controlChange(channel: channel, controller: key, value: 127)])
//        try send([.controlChange(channel: channel, controller: key, value: 127)])
//    }
//    try turnAllLedsOff()
//    sleep(1)
//    for key in UInt8(0)...127 {
//        try send([.controlChange(channel: channel, controller: key, value: 127)])
//    }
//}
