# MIDIKit [![Documentation](https://img.shields.io/badge/Documentation-<Color>.svg)](https://dnadoba.github.io/MIDIKit)

MIDIKit is a Swift Package for decoding and encoding MIDI Packages and a Swifty Wrapper for CoreMIDI on iOS and macOS.

## Playground
There is a playground in the root folder of this repository. 
You should be able to run it by first opening this Swift Package in Xcode by double-clicking the Package.swift and then opening the Playground in the Project Navigator.

The Playground lists all connected devices, logs all MIDI messages received. 
You can also send MIDI messages back to all connected devices by using the `send(_:)` function at the end of the Playground. 
Make sure you connect your MIDI device to your Mac before you start the Playground.

## Connection basics

Create and start the MIDI Client

```swift
let midiClient = MIDIClient(name: "My Client")

do {
    try midiClient.start()
} catch {
    // catch error
}
```

Send messages

```swift
do {
    let outputPort = try midiClient.makeOutputPort(name: "Output") 
    outputPort.send(MIDIMessage.controlChange(channel: 1, controller: 11, value: 64), to: destination)
} catch {
    // catch error
}
```
Receive messages

```swift
let midiInputPort = try midiClient.makeInputPort(name: "Input", callback: { (result) in
    
    do {
        let packet = try result.get()
        let message = packet.message
        
        // Handle message
    } catch {
        // catch error
    }
})
```

## MIDI Messages

MIDIKit supports the creation of all common MIDI Messages via dedicated enums. Here some examples:

```swift
    // Control change
    let messsage = MIDIMessage.controlChange(channel: 1, controller: 11, value: 64), to: destination)
    
    // Note on
    let message = MIDIMessage.noteOnEvent(channel: 1, key: 20, velocity: 100)
    
    // Sysex
    let data: [UInt8] = [0xF0, 0x01, 0x02, 0xF7]
    let message = MIDIMessage.systemExclusivMessage(data)
```

## MIDI Network support

To connect your client to a MIDI network session, create a specialized `MIDINetworkClient`

```swift
let connection = MIDINetworkConnection(host: MIDINetworkHost(name: "Session 1", address: "192.168.0.100", port: 5006))
let midiClient = try MIDINetworkClient(name: "My Client", connection: connection)

do {
    try midiClient.start()
} catch {
    // catch error
}
```

When connected to a MIDI Network, you can use the dedicated source and destination endpoints for sending and receiving MIDI messages:

```swift
...

let source = midiClient.sourceEndpoint
let destination = midiClient.destinationEndpoint

// Send a MIDI message
do {
    let outputPort = try midiClient.makeOutputPort(name: "Output") 
    outputPort.send(MIDIMessage.controlChange(channel: 1, controller: 11, value: 64), to: destination)
} catch {
    // catch error
}

// Receive MIDI messages
let midiInputPort = try midiClient.makeInputPort(name: "Input", callback: { (result) in
    
    do {
        let packet = try result.get()
        let message = packet.message
        
        // Handle message
    } catch {
        // catch error
    }
})

midiInputPort.connect(to: source)

```
