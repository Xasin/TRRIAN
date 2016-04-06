delegate ArduSensor sensor_constructor(ArduinoInterface comsInterface, uint8 number);

class SensorWindow : Gtk.Bin {
	
	public ArduinoInterface arduComs {public get; private set;}
	private ArduSensor[] sensors;
	
	public signal void create_new_sensor(uint8[] data);
	
	private Gtk.ListBox dispBox;
			
	public SensorWindow(ArduinoInterface coms) {
		this.arduComs = coms;
		
		this.dispBox = new Gtk.ListBox();
		this.add(dispBox);
		this.show_all();
		
		arduComs.on_packet_received.connect( (data) => {
			for(int i=0; i<sensors.length; i++) {
				if(sensors[i].matches_ident(data))
					return;
			}
			
			this.create_new_sensor(data);
		});
	}
	
	public void add_new_sensor(sensor_constructor c, string ident) {
		this.create_new_sensor.connect( (data) => {			
			if(((string)data)[0:1] == ident[0:1])
				dispBox.add(c(arduComs, data[ident.length+1]));
		} );
	}
}
