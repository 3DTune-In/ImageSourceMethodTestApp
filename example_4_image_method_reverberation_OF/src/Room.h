#pragma once
#include <vector>
#include "Wall.h"

class Room
{
public:
	void setup(float width, float length, float height);
	void insertWall(Wall newWall);
	void draw();

private:
	std::vector<Wall> walls;
};

