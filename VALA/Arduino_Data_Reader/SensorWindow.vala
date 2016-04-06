class SensorWindow : Gtk.Bin {
	
	public ArduinoInterface arduComs {public get; private set;}
	private ArduSensor[] sensors;
	
	private Gtk.ListBox dispBox;
	
	private sensorType[] typeList;
		
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
	
	public void add_new_sensor(ArduSensor newSensor) {
		this.dispBox.add(newSensor);
		this.sensors += newSensor;
	}
}
