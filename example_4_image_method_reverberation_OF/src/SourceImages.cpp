#include "SourceImages.h"

void SourceImages::setup(Binaural::CCore &_core, Common::CVector3 _location)
{
	core = &_core;
	sourceLocation = _location;
	sourceDSP = _core.CreateSingleSourceDSP();						// Creating audio source
	Common::CTransform sourcePosition;
	sourcePosition.SetPosition(_location);											 
	sourceDSP->SetSourceTransform(sourcePosition);					//Set source position
	sourceDSP->SetSpatializationMode(Binaural::TSpatializationMode::HighQuality);	// Choosing high quality mode for anechoic processing
	sourceDSP->DisableNearFieldEffect();											// Audio source will not be close to listener, so we don't need near field effect
	sourceDSP->EnableAnechoicProcess();											// Enable anechoic processing for this source
	sourceDSP->EnableDistanceAttenuationAnechoic();								// Do not perform distance simulation
	sourceDSP->EnablePropagationDelay();
}

shared_ptr<Binaural::CSingleSourceDSP> SourceImages::getSourceDSP()
{
	return sourceDSP;
}

std::vector<shared_ptr<Binaural::CSingleSourceDSP>> SourceImages::getImageSourceDSPs()
{
	return sourceImageDSP;
}

void SourceImages::setLocation(Common::CVector3 _location)
{
	sourceLocation = _location;
	Common::CTransform sourcePosition;
	sourcePosition.SetPosition(_location);									 
	sourceDSP->SetSourceTransform(sourcePosition);					//Set source position
	updateImages();
}

Common::CVector3 SourceImages::getLocation()
{
	return sourceLocation;
}

void SourceImages::createImages(Room _room, int reflectionOrder)
{
	walls = _room.getWalls();
	for (int i = 0; i < walls.size(); i++)
	{
		SourceImages tempSourceImage;

		Common::CVector3 tempImageLocation = walls[i].getImagePoint(sourceLocation);
//		imageLocations.push_back(tempImageLocation);   //REMOVE this will be inside the recursive sourceImages

		shared_ptr<Binaural::CSingleSourceDSP> tempsourceImageDSP;
		
		tempsourceImageDSP = core->CreateSingleSourceDSP();						               // Creating image audio source
		Common::CTransform sourceImagePosition;
		sourceImagePosition.SetPosition(tempImageLocation);
		tempsourceImageDSP->SetSourceTransform(sourceImagePosition);
		tempsourceImageDSP->SetSpatializationMode(Binaural::TSpatializationMode::HighQuality);	// Choosing high quality mode for anechoic processing
		tempsourceImageDSP->DisableNearFieldEffect();											// Audio source will not be close to listener, so we don't need near field effect
		tempsourceImageDSP->EnableAnechoicProcess();											// Enable anechoic processing for this source
		tempsourceImageDSP->EnableDistanceAttenuationAnechoic();								// Do not perform distance simulation
		tempsourceImageDSP->EnablePropagationDelay();

		sourceImageDSP.push_back(tempsourceImageDSP);   //REMOVE this will be inside the recursive sourceImages

		tempSourceImage.setup(*core, tempImageLocation);

		images.push_back(tempSourceImage);

	}
}

void SourceImages::updateImages()
{
	for (int i = 0; i < walls.size(); i++)
	{
		//FIXME: When some images disappear or reappear, this has to be done differently
		images[i].setLocation(walls[i].getImagePoint(sourceLocation));
		// Moves Images
		Common::CTransform sourceImagePosition;
		sourceImagePosition.SetPosition(images[i].getLocation());
		sourceImageDSP.at(i)->SetSourceTransform(sourceImagePosition);

	}
}

void SourceImages::drawSource()
{
	ofBox(sourceLocation.x, sourceLocation.y, sourceLocation.z, 0.05);

}

void SourceImages::drawImages()
{
	for (int i = 0; i < images.size(); i++)
	{
		ofBox(images[i].getLocation().x, images[i].getLocation().y, images[i].getLocation().z, 0.05);
	}
}

void SourceImages::	drawRaysToListener(Common::CVector3 _listenerLocation)
{
	for (int i = 0; i < images.size(); i++)
	{
		Common::CVector3 reflectionPoint = walls[i].getIntersectionPointWithLine(images[i].getLocation(), _listenerLocation);
		if (walls[i].checkPointInsideWall(reflectionPoint))
		{
			ofBox(reflectionPoint.x, reflectionPoint.y, reflectionPoint.z, 0.05);
			ofLine(sourceLocation.x, sourceLocation.y, sourceLocation.z, reflectionPoint.x, reflectionPoint.y, reflectionPoint.z);
			ofLine(reflectionPoint.x, reflectionPoint.y, reflectionPoint.z, _listenerLocation.x, _listenerLocation.y, _listenerLocation.z);
		}
	}
}

void SourceImages::processAnechoic(CMonoBuffer<float> &bufferInput, Common::CEarPair<CMonoBuffer<float>> & bufferOutput)
{
		Common::CEarPair<CMonoBuffer<float>> bufferProcessed;

		sourceDSP->SetBuffer(bufferInput);
		sourceDSP->ProcessAnechoic(bufferProcessed.left, bufferProcessed.right);

		bufferOutput.left += bufferProcessed.left;
		bufferOutput.right += bufferProcessed.right;
}

void SourceImages::processImages(CMonoBuffer<float> &bufferInput, Common::CEarPair<CMonoBuffer<float>> & bufferOutput, Common::CVector3 _listenerLocation)
{
	for (int i = 0; i < walls.size(); i++)
	{
		Common::CVector3 reflectionPoint = walls.at(i).getIntersectionPointWithLine(images[i].getLocation(), _listenerLocation);
		if (walls[i].checkPointInsideWall(reflectionPoint))
		{
		    Common::CEarPair<CMonoBuffer<float>> bufferProcessed;

			sourceImageDSP.at(i)->SetBuffer(bufferInput);
			sourceImageDSP.at(i)->ProcessAnechoic(bufferProcessed.left, bufferProcessed.right);

			bufferOutput.left += bufferProcessed.left;
			bufferOutput.right += bufferProcessed.right;
		}

	}
}
