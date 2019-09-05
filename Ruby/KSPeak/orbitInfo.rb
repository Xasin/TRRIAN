
class LogFilter
	attr_accessor :min, :max, :minCPercent, :minCAbsolute
	attr_accessor :maxPSpeed
	attr_accessor :stepSize
	attr_accessor :enabled

	def initialize(&block)
		@currentValue = 0;
		@lastValue 	  = 0;
		@changeSpeed  = 0;

		@lastRoundedValue = 0;

		@lastChgTime = Time.now();

		@min = 0;
		@max = nil;
		@minCPercent = 0.1;
		@minCAbsolute = 1;
		@maxPSpeed = 0.05;
		@stepSize = 0.25;

		@enabled = true;

		@onChanged = block;
	end

	def recalc_rounded()
		return unless @enabled;

		return if @currentValue < @min;
		return if @max and @currentValue > @max;

		return if (@currentValue - @lastRoundedValue)/@lastRoundedValue < @minCPercent;
		return if (@currentValue - @lastRoundedValue) < @minCAbsolute;

		return if (@changeSpeed/@currentValue) > @maxPSpeed;

		magnitude = (10 ** Math.log(@currentValue, 10).floor);
		stepSize = magnitude * @stepSize;

		return if (@currentValue - @lastRoundedValue).abs < stepSize;

		roundedValue = (@currentValue/stepSize).round() * stepSize;

		@onChanged.call(roundedValue, @lastRoundedValue);
		@lastRoundedValue = roundedValue;
	end

	def value=(nValue)
		@changeSpeed = (nValue - @currentValue) / (Time.now() - @lastChgTime);
		@lastChgTime = Time.now();
		@lastValue = @currentValue;
		@currentValue = nValue;

		recalc_rounded();
	end
end

periapsisFilter = LogFilter.new() do |nPep|
	speak("Periapsis at", "#{nPep.round} kilometers");
end
$telemachus.track("o.PeA") do |nAlt, oAlt|
	periapsisFilter.value = nAlt;
end

apoapsisFilter = LogFilter.new() do |nPep|
	speak("Apoapsis at", "#{nPep.round} kilometers");
end
$telemachus.track("o.ApA") do |nAlt, oAlt|
	apoapsisFilter.value = nAlt;
end
