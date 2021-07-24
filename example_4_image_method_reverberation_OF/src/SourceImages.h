#pragma once
#include "SoundSource.h"
#include "Room.h"
#include <BinauralSpatializer/3DTI_BinauralSpatializer.h>
#include <Common/Vector3.h>
class SourceImages
{
public:
	void setup(Binaural::CCore &_core, Common::CVector3 _location);
	shared_ptr<Binaural::CSingleSourceDSP> getSourceDSP();
	vector<shared_ptr<Binaural::CSingleSourceDSP>> getImageSourceDSPs();
	void setLocation(Common::CVector3 _location);
	Common::CVector3 getLocation();
	void createImages(Room _room);
	void updateImages();
	void drawSource();
	void drawImages();

private:
	std::vector<Wall> walls;										//List of walls
	Common::CVector3 sourceLocation;								//Original source location
	shared_ptr<Binaural::CSingleSourceDSP>	sourceDSP;				// Pointer to the original source interface
	vector<Common::CVector3> imageLocations;						//List of locations of source images
	vector<shared_ptr<Binaural::CSingleSourceDSP>> sourceImageDSP;	//List of pointers to source image interfaces
};
