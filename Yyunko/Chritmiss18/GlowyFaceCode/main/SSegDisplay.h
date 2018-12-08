/*
 * SSegDisplay.h
 *
 *  Created on: 7 Dec 2018
 *      Author: xasin
 */

#ifndef MAIN_SSEGDISPLAY_H_
#define MAIN_SSEGDISPLAY_H_

#include "DrawBox.h"

struct SegmentDetail {
	int oX;
	int oY;
	int r;
};

class SSegDisplay {
private:
	Peripheral::OLED::DrawBox &mainBox;

public:
	static void draw_element(Peripheral::OLED::DrawBox &box);

	SSegDisplay(Peripheral::OLED::DrawBox &mainBox);

	void draw_segments(uint8_t map, uint8_t pos);
	void draw_number(uint8_t no, uint8_t pos);
};

#endif /* MAIN_SSEGDISPLAY_H_ */
