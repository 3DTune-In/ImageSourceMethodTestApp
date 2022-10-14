#include "ofApp.h"

//#define SAMPLERATE 44100
#define BUFFERSIZE 512
// TEST PROFILER CLASS
#define USE_PROFILER
#ifdef USE_PROFILER
#include <Windows.h>
#include "Common/Profiler.h"
//CProfilerDataSet dsAudioLoop;
Common::CProfilerDataSet dsProcessFrameTime;
//Common::CProfilerDataSet dsProcessReverb;
Common::CTimeMeasure startOfflineRecord;
#endif


#define SOURCE_STEP 0.02f
#define LISTENER_STEP 0.01f
#define MAX_REFLECTION_ORDER 8
#define MAX_DIST_SILENCED_FRAMES 1000
#define MIN_DIST_SILENCED_FRAMES 2
#define MAX_SECONDS_TO_RECORD 30


//--------------------------------------------------------------
void ofApp::setup() {
	
	setupDone = false;
	
	// SETUP PROFILER
#ifdef USE_PROFILER
	Common::PROFILER3DTI.InitProfiler();
	Common::PROFILER3DTI.SetAutomaticWrite(dsProcessFrameTime, "PROF_APP_ProcessAllSourcesTIME.txt");
	Common::PROFILER3DTI.StartRelativeSampling(dsProcessFrameTime);
	//PROFILER3DTI.SetAutomaticWrite(dsProcessReverb, "PROF_APP_PROCESSREVERB.txt");
	//PROFILER3DTI.StartRelativeSampling(dsProcessReverb);
#endif

	// Core setup
	Common::TAudioStateStruct audioState;	                            // Audio State struct declaration
	//audioState.bufferSize = myCore.GetAudioState().bufferSize;		// Setting buffer size 
	audioState.bufferSize = BUFFERSIZE;			                        // Setting buffer size 
	audioState.sampleRate = myCore.GetAudioState().sampleRate;   		// Setting frame rate 
	myCore.SetAudioState(audioState);									// Applying configuration to core
	myCore.SetHRTFResamplingStep(15);								    // Setting 15-degree resampling step for HRTF

	// Listener setup
	listener = myCore.CreateListener();								 // First step is creating listener
	Common::CVector3 listenerLocation(0, 0, 0);
	Common::CTransform listenerPosition = Common::CTransform();		 // Setting listener in (0,0,0)
	listenerPosition.SetPosition(listenerLocation);
	listener->SetListenerTransform(listenerPosition);
	listener->DisableCustomizedITD();								 // Disabling custom head radius
	// HRTF can be loaded in SOFA (more info in https://sofacoustics.org/) Some examples of HRTF files can be found in 3dti_AudioToolkit/resources/HRTF
	string pathData = ofToDataPath("");
	string pathResources = ofToDataPath("resources");
	string fullPath = pathResources + "\\" + "hrtf.sofa";  //"hrtf.sofa"= pathFile;
	//string fullPath = pathResources + "\\" + "UMA_NULL_S_HRIR_512.sofa";  // To test the Filterbank
	bool specifiedDelays;
	bool sofaLoadResult = HRTF::CreateFromSofa(fullPath, listener, specifiedDelays);
	//bool sofaLoadResult = HRTF::CreateFromSofa("hrtf.sofa", listener, specifiedDelays);                 //VSTUDIO
	//bool sofaLoadResult = HRTF::CreateFromSofa("UMA_NULL_S_HRIR_512.sofa", listener, specifiedDelays);  //VSTUDIO
	if (!sofaLoadResult) {
		cout << "ERROR: Error trying to load the SOFA file" << endl << endl;
	}

	/************************/
	// Environment setup
	environment = myCore.CreateEnvironment();									// Creating environment to have reverberated sound
	environment->SetReverberationOrder(TReverberationOrder::ADIMENSIONAL);		// Setting number of ambisonic channels to use in reverberation processing
	fullPath = pathResources + "\\" + "brir.sofa";  //"hrtf.sofa"= pathFile;
	BRIR::CreateFromSofa(fullPath, environment);								// Loading SOFAcoustics BRIR file and applying it to the environment
	//BRIR::CreateFromSofa("brir.sofa", environment);							// Loading SOFAcoustics BRIR file and applying it to the environment
	
	//environment->SetNumberOfSilencedFrames(9);
	
	// Room setup
	ISM::RoomGeometry trapezoidal;

	/////////////Read the XML file with the geometry of the room and absorption of the walls////////
	/*
	string pathData = ofToDataPath("", true); 
	string fileName = pathData + "\\trapezoidal_3.xml";
	if (!xml.load(pathData+"\\trapezoidal_3.xml"))
	{
		ofLogError() << "Couldn't load file";
	}
	*/

	//"trapezoidal_3.xml"  "theater_room.xml";
	fullPath = pathResources + "\\" + "trapezoidal_1.xml";
	if (!xml.load(fullPath))
	{
		ofLogError() << "Couldn't load file";
	}

	// select all corners and iterate through them
	auto cornersXml = xml.find("//ROOMGEOMETRY/CORNERS");
	for (auto & currentCorner : cornersXml) {
		// for each corner in the room insert its coordinates
		auto cornersInFile = currentCorner.getChildren("CORNER");

		for (auto aux : cornersInFile) {
			std::string p3Dstr = aux.getAttribute("_3Dpoint").getValue();
			std::vector<float> p3Dfloat = parserStToFloat(p3Dstr);
			Common::CVector3 tempP3d;
			tempP3d.x = p3Dfloat[0];
			tempP3d.y = p3Dfloat[1];
			tempP3d.z = p3Dfloat[2];
			trapezoidal.corners.push_back(tempP3d);
		}		
	}
	// select all walls and iterate through them
	auto wallsXml = xml.find("//ROOMGEOMETRY/WALLS");	
	for (auto & currentWall : wallsXml) {
		// for each wall in the room insert corners its and absortions
		auto wallsInFile = currentWall.getChildren("WALL");
		for (auto aux : wallsInFile) {
			std::string strVectInt = aux.getAttribute("corner").getValue();
			std::vector<int> tempCornersWall  = parserStToVectInt(strVectInt);
			trapezoidal.walls.push_back(tempCornersWall);

			std::string strVectFloat = aux.getAttribute("absor").getValue();
			std::vector<float> tempAbsorsWall = parserStToFloat(strVectFloat);
			absortionsWalls.push_back(tempAbsorsWall);
		}
	}
			
	ISMHandler = std::make_shared<ISM::CISM>(&myCore);		// Initialize ISM		
	ISMHandler->setupArbitraryRoom(trapezoidal);
	shoeboxLength = 7.5; shoeboxWidth = 3; shoeboxHeight = 3;
	//ISMHandler->SetupShoeBoxRoom(shoeboxLength, shoeboxWidth, shoeboxHeight);
	
	//Absortion as vector
	ISMHandler->setAbsortion( (std::vector<std::vector<float>>)  absortionsWalls);

	ISMHandler->setReflectionOrder(INITIAL_REFLECTION_ORDER);

	mainRoom = ISMHandler->getRoom();

	// setup of the anechoic source
	//Common::CVector3 initialLocation(13, 0, -4);
	Common::CVector3 initialLocation(1, 0, 0);
	ISMHandler->setSourceLocation(initialLocation);					// Source to be rendered
	anechoicSourceDSP = myCore.CreateSingleSourceDSP();				// Creating audio source
	Common::CTransform sourcePosition;
	sourcePosition.SetPosition(initialLocation);
	anechoicSourceDSP->SetSourceTransform(sourcePosition);							//Set source position
	anechoicSourceDSP->SetSpatializationMode(Binaural::TSpatializationMode::HighQuality);	// Choosing high quality mode for anechoic processing
	anechoicSourceDSP->DisableNearFieldEffect();											// Audio source will not be close to listener, so we don't need near field effect
	anechoicSourceDSP->EnableAnechoicProcess();										// Enable anechoic processing for this source
	//anechoicSourceDSP->DisableAnechoicProcess();										// Disable anechoic processing for this source
	//stateAnechoicProcess = true;                  //Is set to true in the method in toggleAnechoic             
	anechoicSourceDSP->EnableDistanceAttenuationAnechoic();								// Do not perform distance simulation
	anechoicSourceDSP->EnableDistanceAttenuationReverb();
	anechoicSourceDSP->EnablePropagationDelay();
	
	// setup of the image sources
	imageSourceDSPList = createImageSourceDSP();

	// setup maxDistanceSourcesToListener and numberOfSilencedFrames
	float maxDistanceSourcesToListener = INITIAL_DIST_SILENCED_FRAMES;
	ISMHandler->setMaxDistanceImageSources(maxDistanceSourcesToListener);
	numberOfSilencedFrames = ISMHandler->calculateNumOfSilencedFrames(maxDistanceSourcesToListener);
	//if (numberOfSilencedFrames > 25) numberOfSilencedFrames = 25;
	
	fullPath = pathResources + "\\" + "speech_female.wav";
	const char* _filePath = fullPath.c_str();
	LoadWavFile(source1Wav, _filePath);
	//LoadWavFile(source1Wav, "impulse16bits44100hz_b.wav");                            // Loading .wav file
	//LoadWavFile(source1Wav, "speech_female.wav");									// Loading .wav file										   
	//LoadWavFile(source1Wav, "sweep0_5.wav");										// Loading .wav file										   
	//AudioDevice Setup
	//// Before getting the devices list for the second time, the strean must be closed. Otherwise,
	//// the app crashes when systemSoundStream.start(); or stop() are called.
	systemSoundStream.close();
	SetDeviceAndAudio(audioState);

	//GUI setup
	logoUMA.loadImage(pathResources + "\\" + "UMA.png");
	logoUMA.resize(logoUMA.getWidth() / 10, logoUMA.getHeight() / 10);
	titleFont.load(pathResources + "\\" + "Verdana.ttf", 32);
	logoSAVLab.loadImage(pathResources + "\\" + "SAVLab.png");
	logoSAVLab.resize(logoSAVLab.getWidth() / 10, logoSAVLab.getHeight() / 10);

	leftPanel.disableHeader();
	leftPanel.setup(pathResources + "\\", "config.xml", 20, 150);
	leftPanel.setWidthElements(220);

	zoom.addListener(this, &ofApp::changeZoom);
	leftPanel.add(zoom.setup("Zoom (Pg. up/down)", 0, -20, 20, 50, 15));

	reflectionOrderControl.addListener(this, &ofApp::changeReflectionOrder);
	leftPanel.add(reflectionOrderControl.set("Relection Order (+/-)", INITIAL_REFLECTION_ORDER, 0, MAX_REFLECTION_ORDER));
	
	maxDistanceImageSourcesToListenerControl.addListener(this, &ofApp::changeMaxDistanceImageSources);
	leftPanel.add(maxDistanceImageSourcesToListenerControl.set("Max Distance (m)", INITIAL_DIST_SILENCED_FRAMES, 2, MAX_DIST_SILENCED_FRAMES));

	anechoicEnableControl.addListener(this, &ofApp::toggleAnechoic);
	leftPanel.add(anechoicEnableControl.set("Direct Path", true));

	//reverbEnableControl.addListener(this, &ofApp::toggleReverb);
	//leftPanel.add(reverbEnableControl.set("REVERB", false));
	bDisableReverb = true;

	binauralSpatialisationEnableControl.addListener(this, &ofApp::toggleBinauralSpatialisation);
	leftPanel.add(binauralSpatialisationEnableControl.set("Binaural spatialisation", true));

	/* The system starts its execution in PLAY mode
       playState = true;
       stopState = false;

       stopToPlayControl.addListener(this, &ofApp::stopToPlay);
       leftPanel.add(stopToPlayControl.set("PLAY_AUDIO", true));

       playToStopControl.addListener(this, &ofApp::playToStop);
       leftPanel.add(playToStopControl.set("STOP_AUDIO", false));
    */

//The system starts its execution in STOP mode
	playState = false;
	stopState = true;

	systemSoundStream.stop();

	stopToPlayControl.addListener(this, &ofApp::stopToPlay);
	leftPanel.add(stopToPlayControl.set("Play", false));

	playToStopControl.addListener(this, &ofApp::playToStop);
	leftPanel.add(playToStopControl.set("Stop", true));
	
	numberOfSecondsToRecordControl.addListener(this, &ofApp::changeSecondsToRecordIR);
	leftPanel.add(numberOfSecondsToRecordControl.set("IR lenght (s)", 1, 1, MAX_SECONDS_TO_RECORD));

	recordOfflineIRControl.addListener(this, &ofApp::recordIrOffline);
	leftPanel.add(recordOfflineIRControl.set("Save IR", false));

	recordOfflineWAVControl.addListener(this, &ofApp::recordWavOffline);
	leftPanel.add(recordOfflineWAVControl.set("Record (offline)", false));
		
	changeAudioToPlayControl.addListener(this, &ofApp::changeAudioToPlay);
	leftPanel.add(changeAudioToPlayControl.set("Load audio", false));

	changeRoomGeometryControl.addListener(this, &ofApp::changeRoomGeometry);
	leftPanel.add(changeRoomGeometryControl.set("Load room", false));

	changeHRTFControl.addListener(this, &ofApp::changeHRTF);
	leftPanel.add(changeHRTFControl.set("Load HRTF", false));
	
	helpDisplayControl.addListener(this, &ofApp::toogleHelpDisplay);
	leftPanel.add(helpDisplayControl.set("Help", false));

	aboutDisplayControl.addListener(this, &ofApp::toogleAboutDisplay);
	leftPanel.add(aboutDisplayControl.set("About", false));
	
	int numWalls = ISMHandler->getRoom().getWalls().size();
	for (int i = 0; i < numWalls; i++)
	{
		ofParameter<bool> tempWall;
		guiActiveWalls.push_back(tempWall);
		guiActiveWalls.at(i) = true;
	}
	
	// Offline WAV record
	recordingOffline = false;
	recordingPercent = 0.0f;
	offlineRecordIteration = 0;
	offlineRecordBuffers = 0;
	frameRate = ofGetFrameRate();		
	// Profilling
	profilling = false;
	setupDone = true;
}


