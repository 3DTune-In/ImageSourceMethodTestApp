#include "Room.h"
#include "ofMain.h"


void Room::insertWall(Wall _newWall)
{
	walls.push_back(_newWall);
}

std::vector<Wall> Room::getWalls()
{
	return walls;
}

std::vector<Room> Room::getImageRooms()
{
	std::vector<Room> roomList;
	for (int i = 0; i < walls.size(); i++)
	{
		Room tempRoom;
		for (int j = 0; j < walls.size(); j++)
		{
			Wall tempWall = walls.at(i).getImageWall(walls.at(j));
			tempRoom.insertWall(tempWall);
		}
		roomList.push_back(tempRoom);
	}
	return roomList;
}

void Room::draw() 
{
	for (int i = 0; i < walls.size(); i++)
	{
		walls[i].draw();
		walls[i].drawNormal();
	}
}