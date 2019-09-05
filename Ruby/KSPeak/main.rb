
require 'mqtt/sub_handler.rb'
require_relative 'TeleLink.rb'

$mqtt = MQTT::SubHandler.new("mqtt://ColorSpeak:Rainbows@192.168.6.111");

$mode = :orbital

$lastOptional = ""
$speechQueue = Queue.new
def speak(optional, mandatory = "")
	outStr = "";

	outStr += optional if(optional != $lastOptional)
	$lastOptional = optional;

	outStr += mandatory;

	$speechQueue << outStr
end

$telemachus = KSPFetcher.new();

#speak("KSP Interface online");

load "orbitInfo.rb"
load "landing.rb"
load "atmosphere.rb"

$telemachus.track("v.body") do |bName|
	puts "Body name: #{bName}"
end

loop do
	str = $speechQueue.pop

	`espeak "#{str}"`
end
