import Foundation
import Darwin
import CoreMIDI
import MIDIKit
import PlaygroundSupport

var parser = MIDIParser()

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
        print(try? parser.parse(data: bytes) as Any)
        packet = UnsafePointer(MIDIPacketNext(packet))
    }
}

var inPort: MIDIPortRef = 0
var src:MIDIEndpointRef = MIDIGetSource(0)
var midiClient: MIDIClientRef = 0
MIDIClientCreate("PlaygroundClient" as CFString, nil, nil, &midiClient)
MIDIInputPortCreate(midiClient, "MidiTest_InPort" as CFString, MyMIDIReadProc, nil, &inPort)

MIDIPortConnectSource(inPort, src, &src)

//let client = MIDIClient(name: "MidiTestClient")

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
