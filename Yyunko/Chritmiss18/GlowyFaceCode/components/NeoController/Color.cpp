/*
 * Color.cpp
 *
 *  Created on: 19 Sep 2018
 *      Author: xasin
 */

#include "Color.h"

namespace Peripheral {

Color::Color() {
	r = 0;
	g = 0;
	b = 0;

	alpha = 255;
}
Color::Color(uint32_t cCode, uint8_t brightness) : Color() {
	set(cCode);
	bMod(brightness);
}

Color::ColorData Color::getLEDValue() const {
	ColorData out = {};
	out.r = ((uint16_t)r*r)>>8;
	out.g = ((uint16_t)g*g)>>8;
	out.b = ((uint16_t)b*b)>>8;

	return out;
}

void Color::set(Color color) {
	for(uint8_t i=0; i<4; i++) {
		*(&this->r + i) = *(&color.r + i);
	}
}
void Color::set(uint32_t cCode) {
	uint8_t *colorPart = (uint8_t *)&cCode;
	r = colorPart[2];
	g = colorPart[1];
	b = colorPart[0];
}
void Color::set(uint32_t cCode, uint8_t factor) {
	set(cCode);
	bMod(factor);
}
Color& Color::operator=(const Color& nColor) {
	this->set(nColor);

	return *this;
}

void Color::bMod(uint8_t factor) {
	uint16_t bFact = factor;
	r = ((r*bFact)>>8) + ((r*bFact & 0x80) != 0);
	g = ((g*bFact)>>8) + ((g*bFact & 0x80) != 0);
	b = ((b*bFact)>>8) + ((b*bFact & 0x80) != 0);
}

Color Color::overlay(Color topColor, uint8_t alpha) {
	/*Color oColor = Color();
	for(uint8_t i=0; i<3; i++)
		*(&(oColor.r) + i) = ((uint16_t)*(&this->r + i)*(255 - alpha) + *(&topColor.r +i)*(alpha)) >> 8;
	*/

	return (*this)*(255-alpha) + topColor*(alpha);
}
void Color::overlay(Color bottom, Color top, uint8_t alpha) {
	for(uint8_t i=0; i<3; i++)
		*(&(this->r) + i) = ((uint16_t)*(&bottom.r + i)*(255 - alpha) + *(&top.r +i)*(alpha)) >> 8;
}

Color Color::operator +(Color secondColor) {
	Color oColor = *this;
	for(uint8_t i=0; i<3; i++)
		*(&(oColor.r) + i) = *(&secondColor.r + i) + *(&this->r + i);

	return oColor;
}
Color Color::operator *(uint8_t brightness) {
	Color oColor = *this;
	oColor.bMod(brightness);

	return oColor;
}

Color& Color::merge_overlay(const Color &top, uint8_t alpha) {
	uint16_t total_alpha = (top.alpha * uint16_t(alpha))>>8;

	for(uint8_t i=0; i<4; i++)
		*(&this->r +i) = (*(&top.r +i)*total_alpha + *(&this->r +i)*(255-total_alpha))>>8;

	return *this;
}
Color& Color::merge_multiply(const Color &top, uint8_t alpha) {
	uint16_t total_alpha = (top.alpha * uint16_t(alpha)) >> 8;

	for(uint8_t i=0; i<3; i++)
		*(&r +i) = (*(&r +i) * (255-total_alpha + (total_alpha*(*(&top.r+i))>>8)))>>8;

	return *this;
}
Color& Color::merge_multiply(uint8_t scalar) {
	for(uint8_t i=0; i<3; i++)
		*(&r +i) = (*(&r +i)*uint16_t(scalar)) >> 8;

	return *this;
}
Color& Color::merge_add(const Color &top, uint8_t alpha) {
	uint16_t total_alpha = (top.alpha * uint16_t(alpha)) >> 8;

	for(uint8_t i=0; i<3; i++) {
		uint8_t& c = *(&r +i);
		uint16_t cB = c + *(&top.r +i);
		if(cB > 255)
			cB = 255;

		c = cB;
	}
	uint16_t alphaB = this->alpha + total_alpha;
	if(alphaB > 255)
		alphaB = 255;
	this->alpha = alphaB;

	return *this;
}

Color Color::calculate_overlay(const Color &top, uint8_t alpha) const {
	Color oColor = *this;

	return (oColor.merge_overlay(top, alpha));
}
Color Color::calculate_multiply(const Color &top, uint8_t alpha) const {
	Color oColor = *this;

	return (oColor.merge_multiply(top, alpha));
}
Color Color::calculate_multiply(uint8_t scalar) const {
	Color oColor = *this;

	return (oColor.merge_multiply(scalar));
}
Color Color::calculate_add(const Color &top, uint8_t alpha) const {
	Color oColor = *this;

	return (oColor.merge_add(top, alpha));
}

} /* namespace Peripheral */
