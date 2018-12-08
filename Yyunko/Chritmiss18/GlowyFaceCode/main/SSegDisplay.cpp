/*
 * SSegDisplay.cpp
 *
 *  Created on: 7 Dec 2018
 *      Author: xasin
 */

#include "SSegDisplay.h"

using namespace Peripheral::OLED;

const SegmentDetail segments[] = {
		{oX: 3, oY: 0, r: 0},
		{oX: 5, oY: 2, r: 3},
		{oX: 5, oY: 15, r: 3},
		{oX: 3, oY: 26, r: 0},
		{oX: 18, oY: 15, r: 3},
		{oX: 18, oY: 2, r: 3},
		{oX: 3, oY: 13, r: 0}
};

const uint8_t numMap[] = {
		0b00111111,
		0b00110000,
		0b01101101,
		0b01111001,
		0b01110010,
		0b01011011,
		0b01011111,
		0b00110011,
		0b01111111,
		0b01111011
};

void SSegDisplay::draw_element(DrawBox &box) {
	for(uint8_t i=0; i<3; i++) {
		box.draw_line(2-i, i, 14-(2-i)*2, 0);
		box.draw_line(2-i, 4-i, 14-(2-i)*2, 0);
	}
}

SSegDisplay::SSegDisplay(DrawBox &mainBox) : mainBox(mainBox) {
}


void SSegDisplay::draw_segments(uint8_t map, uint8_t pos) {
	DrawBox tempBox = DrawBox(14, 5);
	tempBox.set_head(&mainBox, false);

	for(uint8_t i=0; i<7; i++) {
		if(((map>>i) & 1) == 0)
			continue;

		tempBox.offsetX  = segments[i].oX + pos*25;
		tempBox.offsetY  = segments[i].oY;
		tempBox.rotation = segments[i].r;

		draw_element(tempBox);
	}
}

void SSegDisplay::draw_number(uint8_t no, uint8_t pos) {
	if(no > 9)
		return;

	draw_segments(numMap[no], pos);
}
