class ArduSensor : Gtk.Bin {	

	protected string ident = "DEFAULT";
	protected uint8 num = 0;

	public ArduSensor() {
	}

	public bool matches_ident(uint8[] data) {
		return ((string)data)[0:2] == (ident + ((char)num).to_string())[0:2];
	}
}

class SensorIRDist : ArduSensor {

	public SensorIRDist(ArduinoInterface inface, uint8 pin) {

		this.num = pin;
		this.ident = "DS";

		var outputLabel = new Gtk.Label("DATA");

		this.add(outputLabel);

		inface.on_packet_received.connect( (data) => {
			if(this.matches_ident(data))
				outputLabel.set_text("Distance: " + ((int)(4.0 * 600 / (data[3] * 256 + data[4]))).to_string());
			} );

		this.show_all();
	}
}

class SensorJS : ArduSensor {

	public SensorJS(ArduinoInterface inface, uint8 num) {

		this.num = num;
		this.ident = "JS";

		var outputLabel = new Gtk.Label("JS-DATA");

		this.add(outputLabel);

		inface.on_packet_received.connect( (data) => {
			if(matches_ident(data))
				outputLabel.set_text("Joystick: " + (data[3] * 256 + data[4]).to_string() + " " + (data[5] * 256 + data[6]).to_string());
			} );

		this.show_all();
	}
}

class ArduWindow : Gtk.Application {

	ArduinoInterface arduConnection;

	SensorWindow outputBox;

	public ArduWindow() {
		Object (application_id: "org.xasin.arduwindow");
	}

	public override void activate() {

		arduConnection = new ArduinoInterface("/dev/ttyACM0");

		var window = new Gtk.ApplicationWindow(this);
		window.title = "Arduino input";

		outputBox = new SensorWindow(arduConnection);

		outputBox.add_new_sensor( (intf,num) => { return new SensorIRDist(intf, num); }, "DS");

		window.add(outputBox);
		window.show_all();

	}
}

int main(string[] args) {
	var iface = new ArduWindow();

	return iface.run(args);
}
