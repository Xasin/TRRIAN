
require 'json'

class KSPFetcher
	def initialize(uri = "localhost:8085")
		@URI = uri;

		@fastTrack = Array.new();
		@slowTrack = Array.new();

		@onChanges =  Hash.new() do |h, key|
			h[key] = Array.new();
		end
		@currentVals = Hash.new();

		@lastError = Time.at(0);

		Thread.new do
			slowCntr = Time.now();
			loop do
				sleep 0.5;
				sleep 5 if (@lastError + 2) > Time.now();

				_fetch_params(@fastTrack) unless @fastTrack.empty?;

				next if(slowCntr > Time.now());
				slowCntr = Time.now() + 5;
				_fetch_params(@slowTrack) unless @slowTrack.empty?;
			end
		end
	end

	def _fetch_params(pList)
		fetchStr = @URI;
		fetchStr += "/telemachus/datalink?"

		indexNum = ("a".."z").to_a;
		queryStr = Array.new();
		pList.each_index do |pInd|
			queryStr << "#{indexNum[pInd]}=#{pList[pInd]}"
		end
		fetchStr += queryStr.join("&");

		oPut = `curl -s "#{fetchStr}"`

		begin
			parsed = JSON.parse(oPut);
		rescue
			@lastError = Time.now();
			return;
		end
		
		parsed.each do |key, val|
			@lastError = Time.now() if(key == "errors")

			next unless index = indexNum.find_index(key);
			resKey = pList[index];
			next unless resKey;
			next if val == @currentVals[resKey];

			@onChanges[resKey].each do |cb|
				cb.call(val, @currentVals[resKey]);
			end
			@currentVals[resKey] = val;
		end
	end

	def track(tag, fast: false, &block)
		arr = fast ? @fastTrack : @slowTrack;
		arr << tag unless arr.include?(tag);

		@onChanges[tag] << block if block;
	end

	def [](key)
		return @currentVals[key];
	end
end
