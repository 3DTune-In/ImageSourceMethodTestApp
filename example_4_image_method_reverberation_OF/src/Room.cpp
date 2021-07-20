#include "Room.h"

void Room::insertWall(Wall _newWall)
{
	walls.push_back(_newWall);
}

std::vector<Wall> Room::getWalls()
{
	return walls;
}

void Room::draw() 
{
	for (int i = 0; i < walls.size(); i++)
	{
		walls[i].draw();
		walls[i].drawNormal();
	}
}