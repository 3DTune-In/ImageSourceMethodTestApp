#include "Room.h"

void Room::insertWall(Wall _newWall)
{
	walls.push_back(_newWall);
}

void Room::draw() 
{
	for (int i = 0; i < walls.size(); i++)
	{
		walls[i].draw();
		walls[i].drawNormal();
	}
}