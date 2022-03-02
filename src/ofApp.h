/**
*
* \brief This is the header file of a reverberation renderer based in the Image Source Methot (ISM) using 3D Tune-In Toolkit
* \date	July 2021
*
* \authors F. Arebola-P�rez and A. Reyes-Lecuona, members of the 3DI-DIANA Research Group (University of Malaga)
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
* \b Acknowledgement: This project has received funding from Spanish Ministerio de Ciencia e Innovaci�n under the SAVLab project (PID2019-107854GB-I00)
*
*/
#pragma once

#include "ofMain.h"
#include <iomanip>
#include <BinauralSpatializer/3DTI_BinauralSpatializer.h>
#include <HRTF/HRTFFactory.h>
#include <HRTF/HRTFCereal.h>
#include "SoundSource.h"
#include "ISM/ISM.h"
#include "ofxGui\src\ofxGui.h"


# define LENGTH_OF_NORMALS 0.2
# define DEFAULT_SCALE 20
# define INITIAL_REFLECTION_ORDER 2

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
		ofTrueTypeFont titleFont;
		ofImage logoUMA;
		ofImage logoSAVLab;

		ofxPanel leftPanel;
		ofxIntSlider zoom;
		ofParameter<int> reflectionOrderControl;
		std::vector<ofParameter<bool>> activeWalls;
		std::vector<string> wallNames = { "Front", "Left", "Right", "Back", "Floor", "Ceiling" };

		float azimuth;		//Camera azimuth
		float elevation;	//Camera elevation
		float shoeboxLength;
		float shoeboxWidth;
		float shoeboxHeight;

		ISM::ISM ISMHandler;
		ISM::Room mainRoom;

		Binaural::CCore							myCore;												 // Core interface
		shared_ptr<Binaural::CListener>			listener;											 // Pointer to listener interface

		std::vector<ofSoundDevice> deviceList;
		ofSoundStream systemSoundStream;

		SoundSource source1Wav;

		shared_ptr<Binaural::CSingleSourceDSP>	anechoicSourceDSP;							// Pointer to the original source DSP
		bool stateAnechoicProcess = true;                                                      //Enabled o Disabled

		std::vector<shared_ptr<Binaural::CSingleSourceDSP>> imageSourceDSPList;			// Vector of pointers to all image source DSPs

		float scale = DEFAULT_SCALE;			//visualization scale

									
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
		void drawRoom(ISM::Room room, int reflectionOrder, int transparency); //Draws recursively rooms
		void drawWall(ISM::Wall wall); //Draws the wall with lines between each pair of consecutive vertices.
		void drawWallNormal(ISM::Wall wall, float length = LENGTH_OF_NORMALS); //Draws a short line, normal to the wall and in the center of the wall towards inside the room.

		/// Methods to manage source images
		void moveSource(Common::CVector3 movement);
		std::vector<shared_ptr<Binaural::CSingleSourceDSP>> ofApp::createImageSourceDSP();

		/// Methods to manage GUI
		void changeZoom(int &zoom);
		void changeReflectionOrder(int &reflectionOrder);
		void toggleWall(bool &active);
		void refreshActiveWalls();
};
