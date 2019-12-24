

#ifndef __ANIMATION_CLOCK__
#define __ANIMATION_CLOCK__

#include "../hw_def.h"

namespace SG {
namespace Animator {
namespace Clock {

extern bool active;

class ClockDial {
public:
	TickType_t next_tick;
	int fade_prescaler;

	int move_time;
	int fade_time;

	int current_pos;

	Peripheral::Layer l_base;

	int target_pos;

	Peripheral::Layer l_color;
	Peripheral::Layer l_ind;

	Peripheral::Color dial_color;
	Peripheral::Color ind_color;

	ClockDial(int size);

	Peripheral::Layer &tick();
};

extern Peripheral::Layer dial_layer;
extern Peripheral::Layer alarm_layer;
extern Peripheral::Layer kwhoosh_layer;

void init();
void tick();

}
}
}

#endif
