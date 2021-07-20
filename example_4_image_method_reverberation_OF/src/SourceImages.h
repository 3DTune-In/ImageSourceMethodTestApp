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
	void drawSource();
	void drawImages();

private:
	SoundSource source;
	Common::CVector3 sourceLocation;
	vector<Common::CVector3> imageLocations;
};

