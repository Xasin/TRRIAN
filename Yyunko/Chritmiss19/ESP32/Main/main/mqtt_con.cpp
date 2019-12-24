
#include "hw_def.h"
#include "xasin/mqtt/Subscription.h"

#include "animation/gate_handling.h"

#include <cstring>

namespace SG {
namespace Conn {

bool authorized_dial = false;
bool clock_active = true;

void init() {
	HW::mqtt.subscribe_to("StarGate/Yyunko/#", [](Xasin::MQTT::MQTT_Packet data){
		if(data.topic == "SetTarget") {
			SG::Animator::Gate::chevron_count = atoi(data.data.data());
		}
		else if(data.topic == "Authorized")
			authorized_dial = (data.data == "Y");
		else if(data.topic == "ClockActive")
			clock_active = (data.data == "Y");
	});
}

int last_chev_pushed = 0;
int last_target_pushed = 0;

Peripheral::Color state_color = Peripheral::Color(0, 0, 0);
Peripheral::Color state_color_current = state_color;

void tick() {
	if(last_chev_pushed != Animator::Gate::chevron_current_locked) {
		last_chev_pushed = Animator::Gate::chevron_current_locked;

		char oPtr[10] = {};
		sprintf(oPtr, "%d", last_chev_pushed);
		HW::mqtt.publish_to("StarGate/Yyunko/CurrentLock", oPtr, strlen(oPtr), true);
	}

	if(last_target_pushed != Animator::Gate::chevron_count) {
		last_target_pushed = Animator::Gate::chevron_count;

		char oPtr[10] = {};
		sprintf(oPtr, "%d", last_target_pushed);
		HW::mqtt.publish_to("StarGate/Yyunko/CurrentTarget", oPtr, strlen(oPtr), true);
	}



	state_color = Peripheral::Color(Material::BLUE, 80);
	if(Animator::Gate::gate_active())
		state_color = Peripheral::Color(0, 0, 0);

	if(HW::mqtt.is_disconnected() == 1)
		state_color = Peripheral::Color(Material::AMBER);
	else if(HW::mqtt.is_disconnected() == 2)
		state_color = Peripheral::Color(Material::RED);

	state_color_current.merge_transition(state_color, 3000);

	HW::chevron_layer[0].merge_overlay(state_color_current);
}

}
}
