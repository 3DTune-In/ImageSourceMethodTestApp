/**
* \class SourceImages
*
* \brief Declaration of SourceImages interface. This class recursively contains the source images implementing the Image Source Methot (ISM) using 3D Tune-In Toolkit
* \date	July 2021
*
* \authors F. Arebola-Pérez and A. Reyes-Lecuona, members of the 3DI-DIANA Research Group (University of Malaga)
* \b Contact: A. Reyes-Lecuona as head of 3DI-DIANA Research Group (University of Malaga): areyes@uma.es
*
* \b Contributions: (additional authors/contributors can be added here)
*
* \b Project: SAVLab (Spatial Audio Virtual Laboratory) ||
* \b Website:
*
* \b Copyright: University of Malaga - 2021
*
* \b Licence: GPLv3
*
* \b Acknowledgement: This project has received funding from Spanish Ministerio de Ciencia e Innovación under the SAVLab project (PID2019-107854GB-I00)
*
*/
#pragma once
#include "SoundSource.h"
#include "Room.h"
#include <BinauralSpatializer/3DTI_BinauralSpatializer.h>
#include <Common/Vector3.h>
class SourceImages
{
	public:
	////////////
	// Methods
	////////////

	/** \brief Initializes the object with one original source
	*	\details creates the original source at a given initial location keeping a link to the Toolkit core.
	*	\param [in] _Core: pointer to the 3DTI binaural core
	*   \param [in] _location: initial location for the original source.
	*/
	void setup(Binaural::CCore &_core, Common::CVector3 _location);

	/** \brief changes the location of the original source
	*	\details Sets a new location for the original source and updates all images accordingly.
	*   \param [in] _location: new location for the original source.
	*/
	void setLocation(Common::CVector3 _location);

	/** \brief Returns the location of the original source 
	*   \param [out] Location: Current location for the original source.
	*/
	Common::CVector3 getLocation();

	/** \brief Returns the 3DTI single source DSP of the original source
	*   \param [out] SingleSourceDSP: 3DTI single source DSP of the original source.
	*/
	shared_ptr<Binaural::CSingleSourceDSP> getSourceDSP();

	/** \brief Returns a vector with DTI single source DSP of the first reflection images sources.
	*   \param [out] SingleSourceDSPVector: vector of 3DTI single source DSP of image sources.
	*/
	std::vector<shared_ptr<Binaural::CSingleSourceDSP>> getImageSourceDSPs();

	int getNumberOfVisibleImages(int reflectionOrder, Common::CVector3 listenerLocation);

	void createImages(Room _room, int reflectionOrder);
	void updateImages();
	void drawSource();
	void drawImages(int reflectionOrder);
	void drawRaysToListener(Common::CVector3 _listenerLocation, int reflectionOrder);
	void drawFirstReflectionRays(Common::CVector3 _listenerLocation);


	void processAnechoic(CMonoBuffer<float> &bufferInput, Common::CEarPair<CMonoBuffer<float>> & bufferOutput);
	void processImages(CMonoBuffer<float> &bufferInput, Common::CEarPair<CMonoBuffer<float>> & bufferOutput, Common::CVector3 _listenerLocation, int _reflectionOrder);

private:
	std::vector<Wall> walls;										   //List of walls

	Common::CVector3 sourceLocation;								   //Original source location
	shared_ptr<Binaural::CSingleSourceDSP>	sourceDSP;				   // Pointer to the original source interface

//	std::vector<Common::CVector3> imageLocations;						//List of locations of source images
//	std::vector<shared_ptr<Binaural::CSingleSourceDSP>> sourceImageDSP;	//List of pointers to source image interfaces
	std::vector<SourceImages> images;									//recursive list of images

	Binaural::CCore *core;                                              //Core
	
};

