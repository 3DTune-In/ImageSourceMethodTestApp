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
#include "ISM/ISM.h"

# define LENGTH_OF_NORMALS 0.2


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
		ofTrueTypeFont textFont;
		float azimuth;		//Camera azimuth
		float elevation;	//Camera elevation
		float shoeboxLength;
		float shoeboxWidth;
		float shoeboxHeight;

		ISM::ISM ISMHandler;
		std::vector<bool> activeWalls = { true, true, true, true, true, true };
		ISM::Room mainRoom;
//		Wall wall_1, wall_2, wall_3, wall_4, floor, ceiling;//////////////////////////////////////To be moved into the ISM API

		Binaural::CCore							myCore;												 // Core interface
		shared_ptr<Binaural::CListener>			listener;											 // Pointer to listener interface

		std::vector<ofSoundDevice> deviceList;
		ofSoundStream systemSoundStream;

		SoundSource source1Wav;

		shared_ptr<Binaural::CSingleSourceDSP>	anechoicSourceDSP;							// Pointer to the original source DSP
		std::vector<shared_ptr<Binaural::CSingleSourceDSP>> imageSourceDSPList;			// Vector of pointers to all image source DSPs

		float scale = 20;			//visualization scale
		int reflectionOrder = 1;	//number of simulated reflections   //////////////////////////////////////To be moved into the ISM API

									
		/// Methods to handle Audio
		int GetAudioDeviceIndex(std::vector<ofSoundDevice> list);
		void SetDeviceAndAudio(Common::TAudioStateStruct audioState);
		void audioOut(float * output, int bufferSize, int nChannels);
		void audioProcess(Common::CEarPair<CMonoBuffer<float>> & bufferOutput, int uiBufferSize);
		void LoadWavFile(SoundSource & source, const char* filePath);

		/// Methods to render audio
		void processAnechoic(CMonoBuffer<float> &bufferInput, Common::CEarPair<CMonoBuffer<float>> & bufferOutput);
		void processImages(CMonoBuffer<float> &bufferInput, Common::CEarPair<CMonoBuffer<float>> & bufferOutput);

		/// Methods to draw rooms. 
		void drawRoom(ISM::Room room);
		void drawWall(ISM::Wall wall); //Draws the wall with lines between each pair of consecutive vertices.
		void drawWallNormal(ISM::Wall wall, float length = LENGTH_OF_NORMALS); //Draws a short line, normal to the wall and in the center of the wall towards inside the room.

		/// Methods to manage source images
		void moveSource(Common::CVector3 movement);
		void toggleWall(int wallIndex);
		std::vector<shared_ptr<Binaural::CSingleSourceDSP>> ofApp::createImageSourceDSP();
};
