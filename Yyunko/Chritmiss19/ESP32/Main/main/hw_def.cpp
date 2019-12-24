/*
 * hw_def.cpp
 *
 *  Created on: 1 Dec 2019
 *      Author: xasin
 */

#include "hw_def.h"

#include "mqtt_con.h"

#include "lwip/err.h"
#include "lwip/apps/sntp.h"

namespace SG {
namespace HW {

using namespace Peripheral;

Xasin::MQTT::Handler mqtt = Xasin::MQTT::Handler();
Peripheral::NeoController raw_leds = Peripheral::NeoController(PIN_WS2812, RMT_CHANNEL_0, 14*3);

Layer dial_layer = Layer(CHEVRON_DIAL_COUNT);
Layer chevron_layer = Layer(CHEVRON_COUNT);
Layer kwhoosh_layer = Layer(KWHOOSH_COUNT);
Layer alarm_layer   = Layer(ALARM_COUNT);

void esp_evt_handler(system_event_t *event) {
    char sntp_server[] = "pool.ntp.org\0";

    Xasin::MQTT::Handler::try_wifi_reconnect(event);
    mqtt.wifi_handler(event);

    switch(event->event_id) {
    case SYSTEM_EVENT_STA_GOT_IP:
        sntp_setoperatingmode(SNTP_OPMODE_POLL);
        sntp_setservername(0, sntp_server);

        sntp_init();
    break;

    default: break;
    }
}

tm cTime = {};
std::tm *get_time() {
	time_t unixTime;
	time(&unixTime);

	localtime_r(&unixTime, &cTime);
	return &cTime;
}

void time_resynch() {
	sntp_stop();
	sntp_init();
}

void init() {
	setenv("TZ", "UTC+1", 1);
	tzset();

	Xasin::MQTT::Handler::start_wifi("TP-LINK_84CDC2\0", "f36eebda48\0", 2);
	mqtt.start("mqtt://nhObg2PzQaQVckEJtj1fHEEhypTEWeH9lj8sbNPQMuzME2mVbb0HDsM1HvttxZqJ@mqtt.flespi.io");

	Conn::init();
}

void remap_chevrons() {
	for(int s=0; s<3; s++) {
		for(int c=0; c<3; c++) {
			int total_chevron = 3*s+c;
			int led_num = 14*(s+1) + 2*c;

			raw_leds.colors[led_num] = chevron_layer[total_chevron];
		}
	}
}

void remap_alert() {
	for(int s=0; s<3; s++) {
		for(int a=0; a<3; a++) {
			int total_alarm = 3*s + a;
			int led_pos = 14*(s+1) + 1 + 2*a;

			raw_leds.colors[led_pos] = alarm_layer[total_alarm];
		}
	}
}

void remap_kwhoosh() {
	for(int s=0; s<3; s++) {
		for(int k=0; k<4; k++) {
			int total_kwoosh = 4*s + k;
			int led_pos = 14*(s+1) + 10 + k;

			raw_leds.colors[led_pos] = kwhoosh_layer[total_kwoosh];
		}
	}
}

void remap_dials() {
	for(int s=0; s<3; s++) {
		for(int d=0; d<4; d++) {
			int partial_dial = 4*s + d;
			int led_pos = 14*(s+1) + 9 - d;

			Color &ref = raw_leds.colors[led_pos];
			ref.g = dial_layer[partial_dial*3].b;
			ref.r = dial_layer[partial_dial*3 + 1].b;
			ref.b = dial_layer[partial_dial*3 + 2].b;
		}
	}
}

void layer_remap_and_update() {
	remap_dials();
	remap_alert();
	remap_kwhoosh();
	remap_chevrons();

	raw_leds.update();
}

}
}
