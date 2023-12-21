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
#include <iomanip>
#include <cstring>
#include <iostream>
#include <algorithm>
#include <filesystem>


#include <BinauralSpatializer/3DTI_BinauralSpatializer.h>
#include <HRTF/HRTFFactory.h>
#include <HRTF/HRTFCereal.h>
#include <BRIR/BRIRFactory.h>
#include <BRIR/BRIRCereal.h>
#include "SoundSource.h"
#include "ISM/ISM.h"
#include "ofxGui\src\ofxGui.h"
#include "WavWriter.h"
#include "OscManager.hpp"
#include "ofxOsc.h"
#include "ofFileUtils.h"


#define SAMPLERATE 44100
#define BUFFERSIZE 512

#define LENGTH_OF_NORMALS 0.2
#define DEFAULT_SCALE 20
#define INITIAL_REFLECTION_ORDER 3
#define FRAME_RATE 60

#define OSC_DEFAULT_TARGET_IP "127.0.0.1"
#define OSC_DEFAULT_TARGET_PORT 12301
#define OSC_DEFAULT_LISTEN_PORT 12300


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
	    // Record to WAV
	    WavWriter wavWriter;
	    bool recordingOffline=false;
		bool boolRecordingIR = false;
	    float recordingPercent;
	    int offlineRecordIteration = 0;
	    int offlineRecordBuffers = 0;
		bool systemSoundStream_Started;
		mutex audioMutex;
	    float frameRate;
		/////////////////////////

		ofTrueTypeFont titleFont;
		ofImage logoUMA;
		ofImage logoSAVLab;
		ofImage logoSONICOM;

		ofxPanel leftPanel;
		ofxIntSlider zoom;
		ofParameter<int> reflectionOrderControl;
		ofParameter<bool> reverbEnableControl;
		ofParameter<bool> anechoicEnableControl;
		ofParameter<bool> binauralSpatialisationEnableControl;
		ofParameter<float> maxDistanceImageSourcesToListenerControl;
		ofParameter<float> reverbGainControl;
		ofParameter<int> winThresholdControl;
		ofParameter<int> windowSlopeControl;
		ofParameter<bool> recordOfflineIRControl;
		ofParameter<bool> recordOfflineIRScanControl;
		ofParameter<bool> recordOfflineWAVControl;
		ofParameter<int> numberOfSecondsToRecordControl;
		ofParameter<bool> changeAudioToPlayControl;
		ofParameter<bool> changeRoomGeometryControl;
		ofParameter<bool> changeHRTFControl;
		ofParameter<bool> changeBRIRControl;
		ofParameter<bool> playToStopControl;
		ofParameter<bool> stopToPlayControl;

		ofParameter<bool> helpDisplayControl;
		ofParameter<bool> aboutDisplayControl;

		std::vector<ofParameter<bool>> guiActiveWalls;

		std::vector<string> wallNames = { "Front", "2", "3", "4", "5",  "6", "7", "8", "9", "0" };
		
		

		float azimuth;		//Camera azimuth
		float elevation;	//Camera elevation
		float shoeboxLength;
		float shoeboxWidth;
		float shoeboxHeight;


		//ISM::ISM ISMHandler;
		shared_ptr<ISM::CISM> ISMHandler;
		
		ISM::Room mainRoom;		
		////////////////////
		ofXml xml;
		std::vector<Common::CVector3> corners;
		ofXml currentWall;
		std::vector<std::vector<int>> walls;		
		std::vector<std::vector<float>> absortionsWalls;
		/////////////////////

		Binaural::CCore							myCore;												 // Core interface
		shared_ptr<Binaural::CListener>			listener;											 // Pointer to listener interface
		shared_ptr<Binaural::CEnvironment>		environment;                                         // Pointer to environment interface
		bool bDisableReverb;                                                                         // true;
		int numberOfSilencedFrames = 0;
		int numberOfSilencedSamples = 0;
		int secondsToRecordIR = 1;
		int numberIRScan = 0;

		float windowSlopeWidth;  //millisec
		float reverbGainLinear;  //linear gain for reverb tail 

		std::vector<ofSoundDevice> deviceList;
		ofSoundStream systemSoundStream;
		
		SoundSource source1Wav;

		shared_ptr<Binaural::CSingleSourceDSP>	anechoicSourceDSP;							// Pointer to the original source DSP
		bool stateAnechoicProcess;                                                          // Enabled o Disabled
		bool stateBinauralSpatialisation;                                                   // Enabled o Disabled
		bool stateDistanceAttenuationAnechoic;                                             // Enabled o Disabled
		bool stateDistanceAttenuationReverb;                                                // Enabled o Disabled

		std::vector<shared_ptr<Binaural::CSingleSourceDSP>> imageSourceDSPList;			// Vector of pointers to all image source DSPs

		float scale = DEFAULT_SCALE;			//visualization scale
		bool boolToogleDisplayHelp;
		bool boolToogleDisplayAbout;
		bool playState;
		bool stopState;		
		bool profilling;	
		std::chrono::steady_clock::time_point startRecordingOfflineTime;
		std::chrono::steady_clock::time_point stopRecordingOfflineTime;

		bool setupDone;
		
		COscManager oscManager;					// OSC Manager
		bool changeFileFromOSC;                 // initial value: false
		char* charFilenameOSC;                  // file name with the geometry or BRIR of the room
		char* charFolderOSC= "workFolder";                    // working folder name
		string fullPathBRIR;


		/// Methods to handle Audio
		int GetAudioDeviceIndex(std::vector<ofSoundDevice> list);
		void SetDeviceAndAudio(Common::TAudioStateStruct audioState);
		void audioOut(float * output, int bufferSize, int nChannels);
		//void audioOut(ofSoundBuffer &outBuffer); //ofSoundBuffer

		void audioProcess(Common::CEarPair<CMonoBuffer<float>> & bufferOutput, int uiBufferSize);
		void LoadWavFile(SoundSource & source, const char* filePath);

		/// Methods to render audio
		void processAnechoic(CMonoBuffer<float> &bufferInput, Common::CEarPair<CMonoBuffer<float>> & bufferOutput);
		void processImages(CMonoBuffer<float> &bufferInput, Common::CEarPair<CMonoBuffer<float>> & bufferOutput);
		void processReverb(CMonoBuffer<float> &bufferInput, Common::CEarPair<CMonoBuffer<float>> & bufferOutput);

		/// Methods to draw rooms. 
		void drawRoom(ISM::Room room, int reflectionOrder, int transparency); //Draws recursively rooms
		void drawWall(ISM::Wall wall); //Draws the wall with lines between each pair of consecutive vertices.
		void drawWallNormal(ISM::Wall wall, float length = LENGTH_OF_NORMALS); //Draws a short line, normal to the wall and in the center of the wall towards inside the room.

		/// Methods to manage source images
		void moveSource(Common::CVector3 movement);
		std::vector<shared_ptr<Binaural::CSingleSourceDSP>> ofApp::createImageSourceDSP();
		std::vector<shared_ptr<Binaural::CSingleSourceDSP>> ofApp::reCreateImageSourceDSP();

		/// Methods to manage GUI
		void changeZoom(int &zoom);
		void changeReflectionOrder(int &reflectionOrder);
		void changeMaxDistanceImageSources(float &maxDistanceSourcesToListener);
		void changeWinThreshold(int& windowThreshold);
		void changeWindowSlope(int &windowSlope);
		void changeReverbGain(float &reverbGain);
		void toggleWall(bool &active);
		void refreshActiveWalls();
		void toggleAnechoic(bool& active);
		void toggleBinauralSpatialisation(bool& active);
		void toggleReverb(bool &active);
		void recordIrOffline(bool &active);
		void recordWavOffline(bool& active);
		void changeSecondsToRecordIR(int &secondsToRecordIR);
		void changeAudioToPlay(bool &active);
		void changeRoomGeometry(bool &active);
		void changeHRTF(bool& active);
		void changeBRIR(bool& active);
		void playToStop(bool &active);
		void stopToPlay(bool &active);
		
		void toogleHelpDisplay(bool &_active);
		void toogleAboutDisplay(bool& _active);

		void ShowRecordingDurationTime();

		/// Methods to manage XML
		std::vector<float> parserStToFloat(const std::string & st);
		std::vector<int> parserStToVectInt(const std::string & st);

		/// Record to WAV functions
		void StartWavRecord(string filename, int bitspersample);
		void EndWavRecord();
		int OfflineWavRecordStartLoop(unsigned long long durationInMilliseconds);
		void OfflineWavRecordOneLoopIteration(int _bufferSize);
		void OfflineWavRecordEndLoop();
		void ShowRecordingMessage();
		void StopWavRecord();

		//
		void StopSystemSoundStream();
		void StartSystemSoundStream();

		void resetAudio();

		// functions for conversion into samples
		int millisec2samples(float _millisec);
		float samples2millisec(float _samples);
		int meters2samples(float meters);
		float samples2meters(float _samples);
		float millisec2meters(float _millesec);
		float meters2millisec(float _meters);

		
		// OSC CallBack
		void OscCallback(const ofxOscMessage& message);		
		void OscCallBackPlay();
		void OscCallBackStop();
		void OscCallBackPlayAndRecord();
		void OscCallBackCoefficients(const ofxOscMessage& message);
		void OscCallBackAbsortions(const ofxOscMessage& message);
		void OscCallBackReverbGain(const ofxOscMessage& message);
		void OscCallBackDistMaxImgs(const ofxOscMessage& message);
		void OscCallBackWindowSlope(const ofxOscMessage& message);
		void OscCallBackReflectionOrder(const ofxOscMessage& message);
		void OscCallBackDirectPathEnable(const ofxOscMessage& message);
		void OscCallBackSpatialisationEnable(const ofxOscMessage& message);
		void OscCallBackReverbEnable(const ofxOscMessage& message);
		void OscCallBackDistanceAttenuationEnable(const ofxOscMessage& message);
		void OscCallBackDistanceAttenuationReverbEnable(const ofxOscMessage& message);
		void OscCallBackSaveIR();
		void OscCallBackChangeRoom(const ofxOscMessage& message);
		void OscCallBackChangeBRIR(const ofxOscMessage& message);
		void OscCallBackListenerLocation(const ofxOscMessage& message);
		void OscCallBackListenerOrientation(const ofxOscMessage& message);
		void OscCallBackSourceLocation(const ofxOscMessage& message);
		void OscCallBackChangeWorkFolder(const ofxOscMessage& message);
		
		void SendOSCMessageToMatlab_Ready();
};
