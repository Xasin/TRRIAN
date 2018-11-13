
#include "Layer.h"

namespace Peripheral {

Layer::Layer(const int length) :length(length) {
	colors = new Color[length];

	alpha = 255;
}
Layer::Layer(const Layer &source) : Layer(source.length) {
	for(int i=0; i<length; i++)
		colors[i] = source[i];

	alpha = source.alpha;
}

Color& Layer::operator[](int id) {
	id %= length;

	return colors[id];
}
Color Layer::operator[](int id) const {
	id %= length;

	return colors[id];
}
Layer& Layer::operator=(const Layer& source) {
	int cAmount = this->length;
	if(source.length < cAmount)
		cAmount = source.length;

	for(int i=0; i<cAmount; i++)
		this->colors[i] = source[i];

	return *this;
}

Layer& Layer::fill(Color fColor, int from, int to) {
	if(to == -1)
		to = length;

	if(from < 0)
		from = 0;
	if(to > length)
		to = length;

	if(from > to) {
		int temp = to;
		to = from;
		from = temp;
	}

	for(int i=from; i<to; i++)
		colors[i] = fColor;

	return *this;
}

Layer& Layer::merge_overlay(const Layer &top, int offset, bool wrap) {
	int from = offset;
	int to   = offset + top.length;

	if(!wrap) {
		if(from < 0)
			from = 0;
		if(to > length)
			to = length;
	}

	for(int i=from; i<to; i++) {
		(*this)[i+offset].merge_overlay(top[i], top.alpha);
	}

	return *this;
}
Layer& Layer::merge_multiply(const Layer &top, int offset, bool wrap) {
	int from = offset;
	int to   = offset + top.length;

	if(!wrap) {
		if(from < 0)
			from = 0;
		if(to > length)
			to = length;
	}

	for(int i=from; i<to; i++) {
		(*this)[i+offset].merge_multiply(top[i], top.alpha);
	}

	return *this;
}
Layer& Layer::merge_multiply(const uint8_t *scalars) {

	for(int i=0; i<length; i++) {
		(*this)[i].merge_multiply(scalars[i]);
	}

	return *this;
}
Layer& Layer::merge_add(const Layer &top, int offset, bool wrap) {
	int from = offset;
	int to   = offset + top.length;

	if(!wrap) {
		if(from < 0)
			from = 0;
		if(to > length)
			to = length;
	}

	for(int i=from; i<to; i++) {
		(*this)[i+offset].merge_add(top[i], top.alpha);
	}

	return *this;
}

}
