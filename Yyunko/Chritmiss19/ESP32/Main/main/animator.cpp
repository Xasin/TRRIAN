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

#include <array>

#include "esp_log.h"

#define CHEVRON_SYM_COUNT 16

namespace SG {
namespace Animator {

using namespace Peripheral;

Color chevron_base = Color(0);
Color chevron_base_target = Color(0);

Layer all_chevrons = Layer(CHEVRON_SYM_COUNT);
Layer active_chevrons   = Layer(CHEVRON_SYM_COUNT);

TickType_t next_chevron_tick = 0;

int tgt_chevron_pos = -1;
int last_chevron_pos = 0;
int chevron_move_count = 0;
bool chevron_dir = false;

void init_chevrons() {
}

void draw_chevrons() {
	chevron_base.merge_transition(chevron_base_target, 1000);

	all_chevrons.fill(chevron_base);
	//all_chevrons.merge_overlay(active_chevrons);

	if(tgt_chevron_pos == -1)
		return;

	all_chevrons[last_chevron_pos] = Color(Material::BLUE, 80);

	if(xTaskGetTickCount() >= next_chevron_tick) {
		next_chevron_tick = xTaskGetTickCount() + 80;

		last_chevron_pos += chevron_dir ? 1 : -1;
		chevron_move_count++;

		if(last_chevron_pos < 0)
			last_chevron_pos = CHEVRON_SYM_COUNT-1;
		if(last_chevron_pos > CHEVRON_SYM_COUNT)
			last_chevron_pos = 0;

		if((chevron_move_count > 5) && (tgt_chevron_pos == last_chevron_pos)) {
			tgt_chevron_pos = -1;
			chevron_dir ^= 1;
			chevron_move_count = 0;

			active_chevrons[last_chevron_pos] = Color(Material::BLUE, 255, 80);
		}
	}
}
void clear_chevrons() {
	active_chevrons.fill(Color(Material::BLUE, 255, 0));
	chevron_base_target = Color(Material::CYAN, 255, 0);

	tgt_chevron_pos = -1;
	last_chevron_pos = 0;
	chevron_dir = false;
	chevron_move_count = 0;
	next_chevron_tick = 0;
}

void all_chevrons_soft() {
	chevron_base_target = Color(Material::CYAN, 255, 80);
}

void anim_thread(void *args) {
	ESP_LOGI("Anim", "Thread started!");

	while(true) {
		vTaskDelay(10);
		HW::raw_leds.colors.fill(0);

		draw_chevrons();

		HW::raw_leds.colors.merge_overlay(all_chevrons);
		HW::raw_leds.update();
	}
}

void init() {
	xTaskCreate(anim_thread, "SG::Anim", 10*1024, nullptr, 10, nullptr);
}

}
}
