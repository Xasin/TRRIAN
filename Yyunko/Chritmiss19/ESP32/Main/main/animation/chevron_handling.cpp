
#include "chevron_handling.h"

#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

namespace SG {
namespace Animator {
namespace Chevrons {

using namespace Peripheral;

// Interface layers
Layer chevron_dials = Layer(CHEVRON_DIAL_COUNT);
Layer chevrons      = Layer(CHEVRON_COUNT);

// Internal chevron dial variables
int chevron_dial_target = -1;
int chevron_dial_current = 1;
int chevron_dial_move_count = 0;
int chevron_dial_dir = 1;

TickType_t chevron_dial_last_change = 0;

// Internal chevron dial layers
Layer l_chevron_dial_smoothed = chevron_dials;
Layer l_chevron_dial_target = chevron_dials;
Layer l_chevron_dial_active = chevron_dials;
Layer l_chevron_dial_active_tgt = chevron_dials;

Layer l_chevrons_target = chevrons;
TickType_t chevron_center_clear_time = 0;
bool  chevron_center_should_clear = false;

bool dial_ready() {
	if(chevron_dial_target != -1)
		return false;
	if((chevron_dial_last_change + 300) >= xTaskGetTickCount())
		return false;
	if((chevron_center_clear_time + 1000) >= xTaskGetTickCount())
		return false;

	return true;
}
void dial_to(int tgt) {
	if(tgt < 0)
		tgt = -tgt;

	chevron_dial_last_change = xTaskGetTickCount() + 500;
	chevron_dial_target = tgt % CHEVRON_DIAL_COUNT;

	puts("Bwweeeeeh");
}

void init() {
	l_chevron_dial_smoothed.fill(Color(0, 0, 0));

	l_chevron_dial_target.fill(Color(0, 0, 0));
	l_chevron_dial_target.alpha = 5;

	l_chevron_dial_active_tgt.fill(Color(0, 0, 0));
	l_chevron_dial_active_tgt.alpha = 10;

	l_chevrons_target.fill(Color(0, 0, 0));
	l_chevrons_target.alpha = 24;
}

void draw_rolling_chevron() {
	l_chevron_dial_active.merge_transition(l_chevron_dial_active_tgt);

	if((chevron_dial_target >= 0) && (xTaskGetTickCount() >= (130+chevron_dial_last_change))) {
		chevron_dial_last_change = xTaskGetTickCount();

		chevron_dial_current += chevron_dial_dir;
		chevron_dial_move_count++;

		if(chevron_dial_current < 0)
			chevron_dial_current = CHEVRON_DIAL_COUNT-1;
		if(chevron_dial_current >= CHEVRON_DIAL_COUNT)
			chevron_dial_current = 0;

		if((chevron_dial_move_count >= 14) && (chevron_dial_current == chevron_dial_target)) {
			chevron_dial_target = -1;
			chevron_dial_dir = -chevron_dial_dir;
			chevron_dial_move_count = 0;

			Color chevron_color = Color(Material::BLUE, 255, 180);
			l_chevron_dial_target[chevron_dial_current] = chevron_color;
			l_chevron_dial_smoothed[chevron_dial_current] = chevron_color;
		}
	}

	if(chevron_dial_target >= 0)
		l_chevron_dial_active[chevron_dial_current].merge_transition(Color(Material::BLUE, 255, 150), 40000);
}

void lock_chevron(int tgt) {
		puts("Kchew");

		l_chevrons_target[tgt] = Color(Material::ORANGE);
		l_chevrons_target[0] = Color(Material::RED);

		chevron_center_clear_time = xTaskGetTickCount() + 1000;
		chevron_center_should_clear = true;

	l_chevron_dial_target[1 + 4*tgt] = 0;
}

void draw_chevrons() {
	if(chevron_center_should_clear) {
		if(xTaskGetTickCount() > chevron_center_clear_time) {
			chevron_center_should_clear = false;
			l_chevrons_target[0] = Color(0, 0, 0);
			puts("Kchew");
		}
	}

	chevrons.merge_transition(l_chevrons_target);
}

void tick() {
	// Calculate the current chevron dialing indicator
	draw_rolling_chevron();

	// Calculate the output chevron dials
	l_chevron_dial_smoothed.merge_transition(l_chevron_dial_target);
	chevron_dials = l_chevron_dial_active;
	chevron_dials.merge_overlay(l_chevron_dial_smoothed);

	draw_chevrons();
}

void deactivate() {
	l_chevron_dial_target.fill(Color(0, 0, 0));
	chevron_dial_current = 1;

	l_chevrons_target.fill(Color(0, 0, 0));
}
void all_soft() {
	Color soft_chevron_color = Color(Material::BLUE, 200, 80);

	Layer soft_layer = l_chevron_dial_target;
	soft_layer.fill(soft_chevron_color);

	auto old_alpha = l_chevron_dial_target.alpha;
	l_chevron_dial_target.alpha = 255;
	soft_layer.merge_overlay(l_chevron_dial_target);
	l_chevron_dial_target.alpha = old_alpha;
	l_chevron_dial_target = soft_layer;

	l_chevrons_target.fill(Color(Material::ORANGE, 130, 80));
}

}
}
}
