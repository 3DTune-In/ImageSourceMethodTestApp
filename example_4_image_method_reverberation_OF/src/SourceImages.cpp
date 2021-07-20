#include "SourceImages.h"

void SourceImages::setLocation(Common::CVector3 _location)
{
	sourceLocation = _location;
	updateImages();
}

Common::CVector3 SourceImages::getLocation()
{
	return sourceLocation;
}

void SourceImages::createImages(Room _room)
{
	walls = _room.getWalls();
	for (int i = 0; i < walls.size(); i++)
	{
		Common::CVector3 tempImageLocation = walls[i].getImagePoint(sourceLocation);
		imageLocations.push_back(tempImageLocation);
	}
}

void SourceImages::updateImages()
{
	for (int i = 0; i < walls.size(); i++)
	{
		//FIXME: When some images disappear or reappear, this has to be done differently
		imageLocations[i] = walls[i].getImagePoint(sourceLocation);
	}
}

void SourceImages::drawSource()
{
	ofBox(sourceLocation.x, sourceLocation.y, sourceLocation.z, 0.05);

}

void SourceImages::drawImages()
{
	for (int i = 0; i < imageLocations.size(); i++)
	{
		ofBox(imageLocations[i].x, imageLocations[i].y, imageLocations[i].z, 0.05);
	}
}