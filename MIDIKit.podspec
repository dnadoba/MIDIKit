
Pod::Spec.new do |s|

  s.name         = "MIDIKit"
  s.version      = "1.0.0"
  s.summary      = "MIDI message decoder/encoder and type safe wrapper around CoreMIDI"

  s.description  = <<-DESC
		   MIDI message decoder/encoder and type safe wrapper around CoreMIDI
                   DESC

  s.homepage     = "https://github.com/dnadoba/MIDIKit"

  s.license      = { :type => "Apache License, Version 2.0", :file => "LICENSE" }


  s.author             = { "David Nadoba" => "dnadoba@gmail.com" }
  s.social_media_url   = "http://twitter.com/dnadoba"

  s.ios.deployment_target = "12.0"
  s.osx.deployment_target = "10.14"

  #s.source       = { :git => "https://github.com/dnadoba/MIDIKit.git", :tag => "#{s.version}" }
  s.source       = { :path => '.' }

  s.source_files  = "Sources/MIDIKit/*.{swift}"
  s.swift_version = "5.1"
end
