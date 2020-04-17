
require 'midilib/io/seqreader'
require 'midilib/sequence.rb'

# Beep

### Structure of the output:
# 1 byte note-type.
# 1 byte volume
# 2 byte duration

## A note type of 0 indicates a pause!

$fName = ARGV[0] || "melody";

seq = MIDI::Sequence.new();

timecode_note_events = Array.new();

File.open($fName + ".mid", 'rb') { | file |
	seq.read(file);
}

seq.each do |track|
	puts "Processing new track!";

	trackNotes = Hash.new();
	track.each do |event|
		next unless event.is_a? MIDI::NoteEvent;
		lastNote = trackNotes[event.note];

		unless(lastNote.nil? || lastNote.velocity == 0)
			timecode_note_events <<
			[lastNote.time_from_start,
					lastNote.note,
					lastNote.velocity,
					event.time_from_start - lastNote.time_from_start];
		end

		trackNotes[event.note] = event;
	end
end

timecode_note_events.sort_by! {|n| n[0] }

puts("Notes processed: #{timecode_note_events.length} - Generating output");

File.open($fName + '.espmidi', 'w') do |output_evt_file|
	output_evt_file.write <<EOF
#ifndef ESP_MIDI_BLOCK_TYPE
#define ESP_MIDI_BLOCK_TYPE
struct esp_midi_byte_t {
	uint8_t type;
	uint8_t vol;
	uint16_t duration;
};
#endif

const esp_midi_byte_t #{$fName}_midi_data[] = {
EOF

	lastTimecode = 0;
	timecode_note_events.each do |evt|
		deltaT = evt[0] - lastTimecode;
		if(deltaT > 0)
			output_evt_file.puts "{0, 0, #{deltaT}},";
		end

		output_evt_file.puts	"{#{evt[1..3].join(',')}},";

		lastTimecode = evt[0];
	end

output_evt_file.puts "};"
end
