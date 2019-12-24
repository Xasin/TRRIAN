

#include "dial_alert.h"

#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

namespace SG {
namespace Animator {
namespace Alert {

using namespace Peripheral;

Layer alert_leds = Layer(ALERT_LED_NUM);
Color alert_color = Color(0, 0, 0);

Layer l_alert_tgt = alert_leds;
Color c_alert_smoothed = alert_color;

void init() {
	alert_leds.fill(Color(0, 0, 0));
	l_alert_tgt = alert_leds;

	l_alert_tgt.alpha = 14;
}

void tick() {
	int alert_pos = (xTaskGetTickCount() / 80) % ALERT_LED_NUM;

	c_alert_smoothed.merge_transition(alert_color, 10000);

	alert_leds.merge_transition(l_alert_tgt);
	alert_leds[alert_pos].merge_overlay(c_alert_smoothed, 200);
}

void start() {
	alert_color = 0xAA0000;
}
void stop() {
	alert_color = Color(0, 0, 0);
}

}
}
}
