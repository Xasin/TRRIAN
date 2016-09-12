use <TagSystem/Tagging.scad>

cam_innerRadius = 51/2;
cam_outerRadius = 56/2;
cam_attachThickness = 1;

cam_attachHeight = 3;

cam_totalheight = cam_attachHeight + cam_attachThickness;

cam_adapterrad = 55.2;
cam_adapterheight = 2;

led_num = 9;
led_distance = cam_outerRadius + 6;
led_centering_dist = 200;
led_angle = 90 - atan(led_centering_dist/led_distance);

$fa = 5;

module basic_ring_adapter() {
	translate([0, 0, cam_totalheight]) difference() {
		cylinder(d = cam_adapterrad + cam_attachThickness * 2, h = cam_adapterheight);
		translate([0, 0, -0.1]) cylinder(d = cam_adapterrad, h = cam_adapterheight + 1);
	}
}

module led_mount() {
	$fs = 0.5;
	translate([0, 0, cam_totalheight/2]) {
		tag("positive") cylinder(d = 5 + 3, h = cam_totalheight, center=true);
		
		tag("negative", false) rotate([led_angle, 0, 0]) cylinder(d = 5.4, h = cam_totalheight + 4, center=true);
	}
}

module leds() {
	for(i = [0:360/led_num:360]) rotate([0, 0, i]) 
		translate([0, led_distance, 0]) led_mount();
}

module frame_basic() {
	hull() leds();
	basic_ring_adapter();
}

module cutout_lens() {
	cylinder(r = cam_innerRadius - cam_attachThickness, h = 100);
}

module cutout_screw() {
	difference() {
		cylinder(r = cam_outerRadius, h = cam_attachHeight);
		cylinder(r = cam_innerRadius, h = cam_attachHeight);
	}
}

module frame() {
	difference() {
		frame_basic();
		
		translate([0, 0, -0.001]) union() {
			showTag("negative") leds();
			cutout_lens();
			cutout_screw();
		}
	}
}

frame();