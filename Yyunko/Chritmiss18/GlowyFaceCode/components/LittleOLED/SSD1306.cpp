/*
 * SSD1306.cpp
 *
 *  Created on: 29 Nov 2018
 *      Author: xasin
 */

#include "SSD1306.h"

namespace Peripheral {
namespace OLED {

SSD1306::SSD1306() : currentAction(nullptr) {
	start_i2c_set();

	send_cmd(SET_MUX_RATIO, 31);
	send_cmd(SET_DISPLAY_OFFSET, 0);
	send_cmd(0x40);
	send_cmd(0xA0, 0xA1);
	send_cmd(0xC0, 0xC8);
	send_cmd(SET_COM_PIN_MAP, 0x02);
	send_cmd(SET_CONTRAST, 0x7F);
	send_cmd(DISPLAY_RAM);
	send_cmd(DISPLAY_NORMAL);
	send_cmd(SET_CLK_DIV, 0x80);
	send_cmd(SET_CHARGE_PUMP, 0x14);
	send_cmd(DISPLAY_ON);
	send_cmd(0xA5);

	send_cmd(SET_MEMORY_ADDR_MODE, 0);
	char oData[] = {SET_COLUMN_RANGE, 0, 127, SET_PAGE_RANGE, 0, 7};
	currentAction->write(0x00, oData, 6);

	end_i2c_set();

	uint8_t *outData = new uint8_t[128];
	for(uint16_t i=0; i<128; i++)
		outData[i] = 0xFF;

	for(uint8_t i=0; i<8; i++) {
		start_i2c_set();
		currentAction->write(DATA_STREAM, outData, 128);
		end_i2c_set();
	}

	delete outData;
}

void SSD1306::start_i2c_set() {
	assert(currentAction == nullptr);

	currentAction = new XaI2C::MasterAction(0b0111100);
}

void SSD1306::send_cmd(uint8_t cmdByte) {
	assert(currentAction);

	currentAction->write(0x80, &cmdByte, 1);
}
void SSD1306::send_cmd(uint8_t cmdByte, uint8_t param) {
	assert(currentAction);

	char data[] = {cmdByte, param};
	currentAction->write(0x00, data, 2);
}

void SSD1306::end_i2c_set() {
	assert(currentAction);

	currentAction->execute();
	delete currentAction;
	currentAction = nullptr;
}

} /* namespace OLED */
} /* namespace Peripheral */
