/*
 * hw_def.cpp
 *
 *  Created on: 1 Dec 2019
 *      Author: xasin
 */

#include "hw_def.h"

namespace SG {
namespace HW {

Peripheral::NeoController raw_leds = Peripheral::NeoController(PIN_WS2812, RMT_CHANNEL_0, 16);

void init() {
}

}
}
