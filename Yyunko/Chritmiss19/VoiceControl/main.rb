
require 'mqtt/sub_handler'
require 'pocketsphinx-ruby'

$mqtt = MQTT::SubHandler.new("mqtt://nhObg2PzQaQVckEJtj1fHEEhypTEWeH9lj8sbNPQMuzME2mVbb0HDsM1HvttxZqJ@mqtt.flespi.io");

cfg = Pocketsphinx::Configuration::Grammar.new("Grammar.JSGF");
cfg['logfn'] = "/dev/null";
rec = Pocketsphinx::LiveSpeechRecognizer.new(cfg);

def speak(text)
	`espeak "#{text}" &`
end

$mqtt.subscribe_to "StarGate/Yyunko/CurrentLock" do |data|
	if(data == "0")
		speak "Gate deactivated"
		next;
	end

	speak "Chevron #{data} locked!"
end

rec.recognize do |sentence|
	puts "Recognized #{sentence}"

	case sentence
	when /authorize/
		$mqtt.publish_to "StarGate/Yyunko/Authorized", "Y"
	when /initiate dialing/
		$mqtt.publish_to "StarGate/Yyunko/SetTarget", "7"
		$mqtt.publish_to "StarGate/Yyunko/Authorized", "N"
	when /close wormhole/
		$mqtt.publish_to "StarGate/Yyunko/SetTarget", "0"
	end
end
