/*
 * hw_def.h
 *
 *  Created on: 1 Dec 2019
 *      Author: xasin
 */

#ifndef MAIN_HW_DEF_H_
#define MAIN_HW_DEF_H_

#define CHEVRON_DIAL_COUNT 36
#define CHEVRON_COUNT		9
#define KWHOOSH_COUNT		12
#define ALARM_COUNT			9

#include "xasin/mqtt/Handler.h"

#include "NeoController.h"
#include "PINS.h"

#include "esp_event.h"
#include "esp_event_loop.h"

#include <ctime>
#include "lwip/apps/sntp.h"

namespace SG {
namespace HW {

extern Xasin::MQTT::Handler mqtt;
extern Peripheral::NeoController raw_leds;

extern Peripheral::Layer dial_layer;
extern Peripheral::Layer kwhoosh_layer;
extern Peripheral::Layer chevron_layer;
extern Peripheral::Layer alarm_layer;

void esp_evt_handler(system_event_t *evt);

void init();

std::tm *get_time();
void time_resynch();

void layer_remap_and_update();

}
}


#endif /* MAIN_HW_DEF_H_ */
