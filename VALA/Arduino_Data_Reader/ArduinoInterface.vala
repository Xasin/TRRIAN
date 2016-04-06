class ArduinoInterface {
	Posix.FILE arduinoInterface;
	
	public signal void on_packet_received();
	
	private int64 lastTransmit = int64.MAX;
	private int64 packetTimeout = 5000;
	
	private uint 	bufSize;	
	private uint8[] buf;
	
	private uint 	readPos = 0;
	private uint 	writePos = 0;
		
	private void read_in_byte() {
		int b = 0;
		
		while((b = arduinoInterface.getc() ) == Posix.FILE.EOF) { 
			Thread.usleep(1000);
			
			if(lastTransmit < get_monotonic_time() - this.packetTimeout) {
				this.on_packet_received();
				this.clear();
				
				this.lastTransmit = int64.MAX;
			}
		}
		
		lastTransmit = get_monotonic_time();
		
		buf[writePos++] = (uint8)b;
		if(writePos == bufSize) writePos = 0; 
		
		stdout.printf("Rec: " + b.to_string() + "\n");
	}
	
	public void clear() {
		this.readPos = this.writePos;
	}
	
	public uint get_available() {
		if(readPos <= writePos) 
			return writePos - readPos;
		else 
			return (writePos + bufSize) - readPos;
	}
	
	public uint8 getc() {
		if(this.get_available() > 0) {
			uint8 i = buf[readPos];
			
			if(++readPos == bufSize) readPos = 0;
			
			return i;
		}
		else 
			return -1;
	}
	
	public int peek(uint pos = 0) {
		if(pos < bufSize) {
			if(pos >= this.get_available())
				return -1;
			else {
				if((pos += readPos) > bufSize) pos -= bufSize;
				
				return buf[pos];
			}
		}
		else 
			return -1;
	}
	
	public ArduinoInterface(string port, int baudrate = 9600, int64 packetTimeout = 5000, int buffer_size = 100) {
		arduinoInterface = Posix.FILE.open(port, "r");
		
		buf = new uint8[buffer_size];
		bufSize = buffer_size;
		
		this.packetTimeout = packetTimeout;
		
		Thread<void*> arduino_reading_thread = new Thread<void*> ("Arduino reading thread", () => { while(true) { this.read_in_byte(); } } );
	}
		
}

int main() {
	
	var sensorduino = new ArduinoInterface("/dev/ttyACM0");
	
	sensorduino.on_packet_received.connect( () => { 
			stdout.printf("Pin: " + sensorduino.getc().to_string() + " - Value: " + ((int16)(sensorduino.getc() * 256 + sensorduino.getc())).to_string() + "\n");
	} );
	
	while(true) {
	}
	
	return 0;
}
