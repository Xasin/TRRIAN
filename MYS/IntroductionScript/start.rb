

require 'mqtt/sub_handler.rb'

$mqtt = MQTT::SubHandler.new("mqtt://Xasin:ChocolateThings@192.168.6.111");
puts "MQTT Connected!";

$debugMSGs = Array.new();
def add_debug(dbgMsg)
	dbgMsg.gsub!("OK",'<font color="green">OK</font>');

	$debugMSGs = $debugMSGs.drop(1) if $debugMSGs.length() > 20;
	$debugMSGs << dbgMsg;

	$mqtt.publish_to "MYS/DebugField", $debugMSGs.join("");
end

def set_switch(on)
	add_debug "Setting lights... OK<br>"
	$mqtt.publish_to "Room/default/Lights/Set/Switch", on ? "on" : "off", retain: true;
end
def set_color(color)
	add_debug "Changing color to #{color}... OK<br>"
	$mqtt.publish_to "MYS/Color", color;
	$mqtt.publish_to "Room/default/Lights/Set/Color", "##{color}";
end

def set_cntdwn(number)
	$mqtt.publish_to "MYS/Countdown", number.to_s;
end

Thread.new do
	sleep 5;

	$hackMSG = ["Trying ARP Spoof...", "Looking for open ports...", "Adjusting firewall...",
					"Restarting ignition sequence...", "Overriding launch codes...",
					"Starting DNA Fabrication...", "Rerouting energy..."]
	until $hackMSG.empty? do
		$hackMSG.shuffle

		add_debug "<font color='orange'>#{$hackMSG.pop}</font>"
		sleep rand 2..15
	end
end.abort_on_exception = true;

Thread.new do
	$remainingTime = 60;
	loop do
		set_cntdwn $remainingTime;
		$remainingTime -= 1;

		sleep 1.1;
	end
end

def speak(message)
	add_debug "Speaking..."
	`espeak -vde "#{message}"`
	add_debug "OK<br>"
end

sleep 10

set_switch true
set_color "000000"
sleep 3
speak "Guten morgen, und hallo."
speak "David ist leider gerade mit einer Klausur beschäftigt, wird aber später noch dazu stoßen."
speak "Er hat mich damit beauftragt, ihn und ein paar seiner Projekte kurz vor zu stellen."
speak "Fangen wir mal mit mir an: Ich bin sein Di ei wei Smart Home."
speak "Gebaut wurde ich vor ca. zwei Jahren, und laufe auf einem Raspberry Pi. Ausgestattet bin ich mit einer Vielzahl an Sensoren, einer Uhr" # TODO Integrate clock!
set_color "ff0000"
speak "und einem LED Lichtstreifen"
set_color "00ff00"
speak "Welcher einen recht netten"
set_color "0000ff"
speak "Tageslichtverlauf emulieren kann."
set_color "000000"

speak "Neben mir hat David auch noch ein eigenes Lasertag entwickelt, welches auf dem ESP32 basiert."
speak "Auskennen tut er sich also am besten mit Embedded Elektronik und Hardware kommunikation"
speak "Scheut aber nicht davor zurück, sich auch bei anderen Fragen an ihn zu wenden."

speak "Und nun, habt ein paar schöne Tage, und viel Erfolg!"
set_switch false
