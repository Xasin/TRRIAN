

lastHeight = 0;

$telemachus.track("v.verticalSpeed");

$telemachus.track("v.heightFromTerrain") do |height|

	next unless height > 0
	next unless height < 5000
	next unless $telemachus["v.verticalSpeed"] < 1;

	next unless (height/lastHeight - 1).abs >= 0.1;

	steps = (10 ** Math.log(height, 10).floor);

	height = (height/steps).round() * steps;

	if(lastPeriapsis != nAlt)
		speak("Altitude ", "#{height} meters");
		lastHeight = height;
	end
end
