#include "Room.h"
#include "ofMain.h"

void Room::setup(float width, float length, float height)
{
	Wall front,back,left,right,ceiling,floor;
	front.insertCorner(length / 2, width / 2, height / 2);
	front.insertCorner(length / 2, width / 2, -height / 2);
	front.insertCorner(length / 2, -width / 2, -height / 2);
	front.insertCorner(length / 2, -width / 2, height / 2);
	insertWall(front);
	left.insertCorner(-length / 2, width / 2, height / 2);
	left.insertCorner(-length / 2, width / 2, -height / 2);
	left.insertCorner(length / 2, width / 2, -height / 2);
	left.insertCorner(length / 2, width / 2, height / 2);
	insertWall(left);
	right.insertCorner(length / 2, -width / 2, height / 2);
	right.insertCorner(length / 2, -width / 2, -height / 2);
	right.insertCorner(-length / 2, -width / 2, -height / 2);
	right.insertCorner(-length / 2, -width / 2, height / 2);
	insertWall(right);
	back.insertCorner(-length / 2, -width / 2, height / 2);
	back.insertCorner(-length / 2, -width / 2, -height / 2);
	back.insertCorner(-length / 2, width / 2, -height / 2);
	back.insertCorner(-length / 2, width / 2, height / 2);
	insertWall(back);


}

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