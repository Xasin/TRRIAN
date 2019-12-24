/*
 * gate_handling.h
 *
 *  Created on: 8 Dec 2019
 *      Author: xasin
 */

#ifndef MAIN_ANIMATION_GATE_HANDLING_H_
#define MAIN_ANIMATION_GATE_HANDLING_H_

#include "../hw_def.h"

namespace SG {
namespace Animator {
namespace Gate {

enum gate_state_t {
	OFF,
	CHEVRON_WAIT_ON_NEXT,
	CHEVRON_DIALING,
	CHEVRON_WAIT_LOCK,
	WORMHOLE_OPEN,

};

extern int chevron_count;
extern int chevron_current_locked;

extern Peripheral::Layer core_layer;

bool gate_active();

void init();
void tick();

}
}
}


#endif /* MAIN_ANIMATION_GATE_HANDLING_H_ */
