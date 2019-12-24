/*
 * animator.cpp
 *
 *  Created on: 1 Dec 2019
 *      Author: xasin
 */


#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

#include "animator.h"

#include "hw_def.h"
#include "mqtt_con.h"

#include <array>

#include "esp_log.h"

namespace SG {
namespace Animator {

using namespace Peripheral;

TickType_t last_time_synch;

void anim_thread(void *args) {
	ESP_LOGI("Anim", "Thread started!");

	while(true) {
		vTaskDelay(19);

		Gate::tick();

		Clock::active = Conn::clock_active;
		if(Gate::gate_active())
			Clock::active = false;

		bool alert_on = Gate::chevron_count != 0;
		if(Conn::authorized_dial)
			alert_on = false;

		Alert::alert_color = alert_on ? Color(Material::RED) : Color(0, 0, 0);

		Chevrons::tick();
		Alert::tick();
		Clock::tick();

		HW::dial_layer.fill(0);
		HW::dial_layer.merge_overlay(Clock::dial_layer);
		HW::dial_layer.merge_overlay(Chevrons::chevron_dials);

		HW::kwhoosh_layer.fill(0);
		HW::kwhoosh_layer.merge_overlay(Gate::core_layer);
		HW::kwhoosh_layer.merge_overlay(Clock::kwhoosh_layer);

		HW::alarm_layer.fill(0);
		HW::alarm_layer.merge_overlay(Clock::alarm_layer);
		HW::alarm_layer.merge_overlay(Alert::alert_leds);

		HW::chevron_layer = Chevrons::chevrons;

		Conn::tick();

		HW::layer_remap_and_update();
	}
}

void init() {
	Chevrons::init();
	Alert::init();
	Clock::init();

	Gate::init();

	last_time_synch = xTaskGetTickCount();

	xTaskCreatePinnedToCore(anim_thread, "SG::Anim", 10*1024, nullptr, 2, nullptr, 1);
}

}
}
