/*
 * gate_handling.cpp
 *
 *  Created on: 8 Dec 2019
 *      Author: xasin
 */

#include "gate_handling.h"
#include "chevron_handling.h"

#include "ManeAnimator.h"

namespace SG {
namespace Animator {
namespace Gate {

Peripheral::Layer core_layer   = Peripheral::Layer(KWHOOSH_COUNT);

Peripheral::Color core_color_c = 0;
Peripheral::Color core_color_t2 = 0;
Peripheral::Color core_color_t1 = 0;

auto whooshimator = ManeAnimator(KWHOOSH_COUNT);

gate_state_t target_state = OFF;
gate_state_t current_state = OFF;

int chevron_count = 0;
int chevron_current_locked = 0;

int gate_type = 0;

const int chevron_dial_order[] = {
		1, 8, 3, 6, 2, 7, 0, 4, 5
};

TickType_t switch_pause = 0;

void abort_dial() {
	// TODO Play the dial abort sound
	Chevrons::deactivate();

	chevron_current_locked = 0;
	chevron_count = 0;
	current_state = OFF;

	puts("Bweehhhh..");
}
void open_wormhole() {
	// TODO Play the BWA BWA - KAWOOSH
	// TODO Add the center wormhole glow

	puts("BWA BWA!");
	Chevrons::all_soft();
	current_state = WORMHOLE_OPEN;

	core_color_c  = Material::BLUE;
	core_color_t1 = 0xFFFFFF;

	if(gate_type == 1)
		core_color_t2 = Peripheral::Color(Material::PURPLE, 190);
	else
		core_color_t2 = Peripheral::Color(Material::BLUE, 190);

	for(int i=0; i<KWHOOSH_COUNT; i++) {
		whooshimator.points[i].pos = 0;
	}
}
void close_wormhole() {
	Chevrons::deactivate();

	chevron_current_locked = 0;
	chevron_count = 0;
	current_state = OFF;

	core_color_t1 = Peripheral::Color(0xFFFFFF, 170, 0);
	core_color_t2 = 0;

	puts("Bwwwchhwwwooohp");
}

bool gate_active() {
	if(current_state != OFF)
		return true;
	if(chevron_count != 0)
		return true;

	return false;
}

void init() {
	whooshimator.basePoint = 0.5;
	whooshimator.baseTug = 0.004;
	whooshimator.dampening = 0.98;

	whooshimator.wrap = true;
	whooshimator.ptpTug = 0.03;
}

int last_vortex_beep = 0;
void tick() {
	whooshimator.tick();

	if((esp_random() % 32) < 4) {
		if(gate_type == 1)
			whooshimator.points[last_vortex_beep++ % KWHOOSH_COUNT].pos = 1;
		else
			whooshimator.points[esp_random() % KWHOOSH_COUNT].vel += 0.03;
	}

	core_color_t1.merge_transition(core_color_t2, 1000);
	core_color_c.merge_transition(core_color_t1, 10000);

	core_layer.fill(core_color_c);
	core_layer.alpha_set(whooshimator.scalarPoints);

	if(switch_pause > xTaskGetTickCount())
		return;

	switch(current_state) {
	case OFF:
		if(chevron_count > 0) {
			current_state = CHEVRON_WAIT_ON_NEXT;
			switch_pause = xTaskGetTickCount() + 1000;
		}
	break;
	case CHEVRON_WAIT_ON_NEXT:
		if(chevron_count == 0) {
			abort_dial();
			break;
		}

		if(chevron_count > chevron_current_locked) {
			Chevrons::dial_to(1 + 4*chevron_dial_order[chevron_current_locked]);
			current_state = CHEVRON_DIALING;
		}
	break;
	case CHEVRON_DIALING:
		if(!Chevrons::dial_ready())
			break;
		if(chevron_count == 0) {
			abort_dial();
			break;
		}

		Chevrons::lock_chevron(chevron_dial_order[chevron_current_locked]);
		chevron_current_locked++;

		current_state = CHEVRON_WAIT_LOCK;
	break;

	case CHEVRON_WAIT_LOCK:
		if(!Chevrons::dial_ready())
			break;

		if(CHEVRON_COUNT == 0) {
			abort_dial();
			break;
		}

		if(chevron_current_locked >= 7 && chevron_count == chevron_current_locked) {
			open_wormhole();
			break;
		}

		current_state = CHEVRON_WAIT_ON_NEXT;
	break;

	case WORMHOLE_OPEN:
		if(chevron_count == 0) {
			close_wormhole();
		}
	break;
	}
}

}
}
}
