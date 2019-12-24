
#ifndef __ANIMATION_DIAL_ALERT__
#define __ANIMATION_DIAL_ALERT__

#include "../hw_def.h"

#define ALERT_LED_NUM 9

namespace SG {
namespace Animator {
namespace Alert {

extern Peripheral::Layer alert_leds;
extern Peripheral::Color alert_color;

void init();
void tick();

void stop();
void start();

}
}
}

#endif
