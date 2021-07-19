#include "SourceImages.h"

void SourceImages::setLocation(Common::CVector3 _location)
{
	sourceLocation = _location;
}

void SourceImages::drawSource()
{
	ofBox(sourceLocation.x, sourceLocation.y, sourceLocation.z, 0.05);

}