//--------------------------------------------------------------
void ofApp::update() {
	
}

//--------------------------------------------------------------
void ofApp::draw() {
		
	if (recordingOffline)											//OF_KEY_F9 (OFFLINE WAV RECORD)
	{
		uint64_t frameStart = ofGetElapsedTimeMillis();
		//int bufferSize = 512;
		int bufferSize = myCore.GetAudioState().bufferSize;

		if (offlineRecordBuffers == 0) {
			
			string pathData = ofToDataPath("", true);
			string filename2, fileNameUsr;
			if (boolRecordingIR)
				fileNameUsr = ofSystemTextBoxDialog("File to save Response Impulse", filename2 = "");
			else
				fileNameUsr = ofSystemTextBoxDialog("File to save the recording", filename2 = "");
		
			if (fileNameUsr.size() > 0) {				
				StartWavRecord(fileNameUsr+".wav", 16);                        // Open wav file
				startRecordingOfflineTime = std::chrono::high_resolution_clock::now();
			}
			else
			{
				recordingOffline = false;                               // Cancel recording process
				boolRecordingIR = false;
				return;
			}
			
			if (boolRecordingIR)
			{
				offlineRecordBuffers = OfflineWavRecordStartLoop((secondsToRecordIR) * 1000);
				cout << "Number of offlineRecordBuffers= " << offlineRecordBuffers << "\n";
			}
			else
			{                                                           //Calculates the number of buffers associated with the size of the wav file
				unsigned long long samplesVectorSize = source1Wav.getSizeSamplesVector();
				offlineRecordBuffers = ceil(samplesVectorSize / myCore.GetAudioState().bufferSize);
				cout << "Number of offlineRecordBuffers= " << offlineRecordBuffers << "\n";
			}

			lock_guard < mutex > lock(audioMutex);	                  // Avoids race conditions with audio thread when cleaning buffers					
			systemSoundStream.stop();
			environment->ResetReverbBuffers();
			anechoicSourceDSP->ResetSourceBuffers();				  //Clean buffers

			imageSourceDSPList = reCreateImageSourceDSP();
			
			for (int i = 0; i < imageSourceDSPList.size(); i++)
				imageSourceDSPList.at(i)->ResetSourceBuffers();	

			if (boolRecordingIR)
			{
				source1Wav.startRecordOfflineOfImpulseResponse(secondsToRecordIR);      //Save initial wav file
			}
			source1Wav.setInitialPosition(); //Now the wav file is always recorded from the beginning
		}
				
		
		ofPushStyle();
		ofBackground(80, 80, 80);
		ShowRecordingMessage();

		float frameDurationInMilliseconds = 1000.0f / frameRate;
		
		float aux;
		while ((aux = ofGetElapsedTimeMillis() - frameStart) < frameDurationInMilliseconds)		{
			OfflineWavRecordOneLoopIteration(bufferSize);  //audioProcess + wavWriter_AppendToFile + offlineRecordBuffers++
			offlineRecordIteration++;
		}
		if (offlineRecordBuffers != 0)
			recordingPercent = 0 + (100 * offlineRecordIteration) / offlineRecordBuffers;

		if (recordingPercent >= 100.0f){
			stopRecordingOfflineTime = std::chrono::high_resolution_clock::now();
			ShowRecordingDurationTime();
			OfflineWavRecordEndLoop();    // StopWavRecord & recordingOffline = false;
			EndWavRecord();               // Close wav file
			
			if (boolRecordingIR)
			{
				source1Wav.endRecordOfflineOfImpulseResponse();    //Restore initial wav file
				boolRecordingIR = false;
			}
			source1Wav.setInitialPosition();
			if (!stopState) systemSoundStream.start();
		}
		ofPopStyle();		
		return;
	}

	//////////////////////////////////////begin of 3D drawing//////////////////////////////////////
	ofPushMatrix();
	ofScale(scale);
	ofScale(1, -1, 1);
	ofTranslate(ofGetWidth() / (scale * 2), -ofGetHeight() / (scale * 2), 0);
	ofRotateZ(90);
	ofRotateY(elevation);
	ofRotateZ(azimuth);

	//draw reference axis
	ofPushStyle();
	ofSetColor(255, 150, 150);
	ofLine(0, 0, 0, 1, 0, 0);
	ofSetColor(150, 255, 150);
	ofLine(0, 0, 0, 0, 1, 0);
	ofSetColor(150, 150, 255);
	ofLine(0, 0, 0, 0, 0, 1);
	ofPopStyle();

	drawRoom(mainRoom, reflectionOrderControl, 255);

	//draw lisener
	Common::CTransform listenerTransform = listener->GetListenerTransform();
	Common::CVector3 listenerLocation = listenerTransform.GetPosition();
	ofSphere(listenerLocation.x, listenerLocation.y, listenerLocation.z, 0.09);						//draw listener

	//draw anechoic source
	ofPushStyle();
	ofSetColor(255, 50, 200, 50);
	Common::CVector3 sourceLocation = ISMHandler->getSourceLocation();
	ofBox(sourceLocation.x, sourceLocation.y, sourceLocation.z, 0.2);								//draw anechoic source
	ofLine(sourceLocation.x, sourceLocation.y, sourceLocation.z,
		listenerLocation.x, listenerLocation.y, listenerLocation.z);								//draw ray from anechoic source

	int numberOfVisibleImages = 0;
	std::vector<ISM::ImageSourceData> imageSourceDataList = ISMHandler->getImageSourceData();
	if (!stopState) {
		//draw image sources (only if play state)
		for (int i = 0; i < imageSourceDataList.size(); i++)
		{
			if (imageSourceDataList.at(i).visible)
			{
				numberOfVisibleImages++;
				ofSetColor(255, 150, 200, imageSourceDataList.at(i).visibility * 255);
				ofBox(imageSourceDataList.at(i).location.x, imageSourceDataList.at(i).location.y, imageSourceDataList.at(i).location.z, 0.2);
				ofLine(imageSourceDataList.at(i).location.x, imageSourceDataList.at(i).location.y, imageSourceDataList.at(i).location.z,
					listenerLocation.x, listenerLocation.y, listenerLocation.z);
				for (int j = 0; j < imageSourceDataList.at(i).reflectionWalls.size(); j++)
				{
					ofPushStyle();
					if (imageSourceDataList.at(i).visibility < 1)
					{
						ofSetColor(150, 255, 200, imageSourceDataList.at(i).visibility * 255);
					}
					Common::CVector3 reflectionPoint = imageSourceDataList.at(i).reflectionWalls.at(j).getIntersectionPointWithLine(imageSourceDataList.at(i).location, listenerLocation);
					ofBox(reflectionPoint.x, reflectionPoint.y, reflectionPoint.z, 0.05);
					ofPopStyle();
				}
			}
		}

	}
	
	ofPopStyle();
	//sourceImages.drawFirstReflectionRays(listenerPosition);

	ofPopMatrix();
	//////////////////////////////////////end of 3D drawing//////////////////////////////////////

	/// Logo of The University of Malaga and Title
	logoUMA.draw(20, 20);
	char title[40];
	if (ofGetWidth() > 1500)
	{
		sprintf(title, "Image Source Method Simulator");
	}
	else
	{
		sprintf(title, "ISM Simulator");
	}
	titleFont.drawString(title, ofGetWidth() / 2 - titleFont.stringWidth(title) / 2, 85);

	/// Logo of the SAVLab project
	logoSAVLab.draw(ofGetWidth() - 300, 20);
	/// This work has been partially funded by the Spanish project Spatial Audio Virtual Laboratory (SAVLab) - PID2019-107854GB-I00, Ministerio de Ciencia e Innovación
	ofDrawBitmapString("This work has been partially", ofGetWidth() - 280, 140);
	ofDrawBitmapString("funded by the Spanish project", ofGetWidth() - 280, 155);
	ofDrawBitmapString("Spatial Audio Virtual Laboratory", ofGetWidth() - 280, 170);
	ofDrawBitmapString("(SAVLab) - PID2019-107854GB-I00", ofGetWidth() - 280, 185);
	ofDrawBitmapString("Ministerio de Ciencia e Innovacion", ofGetWidth() - 280, 200);

	/// print number of visible images
	ofPushStyle();
	ofSetColor(50, 150);
	ofRect(ofGetWidth() - 300, ofGetHeight()- 100, 290, 90);
	ofPopStyle();
	char numberOfImagesStr[255];
	sprintf(numberOfImagesStr, "Number of visible images: %d", numberOfVisibleImages);
	ofDrawBitmapString(numberOfImagesStr, ofGetWidth() - 285, ofGetHeight() - 85);
	sprintf(numberOfImagesStr, "Number of source DSPs: %d", imageSourceDSPList.size()+1);  //number of DSPs for teh images plus one for the anechoic
	ofDrawBitmapString(numberOfImagesStr, ofGetWidth() - 285, ofGetHeight()-65);
	sprintf(numberOfImagesStr, "Max distance images-listener: %d", int(ISMHandler->getMaxDistanceImageSources()));
	ofDrawBitmapString(numberOfImagesStr, ofGetWidth() - 285, ofGetHeight() - 45);
#if 0
	if (!bDisableReverb) 
	{
 	    sprintf(numberOfImagesStr, "Number of silences frames: %d", numberOfSilencedFrames);
		ofDrawBitmapString(numberOfImagesStr, ofGetWidth() - 285, ofGetHeight() - 25);
	}
	else
	{
		sprintf(numberOfImagesStr, "Reverb Disabled");
		ofDrawBitmapString(numberOfImagesStr, ofGetWidth() - 285, ofGetHeight() - 25);
	}
#endif
	
	if (!boolToogleDisplayHelp)
	{
		ofPushStyle();
		ofSetColor(50, 150);
		ofRect(20, ofGetHeight() - 250, 390, 355);
		ofPopStyle();
		char numberOfImagesStr[255];
		sprintf(numberOfImagesStr, "Point of View Control: cursor keys");
		ofDrawBitmapString(numberOfImagesStr, 30, ofGetHeight() -230);
		
		sprintf(numberOfImagesStr, "MoveSOURCE:      'k'_Left(-X)   'i'_Right(+X)");
		ofDrawBitmapString(numberOfImagesStr, 30, ofGetHeight() - 210);
		sprintf(numberOfImagesStr, "                 'j'_Up  (+Y)   'l'_Down (-Y)");
		ofDrawBitmapString(numberOfImagesStr, 30, ofGetHeight() - 190);
		sprintf(numberOfImagesStr, "                 'u'_Up  (+Z)   'm'_Down (-Z)");
		ofDrawBitmapString(numberOfImagesStr, 30, ofGetHeight() - 170);

		sprintf(numberOfImagesStr, "MoveLISTENER:    's'_Left(-X)   'w'_Right(+X)");
		ofDrawBitmapString(numberOfImagesStr, 30, ofGetHeight() - 150);
		sprintf(numberOfImagesStr, "                 'a'_Up  (+Y)   'd'_Down (-Y)");
		ofDrawBitmapString(numberOfImagesStr, 30, ofGetHeight() - 130);
		sprintf(numberOfImagesStr, "                 'e'_Up  (+Z)   'x'_Down (-Z)");
		ofDrawBitmapString(numberOfImagesStr, 30, ofGetHeight() - 110);
		
		sprintf(numberOfImagesStr, "RotateLISTENER:  'A'_Left       'D'_right");
		ofDrawBitmapString(numberOfImagesStr, 30, ofGetHeight() - 90);
				
		sprintf(numberOfImagesStr, "ShoeBoxRoom:     'y'_Length++   'b'_Length--");
		ofDrawBitmapString(numberOfImagesStr, 30, ofGetHeight() - 70);
		sprintf(numberOfImagesStr, "                 'g'_Width++    'h'_Width--");
		ofDrawBitmapString(numberOfImagesStr, 30, ofGetHeight() - 50);
		sprintf(numberOfImagesStr, "                 'v'_Height++   'n'_Height--");
		ofDrawBitmapString(numberOfImagesStr, 30, ofGetHeight() - 30);
		sprintf(numberOfImagesStr, "Enable or disable wall: '1' '2' '3' '4' ... ");
		ofDrawBitmapString(numberOfImagesStr, 30, ofGetHeight() - 10);

	}

	if (!boolToogleDisplayAbout)
	{

		ofPushStyle();
		ofSetColor(50, 150);
		ofRect((ofGetWidth()/2)-300, ofGetHeight()/4, 660, 300);
		ofPopStyle();
		char numberOfImagesStr[255];
		sprintf(numberOfImagesStr, "Version: 1.0.0");
		ofDrawBitmapString(numberOfImagesStr, (ofGetWidth() / 2) - 300 +30, ofGetHeight()/4 +20);
		sprintf(numberOfImagesStr, "Copyright: ");
		ofDrawBitmapString(numberOfImagesStr, (ofGetWidth() / 2) - 300 + 30, ofGetHeight()/4 +50);
		sprintf(numberOfImagesStr, "Authors: Fabian Arrebola, Daniel Gonzalez-Toledo, Paula Garcia-Jimenez");
		ofDrawBitmapString(numberOfImagesStr, (ofGetWidth() / 2) - 300 + 30, ofGetHeight()/4 +80);
		sprintf(numberOfImagesStr, "         Luis Molina-Tanco, Maria Cuevas-Rodriguez, Arcadio Reyes-Lecuona");
		ofDrawBitmapString(numberOfImagesStr, (ofGetWidth() / 2) - 300 + 30, ofGetHeight()/4 +100);

		sprintf(numberOfImagesStr, "M. Cuevas-Rodriguez et al., 3D Tune-In Toolkit:");
		ofDrawBitmapString(numberOfImagesStr, (ofGetWidth() / 2) - 300 + 30, ofGetHeight()/4 +130);
		sprintf(numberOfImagesStr, "An open - source library for real - time binaural spatialisation,");
		ofDrawBitmapString(numberOfImagesStr, (ofGetWidth() / 2) - 300 + 30, ofGetHeight() / 4 +150);
		sprintf(numberOfImagesStr, "PLoS One, vol. 14, no. 3, p. e0211899, Mar. 2019.");
		ofDrawBitmapString(numberOfImagesStr, (ofGetWidth() / 2) - 300 + 30, ofGetHeight() / 4 +170);
		
		sprintf(numberOfImagesStr, "This work has been partially funded by the Ministry of Science and Technology");
		ofDrawBitmapString(numberOfImagesStr, (ofGetWidth() / 2) - 300 + 30, ofGetHeight()/4 +200);
		sprintf(numberOfImagesStr, "within the National R&D Plan through the SAVLab project");
		ofDrawBitmapString(numberOfImagesStr, (ofGetWidth() / 2) - 300 + 30, ofGetHeight()/4 +220);
		sprintf(numberOfImagesStr, "Virtual Spatial Audio Laboratory (PID2019-107854GB-I00)");
		ofDrawBitmapString(numberOfImagesStr, (ofGetWidth() / 2) - 300 + 30, ofGetHeight()/4 +240);
		sprintf(numberOfImagesStr, "and by the European Union, within the framework program Horizon 2020");
		ofDrawBitmapString(numberOfImagesStr, (ofGetWidth() / 2) - 300 + 30, ofGetHeight()/4 +260);
		sprintf(numberOfImagesStr, "through the SONICOM project (agreement No. 101017743)");
		ofDrawBitmapString(numberOfImagesStr, (ofGetWidth() / 2) - 300 + 30, ofGetHeight()/4 +280);
		 
	}

	leftPanel.draw();
}

