struct dataInput {
	uint8 pin;
	int16 data;
}

class ardIntface {
	Posix.FILE arduinoInterface;
	
	public signal void on_data_received(dataInput input);
	
	private int[] buf = new int[64];
	private uint8 readPos = 0;
	private uint8 writePos = 0;
	
	private uint8 get_available() {
		if(readPos <= writePos) 
			return writePos - readPos;
		else 
			return (writePos + 64) - readPos;
	}
	
	private int read() {
		if(this.get_available() > 0) {
			int i = buf[readPos];
			
			if(++readPos == 64) readPos = 0;
			
			stdout.printf("R: " + i.to_string() + "\n");
			
			return i;
		}
		else 
			return 0;
	}
	
	private void receive() {
		int b = 0;
		while((b = arduinoInterface.getc() )== Posix.FILE.EOF) { Thread.usleep(5000); }
		
		buf[writePos++] = b;
		if(writePos == 64) writePos = 0;
		
		Thread.usleep(5000); 
	}
	
	private void check_coms() {
		
		receive();
		
		if(this.get_available() > 3) {
			dataInput iData = {0, 0};
			iData.pin = (uint8)this.read();
			iData.data = (int16)(this.read() * 256 + this.read());
			this.on_data_received(iData);
		}
	}
	
	public ardIntface(string port) {
		arduinoInterface = Posix.FILE.open(port, "r+");
		
		Thread<void*> input_check_thread = new Thread<void*> ("Arduino Interface Thread", () => { while(true) { this.check_coms(); } });
	}
		
}



int main() {
	
	var ardu = new ardIntface("/dev/ttyACM0");

	ardu.on_data_received.connect( (dataStuff) => { stdout.printf("Received data: " + dataStuff.data.to_string() + "\n"); } );

	while(true) {
		Thread.usleep(1000000);
	}
	
	return 0;
}
