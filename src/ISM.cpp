#include "ISM.h"

void ISM::SetupShoeBoxRoom(float length, float width, float height, Binaural::CCore &core) //FIXME: el paramwetro core debe desaparecer
{
	mainRoom.setupShoebox(length, width, height);
	originalSource.setup(core, Common::CVector3(0, 0, 0)); //FIXME: no debería ser necesario hacer setup de la fuente cuando no tenga el core
	originalSource.setLocation(Common::CVector3(1, 0, 0));
	originalSource.createImages(mainRoom,Common::CVector3(0,0,0),reflectionOrder);
}

void ISM::enableWall(int wallIndex)
{
	mainRoom.enableWall(wallIndex);
}

void ISM::disableWall(int wallIndex)
{
	mainRoom.disableWall(wallIndex);
}

void ISM::setReflectionOrder(int _reflectionOrder)
{
	reflectionOrder = _reflectionOrder;
	originalSource.refreshImages(mainRoom, Common::CVector3(0,0,0), reflectionOrder); //(0,0,0) is used instead of listener location. We should consider to change listener location by the center of the room
}

int ISM::getReflectionOrder()
{
	return reflectionOrder;
}

void ISM::setSourceLocation(Common::CVector3 location)
{
	originalSource.setLocation(location);

}

Common::CVector3 ISM::getSourceLocation()
{
	return originalSource.getLocation();
}


std::vector<Common::CVector3> ISM::getVirtualSourceLocations()
{
	std::vector<Common::CVector3> imageSourceList;
	originalSource.getImageLocations(imageSourceList, reflectionOrder);
	return imageSourceList;
}