//--------------------------------------------------------------
void ofApp::keyPressed(int key){

	Common::CTransform listenerTransform = listener->GetListenerTransform();
	Common::CVector3 listenerLocation = listenerTransform.GetPosition();

	float distanceNearestWall;
	bool state;
		
	switch (key)
	{
	case OF_KEY_LEFT:
		azimuth++;
		break;
	case OF_KEY_RIGHT:
		azimuth--;
		break;
	case OF_KEY_UP:
		elevation++;
		break;
	case OF_KEY_DOWN:
		elevation--;
		break;
	case OF_KEY_PAGE_UP:
	    scale*=0.9;
		break;
	case OF_KEY_PAGE_DOWN:
		scale*=1.1;
		break;
	case OF_KEY_INSERT:
		numberOfSilencedFrames++;
		if (numberOfSilencedFrames > 250) numberOfSilencedFrames = 250;
		/*int numberOfSilencedFrames;
		numberOfSilencedFrames = environment->GetNumberOfSilencedFrames();
		numberOfSilencedFrames++;
		environment->SetNumberOfSilencedFrames(numberOfSilencedFrames);*/
		break;
		
	case OF_KEY_DEL:
		numberOfSilencedFrames--;
		if (numberOfSilencedFrames < 0) numberOfSilencedFrames = 0;
		/*int numberOfSilencedFrames;
		numberOfSilencedFrames = environment->GetNumberOfSilencedFrames();
		numberOfSilencedFrames--;
		environment->SetNumberOfSilencedFrames(numberOfSilencedFrames);*/
		break;
	case OF_KEY_HOME: // OF_KEY_PAGE_UP:
		if (maxDistanceImageSourcesToListenerControl < MAX_DIST_SILENCED_FRAMES) {
			maxDistanceImageSourcesToListenerControl++;
		}
		break;

	case OF_KEY_END: //OF_KEY_PAGE_DOWN:
		if (maxDistanceImageSourcesToListenerControl > MIN_DIST_SILENCED_FRAMES) 
		{
			maxDistanceImageSourcesToListenerControl--;
		}
		break;
		
	case 'k': //Moves the source left (-X)
		moveSource(Common::CVector3(-SOURCE_STEP, 0, 0));
		break;
	case 'i': //Moves the source right (+X)
		moveSource(Common::CVector3(SOURCE_STEP, 0, 0));
		break;
	case 'j': //Moves the source up (+Y)
		moveSource(Common::CVector3(0, SOURCE_STEP, 0));
		break;
	case 'l': //Moves the source down (-Y)
		moveSource(Common::CVector3(0, -SOURCE_STEP, 0));
		break;
	case 'u': //Moves the source up (Z)
		moveSource(Common::CVector3(0, 0, SOURCE_STEP));
		break;
	case 'm': //Moves the source down (-Z)
		moveSource(Common::CVector3(0, 0, -SOURCE_STEP));
		break;
	case 's': //Moves the listener left (-X)
	{
		listenerTransform.Translate(Common::CVector3(-LISTENER_STEP, 0, 0));
		listener->SetListenerTransform(listenerTransform);
		/////
		listenerTransform = listener->GetListenerTransform();
		listenerLocation = listenerTransform.GetPosition();
		mainRoom = ISMHandler->getRoom();
		state = mainRoom.checkPointInsideRoom(listenerLocation, distanceNearestWall);
		if (state == false)
		{
			listenerTransform.Translate(Common::CVector3(LISTENER_STEP, 0, 0));
			listener->SetListenerTransform(listenerTransform);
		}
		Common::CVector3 Location = ISMHandler->getSourceLocation();
		ISMHandler->setSourceLocation(Location);  //FIXME: when the listener is moved images should be updated
		break;
	}
	case 'w': //Moves the listener right (X)
	{
		listenerTransform.Translate(Common::CVector3(LISTENER_STEP, 0, 0));
		listener->SetListenerTransform(listenerTransform);
		/////
		listenerTransform = listener->GetListenerTransform();
		listenerLocation = listenerTransform.GetPosition();
		mainRoom = ISMHandler->getRoom();
		state = mainRoom.checkPointInsideRoom(listenerLocation, distanceNearestWall);
		if (state == false)
		{
			listenerTransform.Translate(Common::CVector3(-LISTENER_STEP, 0, 0));
			listener->SetListenerTransform(listenerTransform);
		}
		Common::CVector3 Location = ISMHandler->getSourceLocation();
		ISMHandler->setSourceLocation(Location); // FIXME: when the listener is moved images should be updated
		break;
	}
	case 'a': //Moves the listener up (Y)
	{
		listenerTransform.Translate(Common::CVector3(0, LISTENER_STEP, 0));
		listener->SetListenerTransform(listenerTransform);
		/////
		listenerTransform = listener->GetListenerTransform();
		listenerLocation = listenerTransform.GetPosition();
		mainRoom = ISMHandler->getRoom();
		state = mainRoom.checkPointInsideRoom(listenerLocation, distanceNearestWall);
		if (state==false)
		{
			listenerTransform.Translate(Common::CVector3(0, -LISTENER_STEP, 0));
			listener->SetListenerTransform(listenerTransform);
		}
		Common::CVector3 Location = ISMHandler->getSourceLocation();
		ISMHandler->setSourceLocation(Location); // FIXME: when the listener is moved images should be updated
		break;
	}
	case 'd': //Moves the listener down (-Y)
	{
		listenerTransform.Translate(Common::CVector3(0, -LISTENER_STEP, 0));
		listener->SetListenerTransform(listenerTransform);
		/////
		listenerTransform = listener->GetListenerTransform();
		listenerLocation = listenerTransform.GetPosition();
		mainRoom = ISMHandler->getRoom();
		state = mainRoom.checkPointInsideRoom(listenerLocation, distanceNearestWall);
		if (state == false)
		{
			listenerTransform.Translate(Common::CVector3(0, LISTENER_STEP, 0));
			listener->SetListenerTransform(listenerTransform);
		}
		Common::CVector3 Location = ISMHandler->getSourceLocation();
		ISMHandler->setSourceLocation(Location); // FIXME: when the listener is moved images should be updated
		break;
	}
	case 'e': //Moves the listener up (Z)
	{
		listenerTransform.Translate(Common::CVector3(0, 0, LISTENER_STEP));
		listener->SetListenerTransform(listenerTransform);
		/////
		listenerTransform = listener->GetListenerTransform();
		listenerLocation = listenerTransform.GetPosition();
		mainRoom = ISMHandler->getRoom();
		state = mainRoom.checkPointInsideRoom(listenerLocation, distanceNearestWall);
		if (state == false)
		{
			listenerTransform.Translate(Common::CVector3(0, 0, -LISTENER_STEP));
			listener->SetListenerTransform(listenerTransform);
		}
		Common::CVector3 Location = ISMHandler->getSourceLocation();	
		ISMHandler->setSourceLocation(Location); // FIXME: when the listener is moved images should be updated
		break;
	}

	case 'x': //Moves the listener up (-Z)
	{
		listenerTransform.Translate(Common::CVector3(0, 0, -LISTENER_STEP));
		listener->SetListenerTransform(listenerTransform);
		/////
		listenerTransform = listener->GetListenerTransform();
		listenerLocation = listenerTransform.GetPosition();
		mainRoom = ISMHandler->getRoom();
		state = mainRoom.checkPointInsideRoom(listenerLocation, distanceNearestWall);
		if (state == false)
		{
			listenerTransform.Translate(Common::CVector3(0, 0, LISTENER_STEP));
			listener->SetListenerTransform(listenerTransform);
		}
		Common::CVector3 Location = ISMHandler->getSourceLocation();
		ISMHandler->setSourceLocation(Location); // FIXME: when the listener is moved images should be updated
		break;
	}
	case 'A': //Rotate Left
		listenerTransform.Rotate(Common::CVector3(0, 0, 1), 0.05);
		listener->SetListenerTransform(listenerTransform);
		break;
	case 'D': //Rotate Right
		listenerTransform.Rotate(Common::CVector3(0, 0, 1), -0.05);
		listener->SetListenerTransform(listenerTransform);
		break;
	case '+': //increases the reflection order 
		if(reflectionOrderControl<MAX_REFLECTION_ORDER) reflectionOrderControl++;
		break;
	case '-': //decreases the reflection order 
		if (reflectionOrderControl > 0) reflectionOrderControl--;
		break;
	case '1': //enable/disable wall number 1 
		if (guiActiveWalls.size() > 0) 
		{
			guiActiveWalls.at(0) = !guiActiveWalls.at(0);
			refreshActiveWalls();
		}
		break;
	case '2': //enable/disable wall number 2 
		if (guiActiveWalls.size() > 1)
		{
			guiActiveWalls.at(1) = !guiActiveWalls.at(1);
			refreshActiveWalls();
		}
		break;
	case '3': //enable/disable wall number 3 
		if (guiActiveWalls.size() > 2)
		{
			guiActiveWalls.at(2) = !guiActiveWalls.at(2);
			refreshActiveWalls();
		}
		break;
	case '4': //enable/disable wall number 4 
		if (guiActiveWalls.size() > 3)
		{
			guiActiveWalls.at(3) = !guiActiveWalls.at(3);
			refreshActiveWalls();
		}
		break;
	case '5': //enable/disable wall number 5 
		if (guiActiveWalls.size() > 4)
		{
			guiActiveWalls.at(4) = !guiActiveWalls.at(4);
			refreshActiveWalls();
		}
		break;
	case '6': //enable/disable wall number 6 
		if (guiActiveWalls.size() > 5)
		{
			guiActiveWalls.at(5) = !guiActiveWalls.at(5);
			refreshActiveWalls();
		}
		break;
	case '7': //enable/disable wall number 7
		if (guiActiveWalls.size() > 6)
		{
			guiActiveWalls.at(6) = !guiActiveWalls.at(6);
			refreshActiveWalls();
		}
		break;
	case '8': //enable/disable wall number 8
		if (guiActiveWalls.size() > 7)
		{
			guiActiveWalls.at(7) = !guiActiveWalls.at(7);
			refreshActiveWalls();
		}
		break;
	case '9': //enable/disable wall number 9
		if (guiActiveWalls.size() > 8)
		{
			guiActiveWalls.at(8) = !guiActiveWalls.at(8);
			refreshActiveWalls();
		}
		break;
	case '0': //enable/disable wall number 10
		if (guiActiveWalls.size() > 9)
		{
			guiActiveWalls.at(9) = !guiActiveWalls.at(9);
			refreshActiveWalls();
		}
		break;
#if 0
	case OF_KEY_F1://ABSORTION -- null
	{
		if (!stopState) systemSoundStream.stop();
		
		int numWalls = ISMHandler->getRoom().getWalls().size();
		for (int i = 0; i < numWalls; i++) {
			absortionsWalls.at(i) = { 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 };
		}
		ISMHandler->setAbsortion((std::vector<std::vector<float>>)  absortionsWalls);

		imageSourceDSPList = reCreateImageSourceDSP();
		
		mainRoom = ISMHandler->getRoom();
		if (!stopState) systemSoundStream.start();
		break;
	}
#endif
	
	case 'y': //increase room's length
		if (!stopState) systemSoundStream.stop();
		
		shoeboxLength += 0.5;
		ISMHandler->SetupShoeBoxRoom(shoeboxLength, shoeboxWidth, shoeboxHeight);
				
		ISMHandler->setAbsortion({ {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3} });
		
		mainRoom = ISMHandler->getRoom();
		imageSourceDSPList = reCreateImageSourceDSP();
		if (!stopState) systemSoundStream.start();
		break;
	case 'b': //decrease room's length
		if (!stopState) systemSoundStream.stop();
		if (shoeboxLength > 3.0)  shoeboxLength -= 0.5;
		
		ISMHandler->SetupShoeBoxRoom(shoeboxLength, shoeboxWidth, shoeboxHeight);
		
		ISMHandler->setAbsortion({ {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3} });
		
		mainRoom = ISMHandler->getRoom();
		imageSourceDSPList = reCreateImageSourceDSP();
		if (!stopState) systemSoundStream.start();
		break;
	case 'g': //decrease room's width
		if (!stopState) systemSoundStream.stop();
		if (shoeboxWidth > 3.0) shoeboxWidth -= 0.5;
		
		ISMHandler->SetupShoeBoxRoom(shoeboxLength, shoeboxWidth, shoeboxHeight);
		
		ISMHandler->setAbsortion({ {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3} });
		
		mainRoom = ISMHandler->getRoom();
		imageSourceDSPList = reCreateImageSourceDSP();
		if (!stopState) systemSoundStream.start();
		break;
	case 'h': //increase room's width
		if (!stopState) systemSoundStream.stop();
		shoeboxWidth += 0.5;

		ISMHandler->SetupShoeBoxRoom(shoeboxLength, shoeboxWidth, shoeboxHeight);
		
		ISMHandler->setAbsortion({ {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3} });
		
		mainRoom = ISMHandler->getRoom();
		imageSourceDSPList = reCreateImageSourceDSP();
		if (!stopState) systemSoundStream.start();
		break;
	case 'v': //decrease room's height
		if (!stopState) systemSoundStream.stop();
		if (shoeboxHeight > 2.5) shoeboxHeight -= 0.5;
		ISMHandler->SetupShoeBoxRoom(shoeboxLength, shoeboxWidth, shoeboxHeight);
		
		ISMHandler->setAbsortion({ {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3} });
		
		mainRoom = ISMHandler->getRoom();
		imageSourceDSPList = reCreateImageSourceDSP();
		if (!stopState) systemSoundStream.start();
		break;
	case 'n': //increase room's height
		if (!stopState) systemSoundStream.stop();
		shoeboxHeight += 0.5;
		ISMHandler->SetupShoeBoxRoom(shoeboxLength, shoeboxWidth, shoeboxHeight);
		
		ISMHandler->setAbsortion({ {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3} });
		
		mainRoom = ISMHandler->getRoom();
		imageSourceDSPList = reCreateImageSourceDSP();
		if (!stopState) systemSoundStream.start();
		break;
	case 't': //Test
		std::vector<ISM::ImageSourceData> data = ISMHandler->getImageSourceData();
		auto w2 = std::setw(2);
		auto w5 = std::setw(5);
		auto w6 = std::setw(6);
		auto w7 = std::setw(7);
		cout << "------------------------------------------------List of Source Images ---------------------------------------------\n";
		cout << "  Visibility | Refl. |                Reflection coeficients                 |        Location       | Dist. (Room)\n";
		cout << "             | order | ";
		float freq = 62.5;
		for (int i = 0; i < NUM_BAND_ABSORTION; i++)
		{
			if(freq < 100) { cout << ' '; }
			if(freq < 1000) { cout << ((int) freq) << "Hz "; }
			else { cout << w2 << ((int) (freq / 1000)) << "kHz "; }
			freq *= 2;
		}
		cout << "|    X       Y       Z  |  \n";
		cout << "-------------+-------+-------------------------------------------------------+-----------------------+--------\n";
		for (int i = 0; i < data.size(); i++)
		{
			if (data.at(i).visible) cout << "VISIBLE "; else cout << "        ";
			cout << w5 << std::fixed << std::setprecision(2) << data.at(i).visibility;							//print source visibility 
			cout << "|   " << data.at(i).reflectionWalls.size();												//print number of reflection needed for this source
			cout << "   | ";
			for (int j = 0; j < NUM_BAND_ABSORTION; j++)
			{ 
				cout << w5 << std::fixed << std::setprecision(2) << data.at(i).reflectionBands.at(j) << " ";	//print abortion coefficientes for a source
			}
			cout << "| " << w6 << std::fixed << std::setprecision(2) << data.at(i).location.x << ", ";			//print source location
			cout << w6 << std::fixed << std::setprecision(2) << data.at(i).location.y << ", ";
			cout << w6 << std::fixed << std::setprecision(2) << data.at(i).location.z << "|";

			cout << w6 << (data.at(i).location - listenerLocation).GetDistance();								//print distance to listener and distance between first and last reflection walls
			cout << " (" << data.at(i).reflectionWalls.front().getMinimumDistanceFromWall(data.at(i).reflectionWalls.back()) << ")" << "\n";
		}
		cout << "Shoebox \n";
		cout << "X=" << shoeboxLength << "\n" << "Y=" << shoeboxWidth << "\n" << "Z=" << shoeboxHeight << "\n";

		if (stateAnechoicProcess) 
			cout << "AnechoicProcess Enabled" << "\n";
		else 
			cout << "AnechoicProcess Disabled" << "\n";

		if (stateBinauralSpatialisation)
			cout << "BinauralSpatialisation Enabled" << "\n";
		else
			cout << "BinauralSpatialisation Disabled" << "\n";

#if 0
		if (!bDisableReverb)
		{
			cout << "Reverb Enabled" << "\n";
			cout << "Number of silenced frames= " << numberOfSilencedFrames << "\n";
		}
		else
			cout << "Reverb Disabled" << "\n";
#endif

		cout << "Max distance images to listener = " << ISMHandler->getMaxDistanceImageSources() << "\n";
		
		break;
	}
}

