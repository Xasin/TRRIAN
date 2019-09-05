

planetColors = {
	"Kerbin" => "#808487",
	"Mun" => "#707071",
	"Minmus" => "#708076",
}


$telemachus.track("v.body") do |nName|
	speak "Welcome to #{nName}"
	pC = planetColors[nName];
	puts "Pushing color #{pC}"
	$mqtt.publish_to "Room/default/Lights/Set/Color", pC if pC;
end

$telemachus.track("p.paused") do |paused|
	$mqtt.publish_to "Room/default/Lights/Set/Color", "#000000" if(paused >= 4)
end
