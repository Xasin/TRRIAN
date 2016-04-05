class ardIntface {
	Posix.FILE arduinoInterface;
	
	private uint 	bufSize;
		
	private uint8[] buf;
	private uint 	readPos = 0;
	private uint 	writePos = 0;
		
	private void read_in_byte() {
		uint8 b = 0;
		while((b = (uint8)arduinoInterface.getc() )== Posix.FILE.EOF) { 
			Thread.usleep(5000); 
		}
		
		buf[writePos++] = b;
		if(writePos == bufSize) writePos = 0; 
	}
	
	public uint get_available() {
		if(readPos <= writePos) 
			return writePos - readPos;
		else 
			return (writePos + bufSize) - readPos;
	}
	
	public uint8 get_c() {
		if(this.get_available() > 0) {
			uint8 i = buf[readPos];
			
			if(++readPos == bufSize) readPos = 0;
			
			return i;
		}
		else 
			return 0;
	}
	
	public ardIntface(string port, uint buffer_size = 256) {
		arduinoInterface = Posix.FILE.open(port, "r+");
		
		buf = new uint8[buffer_size];
		
		Thread<void*> arduino_reading_thread = new Thread<void*> ("Arduino reading thread", () => { while(true) { this.read_in_byte(); } } );
	}
		
}