//--------------------------------------------------------------
void ofApp::keyReleased(int key){
	if (key == 32 /*space*/) {
		std::cout << "Starting profilling" << std::endl;
		std::this_thread::sleep_for(10ms);		// In case "cout" will create some kind of interference with the profile measurement.
		profilling = true;
	}
}

//--------------------------------------------------------------
void ofApp::mouseMoved(int x, int y ){

}

//--------------------------------------------------------------
void ofApp::mouseDragged(int x, int y, int button){

}

//--------------------------------------------------------------
void ofApp::mousePressed(int x, int y, int button){
														
}

//--------------------------------------------------------------
void ofApp::mouseReleased(int x, int y, int button){

}

//--------------------------------------------------------------
void ofApp::mouseEntered(int x, int y){

}

//--------------------------------------------------------------
void ofApp::mouseExited(int x, int y){

}

//--------------------------------------------------------------
void ofApp::windowResized(int w, int h){

}

//--------------------------------------------------------------
void ofApp::gotMessage(ofMessage msg){

}

//--------------------------------------------------------------
void ofApp::dragEvent(ofDragInfo dragInfo){ 

}

/// Read the list of devices of the user computer, allowing the user to select which device to use. Configure the Audio using openFramework
void ofApp::SetDeviceAndAudio(Common::TAudioStateStruct audioState) {
	// This call could block the app when the motu audio interface is unplugged
	// It gives the message: 
	// RtApiAsio::getDeviceInfo: error (Hardware input or output is not present or available).
	// initializing driver (Focusrite USB 2.0 Audio Driver).
	deviceList = systemSoundStream.getDeviceList();


	for (int c = deviceList.size() - 1; c >= 0; c--)
	{
		if (deviceList[c].outputChannels == 0)
			deviceList.erase(deviceList.begin() + c);
	}

	//Show list of devices and return the one selected by the user
	int deviceId = GetAudioDeviceIndex(deviceList);

	if (deviceId >= 0)
	{
		systemSoundStream.setDevice(deviceList[deviceId]);

		ofSoundDevice &dev = deviceList[deviceId];

		//Setup Aduio
		systemSoundStream.setup(this,		// Pointer to ofApp so that audioOut is called									  
			2,								//dev.outputChannels, // Number of output channels reported
			0,								// Number of input channels
			audioState.sampleRate,			// sample rate, e.g. 44100 
			audioState.bufferSize,			// Buffer size, e.g. 512
			4   // -> Is the number of buffers that your system will create and swap out.The more buffers, 
			   // the faster your computer will write information into the buffer, but the more memory it 
			  // will take up.You should probably use two for each channel that you’re using.Here’s an 
			 // example call : ofSoundStreamSetup(2, 0, 44100, 256, 4);
			//     http://openframeworks.cc/documentation/sound/ofSoundStream/
		);
		cout << "Device selected : " << "ID: " << dev.deviceID << "  Name: " << dev.name << endl;

		systemSoundStream_Started = true;

		//lastBuffer.setDeviceID(deviceId);
		
	}
	else
	{
		cout << "Could not find any usable sound Device" << endl;

		systemSoundStream_Started = false;
	}
}

