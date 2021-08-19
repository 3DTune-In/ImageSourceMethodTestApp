/**
*
* \brief This is the header file of a reverberation renderer based in the Image Source Methot (ISM) using 3D Tune-In Toolkit
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

#include "ofMain.h"
#include <BinauralSpatializer/3DTI_BinauralSpatializer.h>
#include <HRTF/HRTFFactory.h>
#include <HRTF/HRTFCereal.h>
#include "SoundSource.h"
#include "Room.h"
#include "SourceImages.h"
#include <Common/Vector3.h>


class ofApp : public ofBaseApp{

	public:
		void setup();
		void update();
		void draw();

		void keyPressed(int key);
		void keyReleased(int key);
		void mouseMoved(int x, int y );
		void mouseDragged(int x, int y, int button);
		void mousePressed(int x, int y, int button);
		void mouseReleased(int x, int y, int button);
		void mouseEntered(int x, int y);
		void mouseExited(int x, int y);
		void windowResized(int w, int h);
		void dragEvent(ofDragInfo dragInfo);
		void gotMessage(ofMessage msg);
		
	private:	
		Room mainRoom;
		Wall wall_1, wall_2, wall_3, wall_4, floor, ceiling;
		float azimuth;		//Camera azimuth
		float elevation;	//Camera elevation

		Binaural::CCore							myCore;												 // Core interface
		shared_ptr<Binaural::CListener>			listener;											 // Pointer to listener interface

		std::vector<ofSoundDevice> deviceList;
		ofSoundStream systemSoundStream;

		SourceImages sourceImages;
		SoundSource source1Wav;
		shared_ptr<Binaural::CSingleSourceDSP>	source1DSP;							 // Pointers to each audio source interface

		int GetAudioDeviceIndex(std::vector<ofSoundDevice> list);
		void SetDeviceAndAudio(Common::TAudioStateStruct audioState);
		void audioOut(float * output, int bufferSize, int nChannels);
		void audioProcess(Common::CEarPair<CMonoBuffer<float>> & bufferOutput, int uiBufferSize);
		void LoadWavFile(SoundSource & source, const char* filePath);

		float scale = 100;			//visualization scale
		int reflectionOrder = 0;	//number of simulated reflections
};
