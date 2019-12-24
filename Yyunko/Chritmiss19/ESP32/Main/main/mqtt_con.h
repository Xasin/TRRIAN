

#ifndef __GATE_MQTT_CON__
#define __GATE_MQTT_CON__

namespace SG {
namespace Conn {

extern bool authorized_dial;
extern bool clock_active;

void tick();
void init();

}
}

#endif
