
#include "clock.h"

namespace SG {
namespace Animator {
namespace Clock {

bool active = false;
uint16_t cAlpha = 0;

using namespace Peripheral;

ClockDial::ClockDial(int size)
	: next_tick(0), fade_prescaler(0),
	move_time(100), fade_time(2),
	current_pos(0),
	l_base(size), target_pos(-1),
	l_color(size), l_ind(size),
	dial_color(0, 0, 0), ind_color(0, 0, 0) {

	l_base.alpha = 4;
	l_base.fill(Color(0, 0, 0));
	l_color.fill(Color(0, 0, 0));
	l_ind.fill(Color(0, 0, 0));

	l_color.alpha = 2;
}

Layer &ClockDial::tick() {
	if((--fade_prescaler) <= 0) {
		fade_prescaler = fade_time;
		l_color.merge_transition(l_base);
	}

	if(xTaskGetTickCount() >= next_tick && current_pos != target_pos) {
		next_tick = xTaskGetTickCount() + move_time;

		current_pos += target_pos > current_pos ? 1 : -1;
	}
	l_color[current_pos].merge_transition(dial_color, 2000);
	l_ind[current_pos].merge_transition(ind_color, 2000);

	l_ind.merge_transition(l_color);

	return l_ind;
}

Layer dial_layer  = Layer(CHEVRON_DIAL_COUNT);
Layer alarm_layer = Layer(ALARM_COUNT);
Layer kwhoosh_layer = Layer(KWHOOSH_COUNT);

ClockDial minutes = ClockDial(CHEVRON_DIAL_COUNT);
ClockDial seconds = ClockDial(ALARM_COUNT);
ClockDial hours   = ClockDial(KWHOOSH_COUNT);

void init() {
	seconds.move_time = 800;
	seconds.fade_time = 40;
	seconds.dial_color = Color(Material::BLUE, 60, 160);
	seconds.ind_color  = Color(Material::CYAN, 80, 160);

	minutes.move_time = 100;
	minutes.fade_time = 1500;
	minutes.dial_color = Color(Material::BLUE, 70, 180);
	minutes.ind_color = Color(Material::BLUE, 120, 180);

	hours.move_time = 100;
	hours.fade_time = 5000;
	hours.dial_color = Color(Material::BLUE, 60, 140);
	hours.ind_color = Color(Material::CYAN, 80, 160);
}

void tick() {
	auto time = HW::get_time();

	seconds.target_pos = 1 + (ALARM_COUNT*(59 - time->tm_sec)/60) % ALARM_COUNT;

	minutes.target_pos = 2 + (CHEVRON_DIAL_COUNT*(59 - time->tm_min)/60) % CHEVRON_DIAL_COUNT;
	hours.target_pos   = (11 - time->tm_hour%12);

	alarm_layer = seconds.tick();
	dial_layer = minutes.tick();
	kwhoosh_layer = hours.tick();

	if(active) {
		if(cAlpha < 65000) {
			cAlpha += 500;
		}
		else {
			cAlpha = 65535;
		}
	}
	else {
		if(cAlpha > 2000) {
			cAlpha -= 1500;
		}
		else {
			cAlpha = 0;
		}
	}

	dial_layer.alpha = cAlpha >> 8;
	kwhoosh_layer.alpha = dial_layer.alpha;
	alarm_layer.alpha = dial_layer.alpha;
}

}
}
}
