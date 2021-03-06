import Foundation
import MIDIKit
import PlaygroundSupport

// Keep playground running
PlaygroundPage.current.needsIndefiniteExecution = true

let client = MIDIClient(name: "MidiTestClient")
try client.start()

// log all currently connected devices
let expectedLength = 30
print("Devices:")
MIDIDevice.getAll().forEach {
    print("Name: \($0.name ?? "-unknown name-")")
    print("ID: \($0.identifier?.debugDescription ?? "-unknown id-")")
    let entities = $0.getEntities()
    if !entities.isEmpty {
        print("Entities:")
    }
    entities.forEach {
        print("   \($0.name ?? "-unknown name-")")
        print("   \($0.name ?? "-unknown name-")")
        print("   Sources:")
        $0.getSources().forEach {
            print("      \($0.name ?? "-unknown name-")")
        }
        print("      Destinations:")
        $0.getDestinations().forEach {
            print("      \($0.name ?? "-unknown name-")")
        }
    }
    print("-----------------------------------------------")
}
// receiving all messages
let inputPorts = try MIDIEndpoint.getAllSources().map { source -> MIDIInputPort in
    let inputPort = try client.makeInputPort(name: "MIDItest_inputPort") { (result) in
        do {
            let packet = try result.get()
            print("MIDI Received From Source: \(packet.source.displayName ?? "-") \(packet.source.entity?.device?.identifier.debugDescription ?? "-")")
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
try send([.controlChange(channel: 0, controller: 0, value: 0)])
