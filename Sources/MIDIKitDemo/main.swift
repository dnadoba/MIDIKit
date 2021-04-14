import Foundation
import MIDIKit

let client = MIDIClient(name: "MidiTestClient")
try client.start()

// log all currently connected devices
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
// receiving all messages
let inputPorts = try MIDIEndpoint.getAllSources().map { source -> MIDIInputPort in
    let inputPort = try client.makeInputPort(name: "MIDItest_inputPort") { (result) in
        do {
            let packet = try result.get()
            print("MIDI Received \(packet.messages.count) Messages From Source: \(packet.source.displayName ?? "-") \(packet.source.entity?.device?.identifier.debugDescription ?? "-")")
            for message in packet.messages {
                print(message)
            }
        } catch {
            print(error)
        }
    }
    try inputPort.connect(to: source)
    return inputPort
}



let outputPort = try client.makeOutputPort(name: "MIDITest_outputPort")

/// sends message to all devices
/// - Parameter messages: MIDI messages to send
func send(_ messages: [MIDIMessage]) throws {
    let allDesitnations = MIDIEndpoint.getAllDestinations()
    if allDesitnations.isEmpty {
        print("no destinations available")
    }
    try allDesitnations.forEach { (destination) in
        try outputPort.send(messages, to: destination)
    }
}

/// send messages to all devices
while true {
    try send(Array(repeating: .controlChange(channel: 1, controller: 2, value: 3), count: 50))
}

sleep(.max)
