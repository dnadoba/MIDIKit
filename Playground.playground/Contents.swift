import Foundation
import Darwin
import CoreMIDI
import MIDIKit
import PlaygroundSupport

var parser = MIDIParser()

var inPort: MIDIPortRef = 0
var src:MIDIEndpointRef = MIDIGetSource(0)
var midiClient: MIDIClientRef = 0
MIDIClientCreate("PlaygroundClient" as CFString, nil, nil, &midiClient)
MIDIPortConnectSource(inPort, src, &src)

var outPort:MIDIPortRef = 0

MIDIOutputPortCreate(midiClient, "MidiTest_OutPort" as CFString, &outPort);

let destNum = 0
print("Using destination #\(destNum)")

var destRef:MIDIEndpointRef = MIDIGetDestination(destNum)
let dest = MIDIEndpoint(destRef)

func send(_ messages: [MIDIMessage]) {
    var packet1:MIDIPacket = MIDIPacket();
    packet1.timeStamp = 0
    
    
    let data = UnsafeMutableRawPointer(&packet1)
        .advanced(by: MemoryLayout<MIDIPacket>.offset(of: \MIDIPacket.data)!)
        .assumingMemoryBound(to: UInt8.self)
    
    packet1.length = UInt16(messages.size)
    messages.write(to: data)
    
    var packetList:MIDIPacketList = MIDIPacketList(numPackets: 1, packet: packet1);
    print("sending messages \(messages) to \(dest?.displayName ?? "")")
    let status = MIDISend(outPort, destRef, &packetList)
    if status != noErr {
        print("Error \(MIDIError(status))")
    }
}
func MyMIDIReadProc(pktList: UnsafePointer<MIDIPacketList>,
                    readProcRefCon: UnsafeMutableRawPointer?, srcConnRefCon: UnsafeMutableRawPointer?) -> Void
{
    let source = (srcConnRefCon?
        .load(as: MIDIEndpointRef.self))
        .flatMap(MIDIEndpoint.init)
    
    print("MIDI Received From Source: \(source?.displayName ?? "-")")
    var packet = UnsafeRawPointer(pktList)
        .advanced(by: MemoryLayout<MIDIPacketList>.offset(of: \MIDIPacketList.packet)!)
        .assumingMemoryBound(to: MIDIPacket.self)
    
    for _ in 0..<pktList.pointee.numPackets {
        let data = UnsafeRawPointer(packet)
            .advanced(by: MemoryLayout<MIDIPacket>.offset(of: \MIDIPacket.data)!)
            .assumingMemoryBound(to: UInt8.self)
        
        let bytes = UnsafeBufferPointer<UInt8>(start: data, count: Int(packet.pointee.length))
        print("Bytes: \(bytes.map({ String($0, radix: 2) }))")
        do {
            let messages = try parser.parse(data: bytes)
            for message in messages {
                print(message)
                if case let .channelMessage(channelMessage) = message {
                    switch channelMessage.kind {
                    case let .noteOnEvent(key, velocity):
                        send([.controlChange(channel: 0, controller: key, value: velocity)])
                    default: break
                    }
                }
            }
        } catch {
            print(error)
        }
        
        packet = UnsafePointer(MIDIPacketNext(packet))
    }
}

//packet1.data.0 = 0x80 + 0; // Note Off event channel 1
//packet1.data.2 = 0; // Velocity
//sleep(1);
//packetList = MIDIPacketList(numPackets: 1, packet: packet1);
//MIDISend(outPort, dest, &packetList);
//print("Note off sent")

//let client = MIDIClient(name: "MidiTestClient")

// Keep playground running
PlaygroundPage.current.needsIndefiniteExecution = true

//print("Devices:")
//MIDIDevice.getAll().forEach {
//    print("   \($0.name as Any)")
//    print("   Entities:")
//    $0.getEntities().forEach {
//        print("      \($0.name as Any)")
//        print("      Sources:")
//        $0.getSources().forEach {
//            print("         \($0.name as Any)")
//        }
//        print("      Destinations:")
//        $0.getDestinations().forEach {
//            print("         \($0.name as Any)")
//        }
//    }
//}

MIDIInputPortCreate(midiClient, "MidiTest_InPort" as CFString, MyMIDIReadProc, nil, &inPort)


let channel: UInt8 = 0
func turnAllLedsOff() {
    for key in UInt8(0)...127 {
        send([.controlChange(channel: channel, controller: key, value: 0)])
    }
}
turnAllLedsOff()

for key in UInt8(0)...127 {
    send([.controlChange(channel: channel, controller: key, value: 127)])
}

for _ in 0...10 {
    for key in UInt8(70)...85 {
        send([.controlChange(channel: channel, controller: key, value: 127)])
        send([.controlChange(channel: channel, controller: key, value: 127)])
        send([.controlChange(channel: channel, controller: key, value: 127)])
        send([.controlChange(channel: channel, controller: key, value: 127)])
        send([.controlChange(channel: channel, controller: key, value: 127)])
    }
    turnAllLedsOff()
    sleep(1)
    for key in UInt8(0)...127 {
        send([.controlChange(channel: channel, controller: key, value: 127)])
    }
}
