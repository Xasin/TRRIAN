/*
 * SSD1306.h
 *
 *  Created on: 29 Nov 2018
 *      Author: xasin
 */

#ifndef COMPONENTS_LITTLEOLED_SSD1306_H_
#define COMPONENTS_LITTLEOLED_SSD1306_H_

namespace Peripheral {
namespace OLED {

#include "MasterAction.h"

class SSD1306 {
private:

	void send_cmd(uint8_t cmdVal);
	void send_cmd(uint8_t cmdVal, uint8_t extraByte);

public:
	SSD1306();
};

} /* namespace OLED */
} /* namespace Peripheral */

#endif /* COMPONENTS_LITTLEOLED_SSD1306_H_ */
