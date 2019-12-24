
#ifndef __ANIMATION_CHEVRONS__
#define __ANIMATION_CHEVRONS__

#include "../hw_def.h"

namespace SG {
namespace Animator {
namespace Chevrons {

extern Peripheral::Layer chevron_dials;
extern Peripheral::Layer chevrons;

bool dial_ready();
void dial_to(int tgt);

void lock_chevron(int tgt);

void init();
void deactivate();
void all_soft();

void tick();

}
}
}

#endif
