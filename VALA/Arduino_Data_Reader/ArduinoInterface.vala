class ArduinoInterface {
	Posix.FILE arduinoInterface;
	
	public signal void on_packet_received(uint8[] data);
	
	private int64 lastTransmit = int64.MAX;
	private int64 packetTimeout;
	
	private uint 	bufSize;	
	private uint8[] buf;
	
	private uint 	readPos = 0;
	private uint 	writePos = 0;
		
	private void read_in_byte() {
		int b = 0;
		if((b = arduinoInterface.getc()) != Posix.FILE.EOF) {
			buf[writePos++] = (uint8)b;
			if(writePos == bufSize) writePos = 0; 
						
			lastTransmit = get_monotonic_time();
		}
	}
	
	private void call_packet_received() {
		uint8[] data = new uint8[0];
		
		while(this.get_available() > 0)
			data += this.getc();
		
		this.on_packet_received(data);
		
		this.clear();
		this.lastTransmit = int64.MAX;
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
	
	public ArduinoInterface(string port, Posix.speed_t baudrate = Posix.B9600, int64 packetTimeout = 5000, int buffer_size = 100) {
		
		var handle = Posix.open (port, Posix.O_RDWR | Posix.O_NOCTTY | Posix.LOG_NDELAY);
		
		Posix.termios termios;
		Posix.tcgetattr(handle, out termios);
		
		Posix.cfsetispeed (ref termios, baudrate);
		Posix.cfsetospeed (ref termios, baudrate);
		
		Posix.tcsetattr (handle, Posix.TCSAFLUSH, termios);
		
		arduinoInterface = Posix.FILE.fdopen(handle, "rw");
		
		buf = new uint8[buffer_size];
		bufSize = buffer_size;
		
		this.packetTimeout = packetTimeout;
		
		Thread<void*> arduino_reading_thread = new Thread<void*> ("Arduino reading thread", () => { 
			while(true) { 
				this.read_in_byte(); 
				
				if(this.lastTransmit < (get_monotonic_time() - this.packetTimeout)) {
					this.call_packet_received();
				}
				
				Thread.usleep(100);
			} } );
	}
		
}
