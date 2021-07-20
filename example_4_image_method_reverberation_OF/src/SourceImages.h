#pragma once
#include "SoundSource.h"
#include "Room.h"
#include <Common/Vector3.h>
class SourceImages
{
public:
	void setLocation(Common::CVector3 _location);
	Common::CVector3 getLocation();
	void createImages(Room _room);
	void updateImages();
	void drawSource();
	void drawImages();

private:
	SoundSource source;
	std::vector<Wall> walls;
	Common::CVector3 sourceLocation;
	vector<Common::CVector3> imageLocations;
};