/// Ask the user to select the audio device to be used and return the index of the selected device
int ofApp::GetAudioDeviceIndex(std::vector<ofSoundDevice> list)
{
	//Show in the console the Audio device list
	int numberOfAudioDevices = list.size(); 
	cout << "     List of available audio outputs" << endl;
	cout << "----------------------------------------" << endl;
	for (int i = 0; i < numberOfAudioDevices; i++) {
		cout << "ID: " << i << "-" << list[i].name << endl;
	}
	int selectedAudioDevice;

	do {
		cout << "Please choose which audio output you wish to use: ";
		cin >> selectedAudioDevice;
		cin.clear();
		cin.ignore(INT_MAX, '\n');
	} while (!(selectedAudioDevice > -1 && selectedAudioDevice <= numberOfAudioDevices));

	// First, we try to retrieve the <Conf.audioInterfaceIndex> th suitable device in the list:
	for (int c = 0; c < numberOfAudioDevices; c++)
	{
		ofSoundDevice &dev = list[c];

		if ((dev.outputChannels >= 0) && c == selectedAudioDevice)
			return c;
	}

	// Otherwise, we try to get the defult device
	for (int c = 0; c < numberOfAudioDevices; c++)
	{
		ofSoundDevice &dev = list[c];

		// dev.isDefaultOutput is not really the same that windows report
		// TODO: update to latest openFrameworks that really can report all drivers present
		// via ofSoundStream::getDevicesByApi 
		//if ((dev.outputChannels >= NUMBER_OF_SPEAKERS) && dev.isDefaultOutput)
		if ((dev.outputChannels >= 0) && dev.isDefaultOutput)
			return c;
	}
	return -1;
}


