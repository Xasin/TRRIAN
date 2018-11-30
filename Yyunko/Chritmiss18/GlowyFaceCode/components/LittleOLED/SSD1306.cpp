/*
 * SSD1306.cpp
 *
 *  Created on: 29 Nov 2018
 *      Author: xasin
 */

#include "SSD1306.h"

namespace Peripheral {
namespace OLED {

#include "font-5x8.c"

SSD1306::SSD1306() :
		currentAction(nullptr), cmdBuffer(),
		screenBuffer() {
	start_cmd_set();

	send_cmd(SET_MUX_RATIO, 31);
	send_cmd(SET_DISPLAY_OFFSET, 0);
	send_cmd(0x40);
	send_cmd(0xA0);
	send_cmd(0xC0);
	send_cmd(SET_COM_PIN_MAP, 0x02);
	send_cmd(SET_CONTRAST, 0x7F);
	send_cmd(DISPLAY_RAM);
	send_cmd(DISPLAY_NONINV);
	send_cmd(SET_CLK_DIV, 0x80);
	send_cmd(SET_CHARGE_PUMP, 0x14);
	send_cmd(DISPLAY_ON);
	send_cmd(DISPLAY_RAM);

	send_cmd(SET_MEMORY_ADDR_MODE, 0);

	end_cmd_set();

	set_pixel(64, 16);

	write_string("Helu Wuff", 0, 0);
	write_string("UwU.exe started", 10, 10, true);

	push_entire_screen();
}

void SSD1306::start_cmd_set() {
	assert(currentAction == nullptr);
	currentAction = new XaI2C::MasterAction(0b0111100);
}

void SSD1306::send_cmd(uint8_t cmdByte) {
	assert(currentAction);

	cmdBuffer.push_back(cmdByte);
}
void SSD1306::send_cmd(uint8_t cmdByte, uint8_t param) {
	assert(currentAction);

	cmdBuffer.push_back(cmdByte);
	cmdBuffer.push_back(param);
}

void SSD1306::end_cmd_set() {
	assert(currentAction);

	currentAction->write(0x00, cmdBuffer.data(), cmdBuffer.size());

	currentAction->execute();

	cmdBuffer.clear();
	delete currentAction;
	currentAction = nullptr;
}

void SSD1306::data_write(void *data, size_t length) {
	printf("Pushing %d bytes to SSD1306!\n", length);

	assert(currentAction == nullptr);

	currentAction = new XaI2C::MasterAction(0b0111100);

	currentAction->write(DATA_STREAM, data, length);
	currentAction->execute();
	delete currentAction;
	currentAction = nullptr;
}

void SSD1306::set_coordinates(uint8_t column, uint8_t page, uint8_t maxColumn, uint8_t maxPage) {
	start_cmd_set();

	const char oData[] = {SET_COLUMN_RANGE, column, maxColumn, SET_PAGE_RANGE, page, maxPage};
	for(uint8_t i=0; i<6; i++)
		cmdBuffer.push_back(oData[i]);

	end_cmd_set();
}

void SSD1306::push_entire_screen() {
	set_coordinates();

	for(uint8_t page = 0; page < screenBuffer.size(); page++) {
		data_write(screenBuffer[page].begin(), screenBuffer[page].size());
	}
}

void SSD1306::set_pixel(uint8_t x, uint8_t y, bool on) {
	if(x >= 128)
		return;
	if(y >= 32)
		return;

	uint8_t page   = y / 8;
	uint8_t page_y = y%8;

	uint8_t &dByte = *(screenBuffer[page].begin() + x);

	if(on)
		dByte |= 1<<page_y;
	else
		dByte &= ~(1<<page_y);
}

void SSD1306::write_char(char c, uint8_t x, uint8_t y, bool invert) {
	const char *fontChar = console_font_5x8 + 8*c;

	for(uint8_t dy=0; dy<8; dy++) {
		for(uint8_t dx=0; dx<5; dx++)
			set_pixel(x+dx, y+dy, ((fontChar[dy]>>(7-dx)) & 1) != invert);
	}
}
void SSD1306::write_string(std::string outString, uint8_t x, uint8_t y, bool invert) {
	for(uint8_t dc = 0; dc<outString.size(); dc++)
		write_char(outString[dc], x + 5*dc, y, invert);
}

} /* namespace OLED */
} /* namespace Peripheral */
