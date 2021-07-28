#pragma once
#include "SoundSource.h"
#include "Room.h"
#include <BinauralSpatializer/3DTI_BinauralSpatializer.h>
#include <Common/Vector3.h>
class SourceImages
{
public:
	//void setup(Binaural::CCore &_core, Common::CVector3 _listenerLocation, Common::CVector3 _location);
	void setup(Binaural::CCore &_core, Common::CVector3 _location);
	shared_ptr<Binaural::CSingleSourceDSP> getSourceDSP();
	std::vector<shared_ptr<Binaural::CSingleSourceDSP>> getImageSourceDSPs();
	void setLocation(Common::CVector3 _location);
	Common::CVector3 getLocation();
	void createImages(Room _room, int reflectionOrder);
	void updateImages();
	void drawSource();
	void drawImages(int reflectionOrder);
	void drawRaysToListener(Common::CVector3 _listenerLocation);

	void processAnechoic(CMonoBuffer<float> &bufferInput, Common::CEarPair<CMonoBuffer<float>> & bufferOutput);
	void processImages(CMonoBuffer<float> &bufferInput, Common::CEarPair<CMonoBuffer<float>> & bufferOutput, Common::CVector3 _listenerLocation);

private:
	std::vector<Wall> walls;										   //List of walls

	Common::CVector3 sourceLocation;								   //Original source location
	shared_ptr<Binaural::CSingleSourceDSP>	sourceDSP;				   // Pointer to the original source interface

//	std::vector<Common::CVector3> imageLocations;						//List of locations of source images
//	std::vector<shared_ptr<Binaural::CSingleSourceDSP>> sourceImageDSP;	//List of pointers to source image interfaces
	std::vector<SourceImages> images;									//recursive list of images

	Binaural::CCore *core;                                              //Core
	
};

