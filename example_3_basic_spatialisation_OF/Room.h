#pragma once
#include <vector>
#include "Wall.h"

class Room
{
public:
	void setup(float width, float length, float height);

private:
	std::vector<Wall> walls;
};

