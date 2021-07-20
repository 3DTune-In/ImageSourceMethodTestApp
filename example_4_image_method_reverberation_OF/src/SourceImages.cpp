#include "SourceImages.h"

void SourceImages::setLocation(Common::CVector3 _location)
{
	sourceLocation = _location;
}

Common::CVector3 SourceImages::getLocation()
{
	return sourceLocation;
}

void SourceImages::drawSource()
{
	ofBox(sourceLocation.x, sourceLocation.y, sourceLocation.z, 0.05);

}