/// Audio output management by openFramework
#if 1
void ofApp::audioOut(float * output, int bufferSize, int nChannels) {
	
	lock_guard < mutex > lock(audioMutex);
	
	// The requested frame size is not allways supported by the audio driver:
	if (myCore.GetAudioState().bufferSize != bufferSize)
		return;

	// Prepare output chunk
	Common::CEarPair<CMonoBuffer<float>> bOutput;
	bOutput.left.resize(bufferSize);
	bOutput.right.resize(bufferSize);

	audioProcess(bOutput, bufferSize);
				
	// Build float array from output buffer
	int i = 0;
	CStereoBuffer<float> iOutput;
	iOutput.Interlace(bOutput.left, bOutput.right);
	for (auto it = iOutput.begin(); it != iOutput.end(); it++)
	{
		float s = *it;
		output[i++] = s;
	}
}
#endif

/// Process audio using the 3DTI Toolkit methods
#if 1
void ofApp::audioProcess(Common::CEarPair<CMonoBuffer<float>> & bufferOutput, int uiBufferSize)
{
	// Declaration, initialization and filling mono buffers
	CMonoBuffer<float> source1(uiBufferSize);  //FIXME cambiar el nombre source1
	source1Wav.FillBuffer(source1);
		
#ifdef USE_PROFILER
	if (profilling) { Common::PROFILER3DTI.RelativeSampleStart(dsProcessFrameTime); }	
#endif

	processAnechoic(source1, bufferOutput);

	if (!bDisableReverb)
	{
		processReverb(source1, bufferOutput);
	}

	//Common::CTransform lisenerTransform = listener->GetListenerTransform();
	//Common::CVector3 lisenerPosition = lisenerTransform.GetPosition();

	processImages(source1, bufferOutput);

#ifdef USE_PROFILER
	if (profilling) { Common::PROFILER3DTI.RelativeSampleEnd(dsProcessFrameTime); }
#endif	
}
#endif

void ofApp::LoadWavFile(SoundSource & source, const char* filePath)
{	
	if (!source.LoadWav(filePath)) {
		cout << "ERROR: file " << filePath << " doesn't exist." << endl<<endl;
	}
}


////////////////////////////////////////////////////////////////////////////////////////
//Methods for audio rendering 
////////////////////////////////////////////////////////////////////////////////////////

void ofApp::processAnechoic(CMonoBuffer<float> &bufferInput, Common::CEarPair<CMonoBuffer<float>> & bufferOutput)
{
	Common::CEarPair<CMonoBuffer<float>> bufferProcessed;
		
	anechoicSourceDSP->SetBuffer(bufferInput);
	anechoicSourceDSP->ProcessAnechoic(bufferProcessed.left, bufferProcessed.right);
	
	bufferOutput.left += bufferProcessed.left;
	bufferOutput.right += bufferProcessed.right;
		
}

void ofApp::processReverb(CMonoBuffer<float> &bufferInput, Common::CEarPair<CMonoBuffer<float>> & bufferOutput)
{
	// Declaration and initialization of separate buffer needed for the reverb
	Common::CEarPair<CMonoBuffer<float>> bufferReverb;

	// Reverberation processing of direct path
	environment->ProcessVirtualAmbisonicReverb(bufferReverb.left, bufferReverb.right, numberOfSilencedFrames);
	// Adding reverberated sound to the direct path
	//bufferReverb.left.ApplyGain(0.25);
	//bufferReverb.right.ApplyGain(0.25);
	bufferOutput.left += bufferReverb.left;
	bufferOutput.right += bufferReverb.right;

}


void ofApp::processImages(CMonoBuffer<float> &bufferInput, Common::CEarPair<CMonoBuffer<float>> & bufferOutput)
{
	Common::CTransform listenerTransform = listener->GetListenerTransform();
	Common::CVector3 listenerLocation = listenerTransform.GetPosition();
	std::vector<ISM::ImageSourceData> data = ISMHandler->getImageSourceData();

	if (data.size() != imageSourceDSPList.size()) { cout << "ERROR: DSP list ("<< imageSourceDSPList.size() <<") and source list ("<< data.size()<<") have different sizes \n"; }

	std::vector<CMonoBuffer<float>> bufferImages;
	ISMHandler->proccess(bufferInput, bufferImages, listenerLocation);

	for (int i = 0; i < imageSourceDSPList.size(); i++)
	{
		if (data.at(i).visible) 
		{
			Common::CEarPair<CMonoBuffer<float>> bufferProcessed;

			imageSourceDSPList.at(i)->SetBuffer(bufferImages.at(i));
			imageSourceDSPList.at(i)->ProcessAnechoic(bufferProcessed.left, bufferProcessed.right);

			bufferOutput.left += bufferProcessed.left;
			bufferOutput.right += bufferProcessed.right;
		}
	}
}


////////////////////////////////////////////////////////////////////////////////////////
//Methods for drawing 
////////////////////////////////////////////////////////////////////////////////////////
void ofApp::drawRoom(ISM::Room room, int reflectionOrder,int transparency)
{
	if (reflectionOrder > 0)
	{
		ofPushStyle();
		ofSetColor(200, transparency);
		reflectionOrder--;
		std::vector<ISM::Wall> walls = room.getWalls();
		for (int i = 0; i < walls.size(); i++)
		{
			if (walls.at(i).isActive())
			{
				drawWall(walls[i]);
				drawWallNormal(walls[i]);
			}
		}
		std::vector<ISM::Room> roomImages = room.getImageRooms();
		for (int i = 0; i < roomImages.size(); i++)
		{
			drawRoom(roomImages.at(i), reflectionOrder, transparency/2);
		}
		ofPopStyle();
	}
	
}

void ofApp::drawWall(ISM::Wall wall)
{
	std::vector<Common::CVector3> polygon = wall.getCorners();
	int numberVertex = polygon.size();
	for (int i = 0; i < numberVertex - 1; i++)
	{
		ofLine(polygon[i].x, polygon[i].y, polygon[i].z,
			polygon[i + 1].x, polygon[i + 1].y, polygon[i + 1].z);
	}
	ofLine(polygon[0].x, polygon[0].y, polygon[0].z,
		polygon[numberVertex - 1].x, polygon[numberVertex - 1].y, polygon[numberVertex - 1].z);
}

void ofApp::drawWallNormal(ISM::Wall wall, float length)
{
	Common::CVector3 center;
	Common::CVector3 normalEnd;
	Common::CVector3 normal;
	center = wall.getCenter();
	normal = wall.getNormal();
	normal.x *= length;
	normal.y *= length;
	normal.z *= length;

	normalEnd = center + normal;
	ofLine(center.x, center.y, center.z,
		normalEnd.x, normalEnd.y, normalEnd.z);
}


////////////////////////////////////////////////////////////////////////////////////////
//Methods for managing sources 
////////////////////////////////////////////////////////////////////////////////////////

void ofApp::moveSource(Common::CVector3 movement)
{
	/// Moving the original anechoic source
	Common::CVector3 newLocation = ISMHandler->getSourceLocation() + movement;
	Common::CTransform listenerTransform = listener->GetListenerTransform();
	Common::CVector3 listenerLocation = listenerTransform.GetPosition();
	ISMHandler->setSourceLocation(newLocation);
	Common::CTransform sourcePosition;
	sourcePosition.SetPosition(newLocation);
	anechoicSourceDSP->SetSourceTransform(sourcePosition);	
}

std::vector<shared_ptr<Binaural::CSingleSourceDSP>> ofApp::createImageSourceDSP()
{
	std::vector<shared_ptr<Binaural::CSingleSourceDSP>> tempImageSourceDSPList;
	std::vector<Common::CVector3> imageSourceLocationList = ISMHandler->getImageSourceLocations();
	

	for (int i = 0; i < imageSourceLocationList.size(); i++)
	{
		shared_ptr<Binaural::CSingleSourceDSP> tempSourceDSP = myCore.CreateSingleSourceDSP();								// Creating audio source
		Common::CTransform sourcePosition;
		sourcePosition.SetPosition(imageSourceLocationList.at(i));
		tempSourceDSP->SetSourceTransform(sourcePosition);							//Set source position
		tempSourceDSP->SetSpatializationMode(Binaural::TSpatializationMode::HighQuality);	// Choosing high quality mode for anechoic processing
		tempSourceDSP->DisableNearFieldEffect();											// Audio source will not be close to listener, so we don't need near field effect
		tempSourceDSP->EnableAnechoicProcess();											// Enable anechoic processing for this source
		tempSourceDSP->EnableDistanceAttenuationAnechoic();								// Do not perform distance simulation
		tempSourceDSP->EnablePropagationDelay();
		tempSourceDSP->DisableReverbProcess();
		tempImageSourceDSPList.push_back(tempSourceDSP);
	}
	return tempImageSourceDSPList;
}

