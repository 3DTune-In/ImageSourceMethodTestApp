#include "ISM.h"

void ISM::SetupShoeBoxRoom(float length, float width, float height, Binaural::CCore &core) //FIXME: el paramwetro core debe desaparecer
{
	mainRoom.setupShoebox(length, width, height);
	originalSource.setup(core, Common::CVector3(0, 0, 0)); //FIXME: no deber�a ser necesario hacer setup de la fuente cuando no tenga el core
	originalSource.setLocation(Common::CVector3(1, 0, 0));
	originalSource.createImages(mainRoom,Common::CVector3(0,0,0),reflectionOrder); //FIXME:the listener location is fake
}

void ISM::enableWall(int wallIndex)
{
	mainRoom.enableWall(wallIndex);
	originalSource.refreshImages(mainRoom, Common::CVector3(0, 0, 0), reflectionOrder); //FIXME:the listener location is fake
}

void ISM::disableWall(int wallIndex)
{
	mainRoom.disableWall(wallIndex);
	originalSource.refreshImages(mainRoom, Common::CVector3(0, 0, 0), reflectionOrder); //FIXME:the listener location is fake
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


std::vector<Common::CVector3> ISM::getImageSourceLocations()
{
	std::vector<Common::CVector3> imageSourceList;
	originalSource.getImageLocations(imageSourceList, reflectionOrder);
	return imageSourceList;
}


std::vector<ImageSourceData> ISM::getImageSourceData(Common::CVector3 listenerLocation)
{
	std::vector<ImageSourceData> imageSourceList;
	originalSource.getImageData(imageSourceList, listenerLocation, reflectionOrder);
	return imageSourceList;
}