std::vector<shared_ptr<Binaural::CSingleSourceDSP>> ofApp::reCreateImageSourceDSP()
{
	for (int i = 0; i < imageSourceDSPList.size(); i++)					//Revome old sourcesDSP
		myCore.RemoveSingleSourceDSP(imageSourceDSPList.at(i));
	imageSourceDSPList = createImageSourceDSP();						//Create new sourceDSP
	return imageSourceDSPList;
}

////////////////////////////////////////////////////////////////////////////////////////
//Methods for managing GUI 
////////////////////////////////////////////////////////////////////////////////////////

void ofApp::changeZoom(int &zoom) 
{
	scale = DEFAULT_SCALE * pow(1.1, zoom);
}

void ofApp::changeReflectionOrder(int &_reflectionOrder)
{
	if (setupDone == false) return;

	if (!stopState) systemSoundStream.stop();
	ISMHandler->setReflectionOrder(_reflectionOrder);
    imageSourceDSPList = reCreateImageSourceDSP();
	if (!stopState) systemSoundStream.start();
}

void ofApp::changeMaxDistanceImageSources(int &_maxDistanceSourcesToListener)
{
	if (setupDone == false) return;

	if (!stopState) systemSoundStream.stop();
		
	ISMHandler->setMaxDistanceImageSources(_maxDistanceSourcesToListener);
	numberOfSilencedFrames = ISMHandler->calculateNumOfSilencedFrames(_maxDistanceSourcesToListener);
	imageSourceDSPList = reCreateImageSourceDSP();
	if (!stopState) systemSoundStream.start();
}

void ofApp::recordIrOffline(bool &_active)
{
	recordingOffline = true;               
	boolRecordingIR = true;
	offlineRecordBuffers = 0;
	recordingPercent = 0.0f;
	offlineRecordIteration = 0;
	recordOfflineIRControl = false;
}

void ofApp::recordWavOffline(bool& _active)
{
	recordingOffline = true;               
	boolRecordingIR = false;
	offlineRecordBuffers = 0;
	recordingPercent = 0.0f;
	offlineRecordIteration = 0;
	recordOfflineWAVControl = false;
}

void ofApp::changeSecondsToRecordIR(int &_secondsToRecordIR)
{
	if (_secondsToRecordIR > 0 && _secondsToRecordIR <=MAX_SECONDS_TO_RECORD)
	   secondsToRecordIR = _secondsToRecordIR;
}

void ofApp::toogleHelpDisplay(bool &_active)
{
	boolToogleDisplayHelp = !boolToogleDisplayHelp;
}

void ofApp::toogleAboutDisplay(bool& _active)
{
	boolToogleDisplayAbout = !boolToogleDisplayAbout;
}

void ofApp::changeAudioToPlay(bool &_active)
{
	changeAudioToPlayControl = false;

	if (setupDone == false) return;
		
	resetAudio();

	//string pathData = ofToDataPath("", true);
	string pathData = ofToDataPath("", false);
	
	ofFileDialogResult openFileResult = ofSystemLoadDialog("Select an WAV file to Play");
	//Check if the user opened a file
	if (openFileResult.bSuccess) {
		ofFile file(openFileResult.getPath());
		ofLogVerbose("The file exists - now checking the type via file extension");
		string fileExtension = ofToUpper(file.getExtension());
		if (fileExtension == "WAV")
		{
			std::string pathData = openFileResult.getPath();
			char *charFilename = new char[pathData.length() + 1];
			strcpy(charFilename, pathData.c_str());
			source1Wav.resetSamplesVector();
			source1Wav.LoadWav(charFilename);
			cout << "Load new WAV File " << charFilename << endl << endl;
		}
		else
		{
			ofLogError() << "Extension must be WAV";
			if (!stopState) systemSoundStream.start();
			return;
		}
	}
	else {
		ofLogError() << "Couldn't load file";
		if (!stopState) systemSoundStream.start();
		return;
	}
	source1Wav.setInitialPosition();
	if (!stopState)  systemSoundStream.start();
}

void ofApp::resetAudio()
{
	if (!stopState) systemSoundStream.stop();
	lock_guard < mutex > lock(audioMutex);

	anechoicSourceDSP->ResetSourceBuffers();				  //Clean buffers

	for (int i = 0; i < imageSourceDSPList.size(); i++)
		imageSourceDSPList.at(i)->ResetSourceBuffers();
	environment->ResetReverbBuffers();
	
	myCore.RemoveEnvironment(environment);

	//Environment setup
	environment = myCore.CreateEnvironment();									// Creating environment to have reverberated sound
	environment->SetReverberationOrder(TReverberationOrder::ADIMENSIONAL);		// Setting number of ambisonic channels to use in reverberation processing
	string pathData = ofToDataPath("");
	string pathResources = ofToDataPath("resources");
	string fullPath = pathResources + "\\" + "brir.sofa";  //"hrtf.sofa"= pathFile;
	BRIR::CreateFromSofa(fullPath, environment);								// Loading SOFAcoustics BRIR file and applying it to the e
	
	// setup of the image sources
	imageSourceDSPList = reCreateImageSourceDSP();
}

void ofApp::playToStop(bool &_active)
{
	if (setupDone == false) return;
		
	if (!playToStopControl && !stopToPlayControl && !playState && stopState)
	{
		playToStopControl.set("Stop", true);
		stopToPlayControl.set("Play", false);
	}
	else if (playToStopControl && playState)
	{
		lock_guard < mutex > lock(audioMutex);	                  // Avoids race conditions with audio thread when cleaning buffers					
		systemSoundStream.stop();
		environment->ResetReverbBuffers();
		anechoicSourceDSP->ResetSourceBuffers();				  //Clean buffers

		imageSourceDSPList = reCreateImageSourceDSP();

		for (int i = 0; i < imageSourceDSPList.size(); i++)
			imageSourceDSPList.at(i)->ResetSourceBuffers();
		stopState = true;
		playState = false;
		playToStopControl.set("Stop", true);
		stopToPlayControl.set("Play", false);
	}
}

void ofApp::stopToPlay(bool &_active)
{
	if (setupDone == false) return;
		
	if (!playToStopControl && !stopToPlayControl && playState && !stopState)
	{
		playToStopControl.set("Stop", false);
		stopToPlayControl.set("Play", true);
	}
	else if (stopToPlayControl && stopState) {
		lock_guard < mutex > lock(audioMutex);	                  // Avoids race conditions with audio thread when cleaning buffers			
		stopState = false;
		playState = true;
		source1Wav.setInitialPosition();
		systemSoundStream.start();
		stopToPlayControl.set("Play", true);
		playToStopControl.set("Stop", false);
	}
}

void ofApp::changeRoomGeometry(bool &_active)
{
	if (!changeRoomGeometryControl)   
		return;                   
	else 
		changeRoomGeometryControl = false;
#if 1 
	if (!stopState) systemSoundStream.stop();

	ISM::RoomGeometry newRoom;

	//string pathData = ofToDataPath("", true);
	string pathData = ofToDataPath("", false);

	ofFileDialogResult openFileResult = ofSystemLoadDialog("Select an XML file with the new configuration of the room");
	//Check if the user opened a file
	if (openFileResult.bSuccess) {

	    ofFile file(openFileResult.getPath());
		ofLogVerbose("The file exists - now checking the type via file extension");
		string fileExtension = ofToUpper(file.getExtension());
		if (fileExtension == "XML")
		{
			string pathData = openFileResult.getPath();
			//	string fileName = openFileResult.getName();
			if (!xml.load(pathData))
			{
				ofLogError() << "Couldn't load file";
				if (!stopState) systemSoundStream.start();
				return;
			}
		}
		else
		{
			ofLogError() << "Extension must be XML";
			if (!stopState) systemSoundStream.start();
			return;
		}

	}
	else {
		ofLogError() << "Couldn't load file";
		if (!stopState) systemSoundStream.start();
		return;
	}


		/////////////Read the XML file with the geometry of the room and absorption of the walls////////

		// select all corners and iterate through them
	auto cornersXml = xml.find("//ROOMGEOMETRY/CORNERS");
	if (cornersXml.empty()) {
		ofLogError() << "The file is not a room configuration";
		if (!stopState) systemSoundStream.start();
		return;
	}

	for (auto & currentCorner : cornersXml) {
		// for each corner in the room insert its coordinates
		auto cornersInFile = currentCorner.getChildren("CORNER");

		for (auto aux : cornersInFile) {
			std::string p3Dstr = aux.getAttribute("_3Dpoint").getValue();
			std::vector<float> p3Dfloat = parserStToFloat(p3Dstr);
			Common::CVector3 tempP3d;
			tempP3d.x = p3Dfloat[0];
			tempP3d.y = p3Dfloat[1];
			tempP3d.z = p3Dfloat[2];
			newRoom.corners.push_back(tempP3d);
		}
	}

	/***********************/
	absortionsWalls.clear();
	/***********************/

	// select all walls and iterate through them
	auto wallsXml = xml.find("//ROOMGEOMETRY/WALLS");
	
	for (auto & currentWall : wallsXml) {
		// for each wall in the room insert corners its and absortions
		auto wallsInFile = currentWall.getChildren("WALL");
		for (auto aux : wallsInFile) {
			std::string strVectInt = aux.getAttribute("corner").getValue();
			std::vector<int> tempCornersWall = parserStToVectInt(strVectInt);
			newRoom.walls.push_back(tempCornersWall);
			std::string strVectFloat = aux.getAttribute("absor").getValue();
			std::vector<float> tempAbsorsWall = parserStToFloat(strVectFloat);
			absortionsWalls.push_back(tempAbsorsWall);
		}
	}
	////////////////////////////////////////////////
	ISMHandler->setupArbitraryRoom(newRoom);

	int numWalls = ISMHandler->getRoom().getWalls().size();
	guiActiveWalls.resize(numWalls);

	for (int i = 0; i < numWalls; i++)
	{
		guiActiveWalls.at(i) = true;
	}

	//Absortion as vector
	ISMHandler->setAbsortion((std::vector<std::vector<float>>)  absortionsWalls);

	//////////////////////////////////
	Common::CVector3 roomCenter = ISMHandler->getRoom().getCenter();

	Common::CVector3 listenerLocation(roomCenter);
	Common::CTransform listenerPosition = Common::CTransform();
	listenerPosition.SetPosition(listenerLocation);
	listener->SetListenerTransform(listenerPosition);

	imageSourceDSPList = reCreateImageSourceDSP();

	mainRoom = ISMHandler->getRoom();

	if (!stopState) systemSoundStream.start();
#endif
}

void ofApp::toggleWall(bool &_active)
{
	refreshActiveWalls();
}

void ofApp::toggleAnechoic(bool &_active)
{
	if (stateAnechoicProcess)
	{
		anechoicSourceDSP->DisableAnechoicProcess();
		stateAnechoicProcess = false;
	}
	else
	{
		anechoicSourceDSP->EnableAnechoicProcess();
		stateAnechoicProcess = true;
	}
}

void ofApp::changeHRTF(bool& _active)
{
	changeHRTFControl = false;
	if (setupDone == false) return;

	if (!stopState) systemSoundStream.stop();
	
	string pathData = ofToDataPath("", false);

	ofFileDialogResult openFileResult = ofSystemLoadDialog("Select an SOFA file with the new HRTF");
	//Check if the user opened a file
	if (openFileResult.bSuccess) {
		ofFile file(openFileResult.getPath());
		ofLogVerbose("The file exists - now checking the type via file extension");
		string fileExtension = ofToUpper(file.getExtension());
		if (fileExtension == "SOFA")
		{
			string pathData = openFileResult.getPath();
			char* charFilename = new char[pathData.length() + 1];
			strcpy(charFilename, pathData.c_str());
			bool specifiedDelays;
			bool sofaLoadResult = HRTF::CreateFromSofa(pathData, listener, specifiedDelays);

			if (!sofaLoadResult) {
				cout << "ERROR: Error trying to load the SOFA file" << endl << endl;
				if (!stopState) systemSoundStream.start();
				return;
			}
			else
			{
				cout << "Load new HRTF File " << pathData << endl  << endl;
			}
		}
		else
		{
			ofLogError() << "Extension must be SOFA";
			if (!stopState) systemSoundStream.start();
			cout << "Load new HRTF File " << pathData << endl << endl;
			return;
		}
	}
	else 
	{
		ofLogError() << "Couldn't load file";
		if (!stopState) systemSoundStream.start();
		return;
	}
	
	if (!stopState) systemSoundStream.start();
}

void ofApp::toggleBinauralSpatialisation(bool& _active)
{

	if (setupDone == false)
	{
		stateBinauralSpatialisation = true;
		return;
	}
		

	if (stateBinauralSpatialisation)
	{
		anechoicSourceDSP->SetSpatializationMode(Binaural::TSpatializationMode::NoSpatialization);
		for (int i = 0; i < imageSourceDSPList.size(); i++)
			imageSourceDSPList.at(i)->SetSpatializationMode(Binaural::TSpatializationMode::NoSpatialization);

		stateBinauralSpatialisation = false;
	}
	else
	{
		anechoicSourceDSP->SetSpatializationMode(Binaural::TSpatializationMode::HighQuality);
		for (int i = 0; i < imageSourceDSPList.size(); i++)
			imageSourceDSPList.at(i)->SetSpatializationMode(Binaural::TSpatializationMode::HighQuality);

		stateBinauralSpatialisation = true;
	}

}



void ofApp::toggleReverb(bool &_active)
{
	if (bDisableReverb) bDisableReverb = false;
	else bDisableReverb = true;
	if (!stopState) systemSoundStream.stop();
	anechoicSourceDSP->ResetSourceBuffers();				//Clean buffers

	imageSourceDSPList = reCreateImageSourceDSP();

	for (int i = 0; i < imageSourceDSPList.size(); i++)
		imageSourceDSPList.at(i)->ResetSourceBuffers();
	environment->ResetReverbBuffers();
	if (!stopState) systemSoundStream.start();
}

void ofApp::refreshActiveWalls()
{
	if (!stopState) systemSoundStream.stop();
	Common::CTransform listenerTransform = listener->GetListenerTransform();
	Common::CVector3 listenerLocation = listenerTransform.GetPosition();
	for (int i = 0; i < guiActiveWalls.size(); i++)
	{
		if (guiActiveWalls.at(i))
		{
			ISMHandler->enableWall(i);
		}
		else
		{
			ISMHandler->disableWall(i);
		}
	}
	mainRoom = ISMHandler->getRoom();

	imageSourceDSPList = reCreateImageSourceDSP();

	if (!stopState) systemSoundStream.start();
}


//////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////

std::vector<float> ofApp::parserStToFloat(const std::string & _st)
{
	std::vector<float> aux;
	if (_st.empty()) return aux;

	std::string st = _st;

	auto pos = st.find(",");
	while (pos != string::npos) {
		float val = std::stof(st.substr(0, pos));
		aux.push_back(val);
		st.erase(0, pos+1);
		pos = st.find(",");
	}
	float val = std::stof(st);
	aux.push_back(val);
	return aux;
}

std::vector<int> ofApp::parserStToVectInt(const std::string & _st)
{
	std::vector<int> aux;
	if (_st.empty()) return aux;

	std::string st = _st;

	auto pos = st.find(",");
	while (pos != string::npos) {
		int val = std::stoi(st.substr(0, pos));
		aux.push_back(val);
		st.erase(0, pos + 1);
		pos = st.find(",");
	}
	int val = std::stoi(st);
	aux.push_back(val);
	return aux;
}



//////////////////////////
// Record to WAV functions
//////////////////////////
void ofApp::OfflineWavRecordOneLoopIteration(int _bufferSize)
{
	Common::CEarPair<CMonoBuffer<float>> recordBuffer;               
	recordBuffer.left.resize(_bufferSize);
	recordBuffer.right.resize(_bufferSize);
	audioProcess(recordBuffer, _bufferSize);
	wavWriter.AppendToFile(recordBuffer);
	//offlineRecordBuffers++;
}

void ofApp::ShowRecordingMessage()
{
	float windowWidth = ofGetWidth();
	float windowHeight = ofGetHeight();
	float panelOpac = 140;
	float border = 5;
	float panelWidth = 300;
	float panelHeight = 80;
	float frameWidth = 2;

	bool centerOnListenerPanel = true;
	//float x;
	//if (centerOnListenerPanel)  x = (windowWidth - IPL_WIDTH - IM.GetRightPanelWidth() - panelWidth) / 2 + IPL_WIDTH;
	//else                        
	float x = (windowWidth - panelWidth) / 2;
	float y = (windowHeight - panelHeight) / 2;

	ofPushMatrix();
	ofEnableAlphaBlending();
	ofFill();

	ofSetColor(0, 0, 0, 128);
	ofDrawRectangle(0, 0, windowWidth, windowHeight);

	ofSetColor(255, 255, 255, panelOpac);
	ofDrawRectangle(x, y, panelWidth, panelHeight);

	ofSetColor(0, 0, 0, panelOpac);
	ofDrawRectangle(x + frameWidth, y + frameWidth, panelWidth - 2 * frameWidth, panelHeight - 2 * frameWidth);

	ofNoFill();
	ofDisableAlphaBlending();

	ofSetColor(255, 255, 255);

	char recordPercentStr[30];
	snprintf(recordPercentStr, 30, "Recording to disk...%.1f%%", recordingPercent);
	ofDrawBitmapString(recordPercentStr, x + panelWidth / 4 - 15, y + panelHeight / 2 + 6);

	ofPopMatrix();
}

void ofApp::OfflineWavRecordEndLoop()
{
	StopWavRecord();	// Reset clip positions	
	recordingOffline = false;
}

void ofApp::StartWavRecord(string filename, int bitspersample)
{
	int sampleRate = myCore.GetAudioState().sampleRate;
	wavWriter.Setup(2, sampleRate, bitspersample);
	if (!wavWriter.CreateWavFile(filename)) {
		cout << "ERROR: Unable to record WAV file" << endl << endl;
	}
	else {
		cout << "FILE: "<< filename << "open" << endl << endl;
	}
}

void ofApp::EndWavRecord()
{
	wavWriter.CloseFile();
}


void ofApp::StopWavRecord()
{
	lock_guard < mutex > lock(audioMutex);	 // Avoids race conditions with audio thread when cleaning buffers

	if (wavWriter.IsWriting())
		EndWavRecord();

	environment->ResetReverbBuffers();				//Clean reverb buffers
}

int ofApp::OfflineWavRecordStartLoop(unsigned long long durationInMilliseconds)
{
	// Convert milliseconds into number of samples (OF_KEY_F10)
	unsigned long long durationInSamples;
	int sampleRate = myCore.GetAudioState().sampleRate;
	durationInSamples = (sampleRate * durationInMilliseconds) / 1000;	// might be rounded

	// Convert number of samples into number of buffers
	int numberOfBuffers = ceil(durationInSamples / myCore.GetAudioState().bufferSize);	// rounded up
	//int numberOfBuffers = floor(durationInSamples / myCore.GetAudioState().bufferSize);	// rounded down

	offlineRecordIteration = 0;

	// Reset progress percentage
	recordingPercent = 0.0f;

	return numberOfBuffers;
}


void ofApp::StopSystemSoundStream()
{
	if (systemSoundStream_Started)
	{
		systemSoundStream_Started = false;
		systemSoundStream.stop();
	}
}
//---------------------------------------------------------------
void ofApp::StartSystemSoundStream()
{
	if (!systemSoundStream_Started)
	{
		systemSoundStream_Started = true;
		systemSoundStream.start();
	}
}


void ofApp::ShowRecordingDurationTime() {
	/*auto duration = std::chrono::duration_cast<std::chrono::seconds>(stopRecordingOfflineTime - startRecordingOfflineTime);
	std::cout << "Time taken to do the recording offline: "	<< duration.count() << " seconds" << endl;*/
	
	auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(stopRecordingOfflineTime - startRecordingOfflineTime);
	std::cout << "Time taken to do the recording offline: " << duration.count() << " milliseconds" << endl;
}