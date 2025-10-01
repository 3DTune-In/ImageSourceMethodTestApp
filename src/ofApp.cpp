#include "ofApp.h"

#define USE_PROFILER
#ifdef USE_PROFILER
#include <Windows.h>
#include "Common/Profiler.h"
//CProfilerDataSet dsAudioLoop;
Common::CProfilerDataSet dsProcessFrameTime;
Common::CProfilerDataSet dsProcessAnechoicTime;
Common::CProfilerDataSet dsProcessReverbTime;
Common::CProfilerDataSet dsProcessISMTime;

Common::CTimeMeasure startOfflineRecord;
#endif
#include <filesystem>


#define SOURCE_STEP 0.02f
#define LISTENER_STEP 0.01f
#define MAX_REFLECTION_ORDER 40
#define MAX_DIST_SILENCED_FRAMES 100          //meters
#define MIN_DIST_SILENCED_FRAMES 1           //meters
#define INITIAL_DIST_SILENCED_FRAMES 3.43     //meters
#define MAX_SECONDS_TO_RECORD 30

#define MAX_WIN_SLOPE 50                      //mseg
#define MIN_WIN_SLOPE 2                       //mseg
#define INITIAL_WIN_SLOPE 2                   //mseg
#define MIN_WIN_THRESHOLD 2.92                //mseg


//--------------------------------------------------------------
// TODO Separate all the code within this setup method into several methods
void ofApp::setup() {
	
	setupDone = false;
	
	stateAnechoicProcess = true;
	stateBinauralSpatialisation = true;
	stateISMProcess = false;	
	stateDistanceAttenuationAnechoic = true;
	stateDistanceAttenuationReverb = false;	
	stateBRIRReverbProcess = false;

	recordingFolder = RECORD_FOLDER;
	
	// SETUP PROFILER
#ifdef USE_PROFILER
	Common::PROFILER3DTI.InitProfiler();
	Common::PROFILER3DTI.SetAutomaticWrite(dsProcessFrameTime, "PROFILLING_APP_ProcessAll.txt");
	Common::PROFILER3DTI.SetAutomaticWrite(dsProcessAnechoicTime, "PROFILLING_APP_ProcessAnechoic.txt");
	Common::PROFILER3DTI.SetAutomaticWrite(dsProcessReverbTime, "PROFILLING_APP_ProcessReverb.txt");
	Common::PROFILER3DTI.SetAutomaticWrite(dsProcessISMTime, "PROFILLING_APP_ProcessISM.txt");

	Common::PROFILER3DTI.StartRelativeSampling(dsProcessFrameTime);
	Common::PROFILER3DTI.StartRelativeSampling(dsProcessAnechoicTime);
	Common::PROFILER3DTI.StartRelativeSampling(dsProcessReverbTime);
	Common::PROFILER3DTI.StartRelativeSampling(dsProcessISMTime);	
#endif

	// Core setup
	Common::TAudioStateStruct audioState;	                            // Audio State struct declaration	
	audioState.bufferSize = BUFFERSIZE;			                        // Setting buffer size 
	audioState.sampleRate = SAMPLERATE;						   			// Setting frame rate 
	myCore.SetAudioState(audioState);									// Applying configuration to core
	myCore.SetHRTFResamplingStep(15);								    // Setting 15-degree resampling step for HRTF

	// Listener setup
	listener = myCore.CreateListener();								 // First step is creating listener
	//Common::CVector3 listenerLocation(0, 0, 0.15);                 // Juntas_ROOM
	Common::CVector3 listenerLocation(-0.45, 0.02, -0.68);           // A108_ROOM
	//Common::CVector3 listenerLocation(-2.4, -1.5, -0.8);           // LAB_ROOM
	//Common::CVector3 listenerLocation(-1.5, 2.4, -0.8);            // LAB_ROOM_ROT
	Common::CTransform listenerPosition = Common::CTransform();		 // Setting listener in (0,0,0)
	listenerPosition.SetPosition(listenerLocation);
	listener->SetListenerTransform(listenerPosition);
		
	listener->DisableCustomizedITD();								 // Disabling custom head radius
	
	// Paths setup
	std::string pathData = ofToDataPath("");
	std::string pathResources = ofToDataPath("resources");	
	
	// HRTF setup
	bool result = LoadHRTFSofa(pathResources); //TODO check samplerate
	if (!result) return;
	
	// Environment setup
	result = LoadBRIRSofa(pathResources); //TODO check samplerate
	if (!result) return;
	int BRIRLength = environment->GetBRIR()->GetBRIRLength();
	float sampleRate = myCore.GetAudioState().sampleRate;
	float secToRecordIR = ((float)BRIRLength) / sampleRate;
	changeSecondsToRecordIR(secToRecordIR);			
	
	// Room setup	
	SetupRoom(pathResources);
		
	// Load wav file
	result =SetupAudioFile(pathResources, audioState.sampleRate);           // Loading .wav file
	if (!result) return;

	// Anechoic Source Setup
	//Common::CVector3 initialLocation(2.0, 0.0, 0.15);             // Juntas_ROOM
	Common::CVector3 initialLocation(1.55, 0.02, -0.68);            // A108_ROOM	
	//Common::CVector3 initialLocation(-2.4, -0.3, -0.8);           // LAB_ROOM
	//Common::CVector3 initialLocation(-0.3, 2.4, -0.8);            // LAB_ROOM_ROT	
	anechoicSourceDSP = myCore.CreateSingleSourceDSP();				// Creating audio source
	Common::CTransform sourcePosition;
	sourcePosition.SetPosition(initialLocation);
	anechoicSourceDSP->SetSourceTransform(sourcePosition);							//Set source position
	anechoicSourceDSP->SetSpatializationMode(Binaural::TSpatializationMode::HighQuality);	// Choosing high quality mode for anechoic processing
	anechoicSourceDSP->DisableNearFieldEffect();											// Audio source will not be close to listener, so we don't need near field effect	
	anechoicSourceDSP->EnableAnechoicProcess();										// Disable anechoic processing for this source
		
	// DistanceAttenuation	
	anechoicSourceDSP->DisableDistanceAttenuationReverb();	
	anechoicSourceDSP->EnablePropagationDelay();
	

	///// HYBRID REVERB setup - croosfade window setup	
	
	// Setup maxDistanceSourcesToListener and numberOfSilencedFrames
	currentMaxDistanceSourcesToListener = INITIAL_DIST_SILENCED_FRAMES;
	numberOfSilencedSamplesInBRIR = meters2samples(currentMaxDistanceSourcesToListener);
	// Setup windowThreshold and windowSlope	   
	currentWindowSlopeWidth = INITIAL_WIN_SLOPE;
	
		
	if (numberOfSilencedSamplesInBRIR + millisec2samples(currentWindowSlopeWidth) /2 > BRIRLength)
	{
		numberOfSilencedSamplesInBRIR = BRIRLength - millisec2samples(currentWindowSlopeWidth) /2;
		currentMaxDistanceSourcesToListener = samples2meters(numberOfSilencedSamplesInBRIR);
		//maxDistanceImageSourcesToListenerControl.set (maxDistanceSourcesToListener);
		//ISMHandler->setMaxDistanceImageSources(maxDistanceSourcesToListener, millisec2meters(windowSlopeWidth));
	}
	// Setup windowThreshold
	currentWindowThreshold = meters2millisec(currentMaxDistanceSourcesToListener);
	//float windowThresholdBRIR = float(numberOfSilencedSamplesInBRIR) / (float)myCore.GetAudioState().sampleRate;	
	//float windowThreshold = meters2secs(maxDistanceSourcesToListener); 
	reverbGainLinear = 1.0;
	SetEnvironmentFadeInWindow(currentMaxDistanceSourcesToListener);
	

	// ISM setup
	//ISMHandler = std::make_shared<ISM::CISM>(&myCore);		// Initialize ISM	
	//ISMHandler->setReflectionOrder(0);
	//ISMHandler->enableStaticDistanceCriterion();	// enable static distance criterion in order to reduce the number of potential sources			
	//ISMHandler->setSourceLocation(initialLocation);	// Source to be rendered
	//ISMHandler->setMaxDistanceImageSources(currentMaxDistanceSourcesToListener, millisec2meters((float)INITIAL_WIN_SLOPE));		
	//ISMHandler->SetupRoom(mainRoom);			
									   
	//AudioDevice Setup
	//// Before getting the devices list for the second time, the strean must be closed. Otherwise,
	//// the app crashes when audioInterfaceController->StartAudioInterface(); or stop() are called.
	//systemSoundStream.close();
	//SetDeviceAndAudio(audioState);
	audioInterfaceController = std::make_shared<CAudioInterfaceController>(std::bind(&ofApp::ShowMessage, this, std::placeholders::_1));
	audioInterfaceController->Setup(this, audioState.sampleRate, audioState.bufferSize, 4);
	
	//The system starts its execution in STOP mode
	playState = false;
	stopState = true;

	//audioInterfaceController->StopAudioInterface();
	// GUI setup
	GuiSetup(pathResources, secToRecordIR);
	
	// Setup active walls in GUI
	int numWalls = mainRoom.getWalls().size();
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

	numberIRScan = 0;

	// Profilling
	profilling = false;
	setupDone = true;

	// INIT ISM
	currentReflectionOrder = INITIAL_REFLECTION_ORDER;
	//ISMHandler->setReflectionOrder(currentReflectionOrder);
					
	ISMHandler2 = std::make_shared<ISM::CISM2>(&myCore);		// Initialize ISM
	ISMHandler2->enableStaticDistanceCriterion();
	ISMHandler2->setSourceLocation(initialLocation);		
	ISMHandler2->Setup(currentReflectionOrder, currentMaxDistanceSourcesToListener, millisec2meters(currentWindowSlopeWidth), mainRoom);
		
	// setup of the image sources
	createImageSourceDSP();
	
	
	// OSC
	oscManager.Setup(OSC_DEFAULT_TARGET_PORT, OSC_DEFAULT_TARGET_IP, OSC_DEFAULT_LISTEN_PORT, std::bind(&ofApp::OscCallback, this, std::placeholders::_1));	
	changeFileFromOSC = false;
}

bool ofApp::SetupAudioFile(const std::string& _pathResources, const int& sampleRate)
{
	std::string fullPath;
	if (sampleRate == 44100){
		fullPath = _pathResources + "\\" + AUDIO_FILE_FEMALE_44100;
	}
	else if (sampleRate == 48000)
	{
		fullPath = _pathResources + "\\" + AUDIO_FILE_FEMALE_48000;
	}
	else {
		//ERROR
		return false;
	}	
	const char* _filePath = fullPath.c_str();
	return LoadWavFile(source1Wav, _filePath);
}

bool ofApp::LoadWavFile(SoundSource& source, const char* filePath)
{
	if (!source.LoadWav(filePath)) {
		cout << "ERROR: file " << filePath << " doesn't exist." << endl << endl;
		return false;
	}
	return true;
}

void ofApp::SetEnvironmentFadeInWindow(float & _maxDistanceSourcesToListener)
{	
	float windowThreshold = meters2secs(_maxDistanceSourcesToListener);
	environment->SetFadeInWindow(windowThreshold, currentWindowSlopeWidth * 0.001, reverbGainLinear);
	numberOfSilencedFrames = floor((numberOfSilencedSamplesInBRIR - currentWindowSlopeWidth / 2) / myCore.GetAudioState().bufferSize);
}

void ofApp::GuiSetup(const std::string& pathResources, float& secToRecordIR)
{
	//GUI setup
	logoUMA.loadImage(pathResources + "\\" + "UMA.png");
	logoUMA.resize(logoUMA.getWidth() / 10, logoUMA.getHeight() / 10);
	titleFont.load(pathResources + "\\" + "Verdana.ttf", 32);
	logoSAVLab.loadImage(pathResources + "\\" + "SAVLab.png");
	logoSAVLab.resize(logoSAVLab.getWidth() / 14, logoSAVLab.getHeight() / 14);
	logoSONICOM.loadImage(pathResources + "\\" + "SONICOM.png");
	logoSONICOM.resize(logoSONICOM.getWidth() / 19, logoSONICOM.getHeight() / 19);

	leftPanel.disableHeader();
	leftPanel.setup(pathResources + "\\", "config.xml", 20, 150);
	leftPanel.setWidthElements(220);
	
	leftPanel.add(sectionLabel1.set("- GENERAL CONFIG -"));

	zoom.addListener(this, &ofApp::changeZoom);
	leftPanel.add(zoom.setup("Zoom (Pg. up/down)", 0, -20, 20, 50, 15));

	audioInterfaceControl.addListener(this, &ofApp::ChangeAudioDevice);
	leftPanel.add(audioInterfaceControl.set("Change Audio Device"));
			
	leftPanel.add(sectionLabel2.set("- RENDERING PARAMETERS -"));

	anechoicEnableControl.addListener(this, &ofApp::toggleAnechoic);
	leftPanel.add(anechoicEnableControl.set("Direct Path", stateAnechoicProcess));

	binauralSpatialisationEnableControl.addListener(this, &ofApp::toggleBinauralSpatialisation);
	leftPanel.add(binauralSpatialisationEnableControl.set("Binaural spatialisation", stateBinauralSpatialisation));

	ismEnableControl.addListener(this, &ofApp::toggleISM);
	leftPanel.add(ismEnableControl.set("ISM", stateISMProcess));

	reverbEnableControl.addListener(this, &ofApp::toggleReverb);
	leftPanel.add(reverbEnableControl.set("REVERB", stateBRIRReverbProcess));

	reverbGainControl.addListener(this, &ofApp::changeReverbGain);
	leftPanel.add(reverbGainControl.set("ReverbGain (dB)", 0, -40, 40));
	
	leftPanel.add(sectionLabel3.set("- ISM PARAMETERS -"));

	reflectionOrderControl.addListener(this, &ofApp::changeReflectionOrder);
	leftPanel.add(reflectionOrderControl.set("Relection Order (+/-)", INITIAL_REFLECTION_ORDER, 0, MAX_REFLECTION_ORDER));

	maxDistanceImageSourcesToListenerControl.addListener(this, &ofApp::changeMaxDistanceImageSources);
	leftPanel.add(maxDistanceImageSourcesToListenerControl.set("Max Distance (m)", currentMaxDistanceSourcesToListener, MIN_DIST_SILENCED_FRAMES, MAX_DIST_SILENCED_FRAMES));
	
	winThresholdControl.addListener(this, &ofApp::changeWinThreshold);	
	leftPanel.add(winThresholdControl.set("WinThreshold (ms)"
		, currentWindowThreshold
		, (MIN_DIST_SILENCED_FRAMES * 1000) / myCore.GetMagnitudes().GetSoundSpeed()
		, (MAX_DIST_SILENCED_FRAMES * 1000) / myCore.GetMagnitudes().GetSoundSpeed()));				
		
	windowSlopeControl.addListener(this, &ofApp::changeWindowSlope);
	leftPanel.add(windowSlopeControl.set("WinSlople (ms)", INITIAL_WIN_SLOPE, MIN_WIN_SLOPE, MAX_WIN_SLOPE));		

	leftPanel.add(sectionLabel4.set("- PLAYBACK CONTROLS -"));

	stopToPlayControl.addListener(this, &ofApp::stopToPlay);
	leftPanel.add(stopToPlayControl.set("Play", false));

	playToStopControl.addListener(this, &ofApp::playToStop);
	leftPanel.add(playToStopControl.set("Stop", true));

	numberOfSecondsToRecordControl.addListener(this, &ofApp::changeSecondsToRecordIR);
	leftPanel.add(numberOfSecondsToRecordControl.set("IR record lenght (s)", secToRecordIR, 0.2, MAX_SECONDS_TO_RECORD));

	recordOfflineIRControl.addListener(this, &ofApp::recordIrOffline);
	leftPanel.add(recordOfflineIRControl.set("Save IR", false));

	recordOfflineWAVControl.addListener(this, &ofApp::recordWavOffline);
	leftPanel.add(recordOfflineWAVControl.set("Record (offline)", false));

	leftPanel.add(sectionLabel5.set("- OTHERS -"));

	changeAudioToPlayControl.addListener(this, &ofApp::changeAudioToPlay);
	leftPanel.add(changeAudioToPlayControl.set("Load audio", false));

	changeRoomGeometryControl.addListener(this, &ofApp::changeRoomGeometry);
	leftPanel.add(changeRoomGeometryControl.set("Load room", false));

	changeHRTFControl.addListener(this, &ofApp::changeHRTF);
	leftPanel.add(changeHRTFControl.set("Load HRTF", false));

	changeBRIRControl.addListener(this, &ofApp::changeBRIR);
	leftPanel.add(changeBRIRControl.set("Load BRIR", false));

	helpDisplayControl.addListener(this, &ofApp::toogleHelpDisplay);
	leftPanel.add(helpDisplayControl.set("Help", false));

	aboutDisplayControl.addListener(this, &ofApp::toogleAboutDisplay);
	leftPanel.add(aboutDisplayControl.set("About", false));
}

bool ofApp::LoadHRTFSofa(const std::string& pathResources)
{
	// HRTF can be loaded in SOFA (more info in https://sofacoustics.org/) Some examples of HRTF files can be found in 3dti_AudioToolkit/resources/HRTF
	std::string fullPath = pathResources + "\\HRTF\\" + "HRTF_SADIE_II_D1_48K_24bit_256tap_FIR_SOFA_aligned.sofa";
	//string fullPath = pathResources + "\\" + "Sala108_listener1_sourceQuad_2m_48kHz_Omnidirectional_direct_path.sofa";
	//string fullPath = pathResources + "\\" + "SalaJuntasTeleco_listener1_sourceQuad_2m_48kHz_Omnidirectional_direct_path.sofa";
	//string fullPath = pathResources + "\\" + "D1_44K_16bit_256tap_FIR_SOFA.sofa";
	//string fullPath = pathResources + "\\" + "3DTI_HRTF_D2_128s_44100Hz.sofa";       //"hrtf.sofa"= pathFile;
	//string fullPath = pathResources + "\\" + "UMA_NULL_S_HRIR_512.sofa";             // To test the Filterbank
	fullPathHRTF = fullPath;

	bool specifiedDelays;
	bool sofaLoadResult = HRTF::CreateFromSofa(fullPath, listener, specifiedDelays);
	if (!sofaLoadResult) {
		std::cout << "ERROR: Error trying to load the SOFA file - " << fullPath << endl << endl;
	}
	else {
		std::cout << "HRTF SOFA file loaded correctly - "<< fullPath << endl << endl;
	}

	return sofaLoadResult;
}

/**
 * @brief 
 * @param pathResources 
 * @return 
 */
bool ofApp::LoadBRIRSofa(const std::string& pathResources)
{
	/************************/
	// Environment setup
	reverberationOrder = BIDIMENSIONAL;
	environment = myCore.CreateEnvironment();									// Creating environment to have reverberated sound
	environment->SetReverberationOrder(reverberationOrder);		// Setting number of ambisonic channels to use in reverberation processing
	
	std::string fullPath;
	//fullPath = pathResources + "\\" + "lab138_3_KU100_reverb_120cm_adjusted_44100.sofa";                      // LAB_ROOM 
	fullPath = pathResources + "\\BRIR\\" + "Sala108_listener1_sourceQuad_2m_48kHz_reverb_adjusted.sofa";             // A108_ROOM 
	//fullPath = pathResources + "\\" + "SalaJuntasTeleco_listener1_sourceQuad_2m_48kHz_reverb_adjusted.sofa";  // Juntas_ROOM
	//fullPath = pathResources + "\\" + "Sala108_listener1_sourceQuad_2m_48kHz_Omnidirectional_reverb.sofa";       
	//fullPath = pathResources + "\\" + "SalaJuntasTeleco_listener1_sourceQuad_2m_48kHz_Omnidirectional_reverb.sofa";   

	fullPathBRIR = fullPath;

	bool result = BRIR::CreateFromSofa(fullPath, environment);		// Loading SOFAcoustics BRIR file and applying it to the environment
	if (!result) {
		std::cout << "ERROR: Error trying to load the BRIR SOFA file - " << fullPath << endl << endl;		
	}
	else {
		std::cout << "BRIR SOFA file loaded correctly - " << fullPath << endl << endl;
	}
	return result;
}

void ofApp::SetupRoom(const std::string& pathResources/*, ISM::RoomGeometry& trapezoidal*/)
{
	ISM::RoomGeometry trapezoidal;
	std::string fullPath;
	/////////////Read the XML file with the geometry of the room and absorption of the walls////////	 	
	//fullPath = pathResources + "\\" + "Juntas_room_Ini.xml";            // Juntas_ROOM
	fullPath = pathResources + "\\Room\\" + "A108_room_Ini.xml";            // A108_ROOM
	//fullPath = pathResources + "\\" + "lab_room_Ini_Izq.xml";       // LAB_ROOM
	//fullPath = pathResources + "\\" + "lab_room_Ini_Rot.xml";       // LAB_ROOM_ROT

	if (!xml.load(fullPath))
	{
		ofLogError() << "Couldn't load file";
		return;
	}
	std::cout << "Room geometry file loaded correctly - " << fullPath << endl << endl;
	// select all corners and iterate through them
	auto cornersXml = xml.find("//ROOMGEOMETRY/CORNERS");
	for (auto& currentCorner : cornersXml) {
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
	std::vector<std::vector<float>> absortionsWalls;
	for (auto& currentWall : wallsXml) {
		// for each wall in the room insert corners its and absortions
		auto wallsInFile = currentWall.getChildren("WALL");
		for (auto aux : wallsInFile) {
			std::string strVectInt = aux.getAttribute("corner").getValue();
			std::vector<int> tempCornersWall = parserStToVectInt(strVectInt);
			trapezoidal.walls.push_back(tempCornersWall);

			std::string strVectFloat = aux.getAttribute("absor").getValue();
			std::vector<float> tempAbsorsWall = parserStToFloat(strVectFloat);
			absortionsWalls.push_back(tempAbsorsWall);
		}
	}

	mainRoom.setupRoomGeometry(trapezoidal);
	mainRoom.setWallAbsortion((std::vector<std::vector<float>>)  absortionsWalls);
}


//--------------------------------------------------------------
void ofApp::update() {
	// OSC
	oscManager.ReceiveOSCCommand();
}

//--------------------------------------------------------------
void ofApp::draw() {
		
	if (recordingOffline)											//OF_KEY_F9 (OFFLINE WAV RECORD)
	{
		return DrawRecordingOffline();
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


	int ordReflectDraw = reflectionOrderControl;
	drawRoom(mainRoom, std::min(ordReflectDraw, 3), 255);

	//draw lisener
	Common::CTransform listenerTransform = listener->GetListenerTransform();
	Common::CVector3 listenerLocation = listenerTransform.GetPosition();
	ofSphere(listenerLocation.x, listenerLocation.y, listenerLocation.z, 0.09);						//draw listener

	Common::CVector3 axis, nose; 	
	float angle;
	Common::CQuaternion QListener = listenerTransform.GetOrientation();
	QListener.ToAxisAngle(axis, angle);
	if (angle < 0.000001) {
		nose.x = listenerLocation.x + axis.x;
		nose.y = listenerLocation.y + axis.y;
		nose.z = listenerLocation.z + axis.z;
	}
	else {
		float yaw, pitch, roll;
		QListener.ToYawPitchRoll(yaw, pitch, roll);
		nose.x = listenerLocation.x + cos (yaw);
		nose.y = listenerLocation.y - sin (yaw);
		nose.z = listenerLocation.z;
	}
	ofLine(listenerLocation.x, listenerLocation.y, listenerLocation.z,
		nose.x, nose.y, nose.z);

	//draw anechoic source
	ofPushStyle();
	ofSetColor(255, 50, 200, 50);

	if (stateAnechoicProcess)
	{
		Common::CVector3 sourceLocation = ISMHandler2->getSourceLocation();
		ofBox(sourceLocation.x, sourceLocation.y, sourceLocation.z, 0.2);								//draw anechoic source
		ofLine(sourceLocation.x, sourceLocation.y, sourceLocation.z,
			listenerLocation.x, listenerLocation.y, listenerLocation.z);								//draw ray from anechoic source
	}

	int numberOfVisibleImages = 0;
	std::vector<ISM::ImageSourceData> imageSourceDataList = ISMHandler2->getImageSourceData();
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
		std::string titleText = "Image Source Method Simulator " + APP_VERSION;
		sprintf(title, titleText.data()) ;
	}
	else
	{
		std::string titleText = "ISM Simulator " + APP_VERSION;
		sprintf(title, titleText.data());
	}
	titleFont.drawString(title, ofGetWidth() / 2 - titleFont.stringWidth(title) / 2, 85);

	/// Logo of the SAVLab project
	logoSAVLab.draw(ofGetWidth() - 260, 20);
	/// Logo of the SONICOM project
	logoSONICOM.draw(ofGetWidth() - 250, 100);
	/// This work has been partially funded by the Spanish project Spatial Audio Virtual Laboratory (SAVLab) - PID2019-107854GB-I00, Ministerio de Ciencia e Innovación
	ofDrawBitmapString("funded by the Spanish project", ofGetWidth() - 280, 155);
	ofDrawBitmapString("Spatial Audio Virtual Laboratory", ofGetWidth() - 280, 170);
	ofDrawBitmapString("(SAVLab) - PID2019-107854GB-I00", ofGetWidth() - 280, 185);
	ofDrawBitmapString("and the European project H2020", ofGetWidth() - 280, 200);
	ofDrawBitmapString("SONICOM (agreement No. 101017743)", ofGetWidth() - 280, 215);

	/// print number of visible images
	ofPushStyle();
	ofSetColor(50, 150);
	ofRect(ofGetWidth() - 300, ofGetHeight()- 130, 290, 120);
	ofPopStyle();
	char messageStr[255];
	sprintf(messageStr, "Number of visible images: %d", numberOfVisibleImages);
	ofDrawBitmapString(messageStr, ofGetWidth() - 285, ofGetHeight() - 115);
	sprintf(messageStr, "Number of source DSPs: %d", imageSourceDSPList.size()+1);  //number of DSPs for teh images plus one for the anechoic
	ofDrawBitmapString(messageStr, ofGetWidth() - 285, ofGetHeight()-100);
	//sprintf(messageStr, "Max distance images-listener: %d", int(ISMHandler->getMaxDistanceImageSources()));
	sprintf(messageStr, "Max distance images-listener: %d", int(maxDistanceImageSourcesToListenerControl.get()));
		ofDrawBitmapString(messageStr, ofGetWidth() - 285, ofGetHeight() - 85);
//#if 0
	if (stateBRIRReverbProcess)
	{
 	    sprintf(messageStr, "Number of silences frames: %d", numberOfSilencedFrames);
		ofDrawBitmapString(messageStr, ofGetWidth() - 285, ofGetHeight() - 70);
	}
	else
	{
		sprintf(messageStr, "Reverb Disabled");
		ofDrawBitmapString(messageStr, ofGetWidth() - 285, ofGetHeight() - 70);
	}
//#endif
	sprintf(messageStr, "posListener: %.2f %.2f %.2f", listenerLocation.x, listenerLocation.y, listenerLocation.z);
	ofDrawBitmapString(messageStr, ofGetWidth() - 285, ofGetHeight() - 55);
	
	//Common::CQuaternion QListener = listenerTransform.GetOrientation();
	float yaw, pitch, roll;
	QListener.ToYawPitchRoll(yaw, pitch, roll);
	sprintf(messageStr, "Listener: %.1f %.1f %.1f %.1f O:%.0f", QListener.w, QListener.x, QListener.y, QListener.z,ofRadToDeg(yaw));
	ofDrawBitmapString(messageStr, ofGetWidth() - 285, ofGetHeight() - 40);
	Common::CVector3 sourceLocation = ISMHandler2->getSourceLocation();
	sprintf(messageStr, "posSource: %.2f %.2f %.2f", sourceLocation.x, sourceLocation.y, sourceLocation.z);
	ofDrawBitmapString(messageStr, ofGetWidth() - 285, ofGetHeight() - 25);
	
	if (!boolToogleDisplayHelp)
	{
		ofPushStyle();
		ofSetColor(50, 150);
		ofRect(20, ofGetHeight() - 250, 390, 355);
		ofPopStyle();
		char messageStr[255];
		sprintf(messageStr, "Point of View Control: cursor keys");
		ofDrawBitmapString(messageStr, 30, ofGetHeight() -230);
		
		sprintf(messageStr, "MoveSOURCE:      'k'_Left(-X)   'i'_Right(+X)");
		ofDrawBitmapString(messageStr, 30, ofGetHeight() - 210);
		sprintf(messageStr, "                 'j'_Up  (+Y)   'l'_Down (-Y)");
		ofDrawBitmapString(messageStr, 30, ofGetHeight() - 190);
		sprintf(messageStr, "                 'u'_Up  (+Z)   'm'_Down (-Z)");
		ofDrawBitmapString(messageStr, 30, ofGetHeight() - 170);

		sprintf(messageStr, "MoveLISTENER:    's'_Left(-X)   'w'_Right(+X)");
		ofDrawBitmapString(messageStr, 30, ofGetHeight() - 150);
		sprintf(messageStr, "                 'a'_Up  (+Y)   'd'_Down (-Y)");
		ofDrawBitmapString(messageStr, 30, ofGetHeight() - 130);
		sprintf(messageStr, "                 'e'_Up  (+Z)   'x'_Down (-Z)");
		ofDrawBitmapString(messageStr, 30, ofGetHeight() - 110);
		
		sprintf(messageStr, "RotateLISTENER:  'A'_Left       'D'_right");
		ofDrawBitmapString(messageStr, 30, ofGetHeight() - 90);
				
		sprintf(messageStr, "ShoeBoxRoom:     'y'_Length++   'b'_Length--");
		ofDrawBitmapString(messageStr, 30, ofGetHeight() - 70);
		sprintf(messageStr, "                 'g'_Width++    'h'_Width--");
		ofDrawBitmapString(messageStr, 30, ofGetHeight() - 50);
		sprintf(messageStr, "                 'v'_Height++   'n'_Height--");
		ofDrawBitmapString(messageStr, 30, ofGetHeight() - 30);
		sprintf(messageStr, "Enable or disable wall: '1' '2' '3' '4' ... ");
		ofDrawBitmapString(messageStr, 30, ofGetHeight() - 10);

	}

	leftPanel.draw();

	if (!boolToogleDisplayAbout)
	{
		int width = 1050;
		int height = 470;
		int leftSide = (ofGetWidth() / 2) - width / 2;
		int upSide = ofGetHeight() / 2 - height / 2;
		int upPos = 20;

		ofPushStyle();
		ofSetColor(50, 230);
		ofRect(leftSide, upSide, width, height);
		ofNoFill();
		ofSetColor(200, 200);
		ofDrawRectangle(leftSide, upSide, width, height);
		ofPopStyle();

		char string[255];

		sprintf(string, "ABOUT IMAGE SOURCE METHOD (ISM) SIMULATOR");
		upPos += 5;
		ofDrawBitmapString(string, leftSide + 15, upSide + upPos);

		sprintf(string, "Version: 1.0.0");
		upPos += 40;
		ofDrawBitmapString(string, leftSide + 15, upSide + upPos);

		sprintf(string, "Copyright (c) University of Malaga. Contact email: areyes@uma.es.");
		upPos += 30; 
		ofDrawBitmapString(string, leftSide + 15, upSide + upPos);

		sprintf(string, "This software is available under GPLv3 license at https://github.com/3DTune-In/ImageSourceMethodTestApp");
		upPos += 30;
		ofDrawBitmapString(string, leftSide + 15, upSide + upPos);

		sprintf(string, "The ISM Simulator is a demostrator of the capabilities of the 3D Tune-In Toolkit to simulate eary reflections using the Image");
		upPos += 20;
		ofDrawBitmapString(string, leftSide + 15, upSide + upPos);
		sprintf(string, "Source Method. The application interface has been developed by Fabian Arrebola and Arcadio Reyes-Lecuona, and includes the ");
		upPos += 20;
		ofDrawBitmapString(string, leftSide + 15, upSide + upPos);
		sprintf(string, "3D Tune-In Toolkit library, developed and maintained by the 3DI-DIANA Team at the University of Malaga (Currently formed by ");
		upPos += 20;
		ofDrawBitmapString(string, leftSide + 15, upSide + upPos);
		sprintf(string, "Daniel González-Toledo, María Cuevas-Rodríguez, Luis Molina Tanco and Fabián Arrebola), under the coordination of Arcadio ");
		upPos += 20;
		ofDrawBitmapString(string, leftSide + 15, upSide + upPos);
		sprintf(string, "Reyes-Lecuona (University of Malaga) and Lorenzo Picinali (Imperial College London)");
		upPos += 20;
		ofDrawBitmapString(string, leftSide + 15, upSide + upPos);

		sprintf(string, "The 3D tune-In Toolkit is a standard C++ library for audio spatialisation and simulation using headphones, available at ");
		upPos += 30;
		ofDrawBitmapString(string, leftSide + 15, upSide + upPos);
		sprintf(string, "https://github.com/3DTune-In/3dti_AudioToolkit. Technical details about the 3D Tune-In Toolkit spatialiser are described in:");
		upPos += 20;
		ofDrawBitmapString(string, leftSide + 15, upSide + upPos);
		sprintf(string, "    - Cuevas-Rodríguez M, Picinali L, González-Toledo D, Garre C, de la Rubia-Cuestas E, Molina-Tanco L and Reyes-Lecuona A. (2019)");
		upPos += 20;
		ofDrawBitmapString(string, leftSide + 15, upSide + upPos);
		sprintf(string, "      3D Tune-In Toolkit: An open-source library for real-time binaural spatialisation. PLOS ONE 14(3): e0211899. ");
		upPos += 20;
		ofDrawBitmapString(string, leftSide + 15, upSide + upPos);
		
		sprintf(string, "You may use this software to generate 3D sounds or room IR without additional restrictions to those imposed by the license of ");
		upPos += 30;
		ofDrawBitmapString(string, leftSide + 15, upSide + upPos);
		sprintf(string, "the original audio or room geometry. You are not compelled to make any mention to this software when using or distributing ");
		upPos += 20;
		ofDrawBitmapString(string, leftSide + 15, upSide + upPos);
		sprintf(string, "those audio files, but we would highly appreciate if you might kindly acknowledge this ISM simulator and the 3D Tune-In Toolkit.");
		upPos += 20;
		ofDrawBitmapString(string, leftSide + 15, upSide + upPos);

		sprintf(string, "This work has been partially funded by the Ministry of Science and Technology within the National R&D Plan through the SAVLab ");
		upPos += 30;
		ofDrawBitmapString(string, leftSide + 15, upSide + upPos);
		sprintf(string, "project Virtual Spatial Audio Laboratory (PID2019-107854GB-I00) and by the European Union, within the framework program ");
		upPos += 20;
		ofDrawBitmapString(string, leftSide + 15, upSide + upPos);
		sprintf(string, "Horizon 2020 through the SONICOM project (agreement No. 101017743)");
		upPos += 20;
		ofDrawBitmapString(string, leftSide + 15, upSide + upPos);
	}
}

void ofApp::DrawRecordingOffline()
{
	uint64_t frameStart = ofGetElapsedTimeMillis();
	int bufferSize = myCore.GetAudioState().bufferSize;

	if (offlineRecordBuffers == 0) {		
		std::string fileNameUsr;
		if (boolRecordingIR)
		{		
			std::string pathResources = ofToDataPath("resources");						
			fileNameUsr = pathResources + "\\" + recordingFolder+"\\ImpulseResponse";
		}
		else
		{
			ofFileDialogResult saveFileResult = ofSystemSaveDialog("sample.wav", "Save output audio");
			fileNameUsr = saveFileResult.getPath();
		}
		if (fileNameUsr.size() > 0) {
			//if (reverbEnableControl && reflectionOrderControl.get() == 0) fileNameUsr = fileNameUsr + "w";       // Windowed+reverb
			//else if (reverbEnableControl && reflectionOrderControl.get() > 0) fileNameUsr = fileNameUsr + "t"; // Hybrid
			//else fileNameUsr = fileNameUsr + "i";                                                              // ISM

			////reflection order
			//fileNameUsr = fileNameUsr + "IrRO" + std::to_string(reflectionOrderControl);

			////pruning distance
			//if (maxDistanceImageSourcesToListenerControl<10)
			//	fileNameUsr = fileNameUsr + "DP0" + std::to_string((int)maxDistanceImageSourcesToListenerControl);
			//else
			//	fileNameUsr = fileNameUsr + "DP" + std::to_string((int)maxDistanceImageSourcesToListenerControl);

			////window width
			//if (windowSlopeControl < 10)
			//	fileNameUsr = fileNameUsr + "W0" + std::to_string(windowSlopeControl);
			//else
			//	fileNameUsr = fileNameUsr + "W" + std::to_string(windowSlopeControl);

			//if (reverbEnableControl && reflectionOrderControl.get() > 0)
			//	fileNameUsr = fileNameUsr + "HYB";

			StartWavRecord(fileNameUsr + ".wav", 16);                        // Open wav file
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
		}
		else
		{   
			//Calculates the number of buffers associated with the size of the wav file
			unsigned long long samplesVectorSize = source1Wav.getSizeSamplesVector();
			offlineRecordBuffers = ceil(samplesVectorSize / myCore.GetAudioState().bufferSize);
			
		}

		std::lock_guard <std::mutex> lock(audioMutex); // Avoids race conditions with audio thread when cleaning buffers					
		if (!stopState) audioInterfaceController->StopAudioInterface();
		environment->ResetReverbBuffers();
		anechoicSourceDSP->ResetSourceBuffers();				  //Clean buffers
		anechoicSourceDSP->DisableDistanceAttenuationSmoothingAnechoic();

		for (int i = 0; i < imageSourceDSPList.size(); i++) {
			imageSourceDSPList.at(i)->ResetSourceBuffers();
			imageSourceDSPList.at(i)->DisableDistanceAttenuationSmoothingAnechoic();
		}

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
	while ((aux = ofGetElapsedTimeMillis() - frameStart) < frameDurationInMilliseconds) {
		OfflineWavRecordOneLoopIteration(bufferSize);  //audioProcess + wavWriter_AppendToFile + offlineRecordBuffers++
		offlineRecordIteration++;
		if (offlineRecordIteration == offlineRecordBuffers)
			break;
	}
	if (offlineRecordBuffers != 0)
		recordingPercent = 0 + (100 * float(offlineRecordIteration)) / offlineRecordBuffers;

	if (recordingPercent >= 100.0f) {
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
		anechoicSourceDSP->EnableDistanceAttenuationSmoothingAnechoic();
		for (int i = 0; i < imageSourceDSPList.size(); i++) {
			imageSourceDSPList.at(i)->EnableDistanceAttenuationSmoothingAnechoic();
		}

		if (!stopState && playState) audioInterfaceController->StartAudioInterface(); /*audioInterfaceController->StartAudioInterface();*/

	}

	if (recordingPercent >= 100.0f) {
		// TODO Delete me, just for testing
		// Send msg to matlab
		SendOSCMessageToMatlab_Ready();
	}

	ofPopStyle();
	return;
}

//--------------------------------------------------------------
void ofApp::keyPressed(int key) {

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
		scale *= 0.9;
		break;
	case OF_KEY_PAGE_DOWN:
		scale *= 1.1;
		break;
#if 0
	case OF_KEY_INSERT:
		numberOfSilencedFrames++;
		if (numberOfSilencedFrames > 251) numberOfSilencedFrames = 251;
		numberOfSilencedSamples = numberOfSilencedFrames * myCore.GetAudioState().bufferSize;
		/*int numberOfSilencedFrames;
		numberOfSilencedFrames = environment->GetNumberOfSilencedFrames();
		numberOfSilencedFrames++;
		environment->SetNumberOfSilencedFrames(numberOfSilencedFrames);*/
		break;

	case OF_KEY_DEL:
		numberOfSilencedFrames--;
		if (numberOfSilencedFrames < 0) numberOfSilencedFrames = 0;
		numberOfSilencedSamples = numberOfSilencedFrames * myCore.GetAudioState().bufferSize;
		/*int numberOfSilencedFrames;
		numberOfSilencedFrames = environment->GetNumberOfSilencedFrames();
		numberOfSilencedFrames--;
		environment->SetNumberOfSilencedFrames(numberOfSilencedFrames);*/
		break;
#endif

	case OF_KEY_HOME: // OF_KEY_PAGE_UP:
	{
		if (maxDistanceImageSourcesToListenerControl.get() < MAX_DIST_SILENCED_FRAMES-3.43)
		{
			if (!stopState) audioInterfaceController->StopAudioInterface();/* audioInterfaceController->StopAudioInterface();*/

			float maxDistanceISM = maxDistanceImageSourcesToListenerControl.get() + 3.43;

			//changeMaxDistanceImageSources(maxDistanceISM);
			maxDistanceImageSourcesToListenerControl.set(maxDistanceISM);
			//ISMHandler2->setMaxDistanceImageSources(maxDistanceISM, millisec2meters(currentWindowSlopeWidth));
			//reCreateImageSourceDSP();
			if (!stopState) audioInterfaceController->StartAudioInterface();/*audioInterfaceController->StartAudioInterface();*/
		}
		break;
	}
	case OF_KEY_END: //OF_KEY_PAGE_DOWN:
	{
		if (maxDistanceImageSourcesToListenerControl.get() > MIN_DIST_SILENCED_FRAMES+3.43)
		{
			if (!stopState) audioInterfaceController->StopAudioInterface();

			float maxDistanceISM = maxDistanceImageSourcesToListenerControl.get() - 3.43;

			//ofApp::changeMaxDistanceImageSources(maxDistanceISM);
			maxDistanceImageSourcesToListenerControl.set(maxDistanceISM);
			//ISMHandler->setMaxDistanceImageSources(maxDistanceISM, millisec2meters(currentWindowSlopeWidth));
			//reCreateImageSourceDSP();
			if (!stopState) audioInterfaceController->StartAudioInterface();
		}
		break;
	}
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
		MoveListener(Common::CVector3(-LISTENER_STEP, 0, 0));
		break;
	}
	case 'w': //Moves the listener right (X)
	{
		MoveListener(Common::CVector3(LISTENER_STEP, 0, 0));		
		break;
	}
	case 'a': //Moves the listener up (Y)
	{
		MoveListener(Common::CVector3(0, LISTENER_STEP, 0));
		break;
	}
	case 'd': //Moves the listener down (-Y)
	{
		MoveListener(Common::CVector3(0, -LISTENER_STEP, 0));		
		break;
	}
	case 'e': //Moves the listener up (Z)
	{
		MoveListener(Common::CVector3(0, 0, LISTENER_STEP));		
		break;
	}

	case 'x': //Moves the listener up (-Z)
	{
		MoveListener(Common::CVector3(0, 0, -LISTENER_STEP));		
		break;
	}
	case 'A': //Rotate Left
		listenerTransform.Rotate(Common::CVector3(0, 0, 1), PI/32);
		listener->SetListenerTransform(listenerTransform);
		break;
	case 'D': //Rotate Right
		listenerTransform.Rotate(Common::CVector3(0, 0, 1), -PI/4);
		listener->SetListenerTransform(listenerTransform);
		break;
	case 'Z': //Rotate Roll Left
		listenerTransform.Rotate(Common::CVector3(1, 0, 0), -PI/4);
		listener->SetListenerTransform(listenerTransform);
		break;
	case 'C': //Rotate Roll Right
		listenerTransform.Rotate(Common::CVector3(1, 0, 0), PI/4);
		listener->SetListenerTransform(listenerTransform);
		break;
	case '+': //increases the reflection order 
		if (reflectionOrderControl < MAX_REFLECTION_ORDER) reflectionOrderControl++;
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
//#if 0
	case OF_KEY_F1://ABSORTION -- null
	{
		if (!stopState) audioInterfaceController->StopAudioInterface();

		int numWalls = mainRoom.getWalls().size();
		std::vector<std::vector<float>> absortionsWalls;
		for (int i = 0; i < numWalls; i++) {
			absortionsWalls.push_back({ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 });
		}
		mainRoom.setWallAbsortion(absortionsWalls);
		//ISMHandler->setAbsortion((std::vector<std::vector<float>>)  absortionsWalls);
		ReconfigureISM();
		//reCreateImageSourceDSP();

		//mainRoom = ISMHandler->getRoom();
		if (!stopState) audioInterfaceController->StartAudioInterface();
		break;
	}
	case OF_KEY_F2://ABSORTION -- 0.7
	{
		if (!stopState) audioInterfaceController->StopAudioInterface();

		int numWalls = mainRoom.getWalls().size();
		std::vector<std::vector<float>> absortionsWalls;
		for (int i = 0; i < numWalls; i++) {
			absortionsWalls.push_back({ 0.7, 0.7, 0.7, 0.7, 0.7, 0.7, 0.7, 0.7, 0.7 });
		}
		mainRoom.setWallAbsortion((std::vector<std::vector<float>>)  absortionsWalls);
		ReconfigureISM();
		//reCreateImageSourceDSP();

		//mainRoom = ISMHandler->getRoom();
		if (!stopState) audioInterfaceController->StartAudioInterface();
		break;
	}
//#endif

	case 'y': //increase room's length
		if (!stopState) audioInterfaceController->StopAudioInterface();

		shoeboxLength += 0.5;
		
		//ISMHandler->SetupShoeBoxRoom(shoeboxLength, shoeboxWidth, shoeboxHeight);
		mainRoom.setupShoeBox(shoeboxLength, shoeboxWidth, shoeboxHeight);
		//ISMHandler->SetupRoom(mainRoom);

		mainRoom.setWallAbsortion({ {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3} });

		//mainRoom = ISMHandler->getRoom();
		ReconfigureISM();
		//reCreateImageSourceDSP();
		if (!stopState) audioInterfaceController->StartAudioInterface();
		break;
	case 'b': //decrease room's length
		if (!stopState) audioInterfaceController->StopAudioInterface();
		if (shoeboxLength > 3.0)  shoeboxLength -= 0.5;

		//ISMHandler->SetupShoeBoxRoom(shoeboxLength, shoeboxWidth, shoeboxHeight);
		mainRoom.setupShoeBox(shoeboxLength, shoeboxWidth, shoeboxHeight);
		//ISMHandler->SetupRoom(mainRoom);
		mainRoom.setWallAbsortion({ {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3} });

		//mainRoom = ISMHandler->getRoom();
		ReconfigureISM();
		//reCreateImageSourceDSP();
		if (!stopState) audioInterfaceController->StartAudioInterface();
		break;
	case 'g': //decrease room's width
		if (!stopState) audioInterfaceController->StopAudioInterface();
		if (shoeboxWidth > 3.0) shoeboxWidth -= 0.5;

		//ISMHandler->SetupShoeBoxRoom(shoeboxLength, shoeboxWidth, shoeboxHeight);
		mainRoom.setupShoeBox(shoeboxLength, shoeboxWidth, shoeboxHeight);
		//ISMHandler->SetupRoom(mainRoom);

		mainRoom.setWallAbsortion({ {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3} });

		//mainRoom = ISMHandler->getRoom();
		ReconfigureISM();
		//reCreateImageSourceDSP();
		if (!stopState) audioInterfaceController->StartAudioInterface();
		break;
	case 'h': //increase room's width
		if (!stopState) audioInterfaceController->StopAudioInterface();
		shoeboxWidth += 0.5;

		//ISMHandler->SetupShoeBoxRoom(shoeboxLength, shoeboxWidth, shoeboxHeight);
		mainRoom.setupShoeBox(shoeboxLength, shoeboxWidth, shoeboxHeight);
		//ISMHandler->SetupRoom(mainRoom);

		mainRoom.setWallAbsortion({ {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3} });

		//mainRoom = ISMHandler->getRoom();
		ReconfigureISM();
		//reCreateImageSourceDSP();
		if (!stopState) audioInterfaceController->StartAudioInterface();
		break;
	case 'v': //decrease room's height
		if (!stopState) audioInterfaceController->StopAudioInterface();
		if (shoeboxHeight > 2.5) shoeboxHeight -= 0.5;
		//ISMHandler->SetupShoeBoxRoom(shoeboxLength, shoeboxWidth,shoeboxHeight);
		mainRoom.setupShoeBox(shoeboxLength, shoeboxWidth, shoeboxHeight);
		//ISMHandler->SetupRoom(mainRoom);

		mainRoom.setWallAbsortion({ {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3} });

		//mainRoom = ISMHandler->getRoom();
		ReconfigureISM();
		//reCreateImageSourceDSP();
		if (!stopState) audioInterfaceController->StartAudioInterface();
		break;
	case 'n': //increase room's height
		if (!stopState) audioInterfaceController->StopAudioInterface();
		shoeboxHeight += 0.5;
		//ISMHandler->SetupShoeBoxRoom(shoeboxLength, shoeboxWidth, shoeboxHeight);
		mainRoom.setupShoeBox(shoeboxLength, shoeboxWidth, shoeboxHeight);
		//ISMHandler->SetupRoom(mainRoom);

		mainRoom.setWallAbsortion({ {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3} });

		//mainRoom = ISMHandler->getRoom();
		ReconfigureISM();
		//reCreateImageSourceDSP();
		if (!stopState) audioInterfaceController->StartAudioInterface();
		break;

	case 'T':
	{
		std::vector<ISM::ImageSourceData> images = ISMHandler2->getImageSourceData();
		float maxDistanceImagesToListener = ISMHandler2->getMaxDistanceImageSources();		
		ShowImagesSourceSummaryData(maxDistanceImagesToListener, images);
		break;
	}

	case 't': //Test
	{
		std::vector<ISM::ImageSourceData> data = ISMHandler2->getImageSourceData();		
		ShowImageSourceData(data, listenerLocation);

		break;				
	}
	//case 'r': //Test
	//{
	//	std::vector<ISM::ImageSourceData> data = ISMHandler2->getImageSourceData();
	//	std::cout << std::endl<< "---- ISM 2 ----" << std::endl;
	//	ShowImageSourceData(data, listenerLocation);

	//	break;
	//}
	//case 'R':
	//{
	//	std::vector<ISM::ImageSourceData> images = ISMHandler2->getImageSourceData();
	//	float maxDistanceImagesToListener = ISMHandler2->getMaxDistanceImageSources();
	//	std::cout << std::endl << "---- ISM 2 ----" << std::endl;
	//	ShowImagesSourceSummaryData(maxDistanceImagesToListener, images);
	//	break;
	//}

	/*case 'q':
	{
		float a = ISMHandler->getMaxDistanceImageSources();
		float b = ISMHandler->getTransitionMeters();
		int c = ISMHandler->getReflectionOrder();

		float maxDistanceImageSources = maxDistanceImageSourcesToListenerControl.get();
		float windowSlopeInMeters = millisec2meters(currentWindowSlopeWidth);
		int order = (int)reflectionOrderControl.get();
		ISM::Room room = ISMHandler2->getRoom();
		ISMHandler2->Setup(order, maxDistanceImageSources, windowSlopeInMeters, mainRoom);
		break;
	}*/
	case 'z':
	{			
		// TODO Delete me, just for testing
		SendOSCMessageToMatlab_Ready();
		break;
	}
	}
}

void ofApp::MoveListener(Common::CVector3 _movement)
{
	Common::CTransform newListenerTransform = listener->GetListenerTransform();	
	newListenerTransform.Translate(_movement);
	Common::CVector3 newListenerLocation = newListenerTransform.GetPosition();
		
	float distanceNearestWall;
	bool result = mainRoom.checkPointInsideRoom(newListenerLocation, distanceNearestWall);
	if (result)
	{				
		listener->SetListenerTransform(newListenerTransform);
		ISMHandler2->SetListenerPosition();
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


void ofApp::ChangeAudioDevice() {

	audioInterfaceController->StopAudioInterface();
	audioInterfaceController->CloseAudioInterface();
	std::vector<CAudioInterfaceController::TAudioInterface> audioInterfaceList = audioInterfaceController->GetOutputAudioDeviceList();
	audioInterfaceController->ShowListAvailableAudioInterface();

	int selectedAudioDevice;
	do {
		cout << "Please choose which audio output you wish to use: ";
		cin >> selectedAudioDevice;
		cin.clear();
		cin.ignore(INT_MAX, '\n');
	} while (!(selectedAudioDevice > -1 && selectedAudioDevice <= audioInterfaceList.back().ID));


	CAudioInterfaceController::TAudioInterfaceSelected _outDevice;
	_outDevice.ID = audioInterfaceList[selectedAudioDevice].ID;
	_outDevice.name = audioInterfaceList[selectedAudioDevice].name;
	_outDevice.API = audioInterfaceList[selectedAudioDevice].API;
	_outDevice.channels = 2;

	CAudioInterfaceController::TAudioInterfaceSelected _inDevice = CAudioInterfaceController::TAudioInterfaceSelected();
	audioInterfaceController->SetupAudioDevices(_outDevice, _inDevice);
}



/// Read the list of devices of the user computer, allowing the user to select which device to use. Configure the Audio using openFramework
//void ofApp::SetDeviceAndAudio(Common::TAudioStateStruct audioState) {
	//// This call could block the app when the motu audio interface is unplugged
	//// It gives the message: 
	//// RtApiAsio::getDeviceInfo: error (Hardware input or output is not present or available).
	//// initializing driver (Focusrite USB 2.0 Audio Driver).
	//deviceList = systemSoundStream.getDeviceList();


	//for (int c = deviceList.size() - 1; c >= 0; c--)
	//{
	//	if (deviceList[c].outputChannels == 0)
	//		deviceList.erase(deviceList.begin() + c);
	//}

	////Show list of devices and return the one selected by the user
	//int deviceId = GetAudioDeviceIndex(deviceList);

	//if (deviceId >= 0)
	//{
	//	systemSoundStream.setDevice(deviceList[deviceId]);

	//	ofSoundDevice &dev = deviceList[deviceId];

	//	//Setup Aduio
	//	systemSoundStream.setup(this,		// Pointer to ofApp so that audioOut is called									  
	//		2,								//dev.outputChannels, // Number of output channels reported
	//		0,								// Number of input channels
	//		audioState.sampleRate,			// sample rate, e.g. 44100 
	//		audioState.bufferSize,			// Buffer size, e.g. 512
	//		4   // -> Is the number of buffers that your system will create and swap out.The more buffers, 
	//		   // the faster your computer will write information into the buffer, but the more memory it 
	//		  // will take up.You should probably use two for each channel that you’re using.Here’s an 
	//		 // example call : ofSoundStreamSetup(2, 0, 44100, 256, 4);
	//		//     http://openframeworks.cc/documentation/sound/ofSoundStream/
	//	);
	//	cout << "Device selected : " << "ID: " << dev.deviceID << "  Name: " << dev.name << endl;

	//	systemSoundStream_Started = true;

	//	//lastBuffer.setDeviceID(deviceId);
	//	
	//}
	//else
	//{
	//	cout << "Could not find any usable sound Device" << endl;

	//	systemSoundStream_Started = false;
	//}
//}

/// Ask the user to select the audio device to be used and return the index of the selected device
//int ofApp::GetAudioDeviceIndex(std::vector<ofSoundDevice> list)
//{
	////Show in the console the Audio device list
	//int numberOfAudioDevices = list.size(); 
	//cout << "     List of available audio outputs" << endl;
	//cout << "----------------------------------------" << endl;
	//for (int i = 0; i < numberOfAudioDevices; i++) {
	//	cout << "ID: " << i << "-" << list[i].name << endl;
	//}
	//int selectedAudioDevice;

	//do {
	//	cout << "Please choose which audio output you wish to use: ";
	//	cin >> selectedAudioDevice;
	//	cin.clear();
	//	cin.ignore(INT_MAX, '\n');
	//} while (!(selectedAudioDevice > -1 && selectedAudioDevice <= numberOfAudioDevices));

	//// First, we try to retrieve the <Conf.audioInterfaceIndex> th suitable device in the list:
	//for (int c = 0; c < numberOfAudioDevices; c++)
	//{
	//	ofSoundDevice &dev = list[c];

	//	if ((dev.outputChannels >= 0) && c == selectedAudioDevice)
	//		return c;
	//}

	//// Otherwise, we try to get the defult device
	//for (int c = 0; c < numberOfAudioDevices; c++)
	//{
	//	ofSoundDevice &dev = list[c];

	//	// dev.isDefaultOutput is not really the same that windows report
	//	// TODO: update to latest openFrameworks that really can report all drivers present
	//	// via ofSoundStream::getDevicesByApi 
	//	//if ((dev.outputChannels >= NUMBER_OF_SPEAKERS) && dev.isDefaultOutput)
	//	if ((dev.outputChannels >= 0) && dev.isDefaultOutput)
	//		return c;
	//}
//	return -1;
//}


/// Audio output management by openFramework
#if 1
void ofApp::audioOut(float * output, int bufferSize, int nChannels) {
	
	//lock_guard < mutex > lock(audioMutex);

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
	if (profilling) {
		Common::PROFILER3DTI.RelativeSampleStart(dsProcessFrameTime);
		Common::PROFILER3DTI.RelativeSampleStart(dsProcessAnechoicTime);
	}
#endif

	// Anechoic processing
	processAnechoic(source1, bufferOutput);

#ifdef USE_PROFILER
	if (profilling) Common::PROFILER3DTI.RelativeSampleEnd(dsProcessAnechoicTime);
#endif

	if (stateBRIRReverbProcess)
	{
#ifdef USE_PROFILER
		if (profilling) Common::PROFILER3DTI.RelativeSampleStart(dsProcessReverbTime);
#endif
		// Reverberation processing
		processReverb(source1, bufferOutput);
#ifdef USE_PROFILER
		if (profilling) Common::PROFILER3DTI.RelativeSampleEnd(dsProcessReverbTime);
#endif
	}

	if (stateISMProcess)
	{

#ifdef USE_PROFILER
		if (profilling) Common::PROFILER3DTI.RelativeSampleStart(dsProcessISMTime);
#endif		
		processImages(source1, bufferOutput);	// Image source processing

#ifdef USE_PROFILER
		if (profilling) Common::PROFILER3DTI.RelativeSampleEnd(dsProcessISMTime);
#endif
	}

#ifdef USE_PROFILER
	if (profilling) { Common::PROFILER3DTI.RelativeSampleEnd(dsProcessFrameTime);	}
#endif	
}
#endif




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
	environment->ProcessVirtualAmbisonicReverb(bufferReverb.left, bufferReverb.right, numberOfSilencedSamplesInBRIR);
	// Adding reverberated sound to the direct path
	bufferOutput.left += bufferReverb.left;
	bufferOutput.right += bufferReverb.right;

}


void ofApp::processImages(CMonoBuffer<float> &bufferInput, Common::CEarPair<CMonoBuffer<float>> & bufferOutput)
{
	Common::CTransform listenerTransform = listener->GetListenerTransform();
	Common::CVector3 listenerLocation = listenerTransform.GetPosition();
	std::vector<ISM::ImageSourceData> data = ISMHandler2->getImageSourceData();

	if (data.size() != imageSourceDSPList.size()) { cout << "ERROR: DSP list ("<< imageSourceDSPList.size() <<") and source list ("<< data.size()<<") have different sizes \n"; }

	std::vector<CMonoBuffer<float>> bufferImages;
	ISMHandler2->proccess(bufferInput, bufferImages, listenerLocation);

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
void ofApp::drawRoom(ISM::Room& room, int reflectionOrder,int transparency)
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

void ofApp::drawWall(ISM::Wall& wall)
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

void ofApp::drawWallNormal(ISM::Wall& wall, float length)
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

/**
 * @brief Moving the original anechoic source
 * @param movement 
 */
void ofApp::moveSource(Common::CVector3 movement)
{
	Common::CTransform sourcePosition = anechoicSourceDSP->GetCurrentSourceTransform();
	Common::CVector3 sourceLocation = sourcePosition.GetPosition();	
	Common::CVector3 newLocation = sourceLocation + movement;			
	//Common::CVector3 newLocation = ISMHandler2->getSourceLocation() + movement;
	//Common::CTransform listenerTransform = listener->GetListenerTransform();
	//Common::CVector3 listenerLocation = listenerTransform.GetPosition();	
	ISMHandler2->setSourceLocation(newLocation);
	//Common::CTransform sourcePosition;
	sourcePosition.SetPosition(newLocation);
	anechoicSourceDSP->SetSourceTransform(sourcePosition);		
}

//std::vector<shared_ptr<Binaural::CSingleSourceDSP>> ofApp::createImageSourceDSP()
void ofApp::createImageSourceDSP()
{
	if (imageSourceDSPList.size() > 0) return; // Already created	
	//std::vector<shared_ptr<Binaural::CSingleSourceDSP>> tempImageSourceDSPList;
	std::vector<Common::CVector3> imageSourceLocationList = ISMHandler2->getImageSourceLocations();		

	for (int i = 0; i < imageSourceLocationList.size(); i++)
	{
		shared_ptr<Binaural::CSingleSourceDSP> tempSourceDSP = myCore.CreateSingleSourceDSP();								// Creating audio source
		Common::CTransform sourcePosition;
		sourcePosition.SetPosition(imageSourceLocationList.at(i));
		tempSourceDSP->SetSourceTransform(sourcePosition);							//Set source position
		if (stateBinauralSpatialisation)
		{
			tempSourceDSP->SetSpatializationMode(Binaural::TSpatializationMode::HighQuality);	// Choosing high quality mode for anechoic processing
		}
		else
		{
			tempSourceDSP->SetSpatializationMode(Binaural::TSpatializationMode::NoSpatialization);	// Choosing no spatialisation mode for anechoic processing
		}
		tempSourceDSP->DisableNearFieldEffect();											// Audio source will not be close to listener, so we don't need near field effect
		//DistanceAttenuation
		tempSourceDSP->EnableAnechoicProcess();											// Enable anechoic processing for this source
		if (stateDistanceAttenuationAnechoic)
		   tempSourceDSP->EnableDistanceAttenuationAnechoic();								//  distance simulation
		else
		   tempSourceDSP->DisableDistanceAttenuationAnechoic();
		tempSourceDSP->EnablePropagationDelay();
		tempSourceDSP->DisableReverbProcess();
		imageSourceDSPList.push_back(tempSourceDSP);
	}
	//return tempImageSourceDSPList;
}

//std::vector<shared_ptr<Binaural::CSingleSourceDSP>> ofApp::reCreateImageSourceDSP()
void ofApp::reCreateImageSourceDSP()
{
	for (int i = 0; i < imageSourceDSPList.size(); i++)					//Revome old sourcesDSP
		myCore.RemoveSingleSourceDSP(imageSourceDSPList.at(i));

	imageSourceDSPList.clear();
	createImageSourceDSP();						//Create new sourceDSP
	//return imageSourceDSPList;
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
	if (is_equal(currentReflectionOrder, _reflectionOrder)) return;

	if (!stopState) audioInterfaceController->StopAudioInterface();
	currentReflectionOrder = _reflectionOrder;
	//ISMHandler->setReflectionOrder(_reflectionOrder);
	ReconfigureISM();
    //reCreateImageSourceDSP();
	if (!stopState) audioInterfaceController->StartAudioInterface();
}


void ofApp::changeMaxDistanceImageSources(float &_maxDistanceSourcesToListener)
{
	if (setupDone == false) return;

	if (is_equal(currentMaxDistanceSourcesToListener,_maxDistanceSourcesToListener)) return;

	if (!stopState) audioInterfaceController->StopAudioInterface();
	stopState = true;
	playState = false;
	playToStopControl.set("Stop", true);
	stopToPlayControl.set("Play", false);

	//float maxDistanceSourcesToListener = _maxDistanceSourcesToListener;

	float numSamplesThreshold = meters2samples(_maxDistanceSourcesToListener);
	float numsamplesWindowSlope = millisec2samples(currentWindowSlopeWidth);
	float numSamplesTotal = numSamplesThreshold + numsamplesWindowSlope/2;

	int BRIRLength = environment->GetBRIR()->GetBRIRLength();
	
	if (numSamplesTotal > BRIRLength)
	{   // WindowThreshold + WindowSlope must be less than BRIR duration
		/*numSamplesTotal = BRIRLength - numsamplesWindowSlope;
		maxDistanceSourcesToListener = samples2meters(numSamplesTotal);*/		
		maxDistanceImageSourcesToListenerControl.setWithoutEventNotifications(currentMaxDistanceSourcesToListener);		
		return;
	}
		
	if ( numSamplesThreshold - numsamplesWindowSlope/2 <= 0)
	{   // WindowSlope too wide and WindowThreshold too low
		//  WindowSlope*0.5 (half-window size to implement the "crossfade") must be less than the Threshold
		//numsamplesWindowSlope = meters2samples(MIN_DIST_SILENCED_FRAMES)-2;   //window is reduced
		//numSamplesThreshold = meters2samples(MIN_DIST_SILENCED_FRAMES)+2;
		//maxDistanceSourcesToListener = samples2meters(numSamplesThreshold);
		//maxDistanceImageSourcesToListenerControl.set(maxDistanceSourcesToListener);
		//windowSlopeWidth = samples2millisec(numsamplesWindowSlope);
		//windowSlopeControl.set(windowSlopeWidth);
		maxDistanceImageSourcesToListenerControl.setWithoutEventNotifications(currentMaxDistanceSourcesToListener);
		return;
	}
	//
	//float windowSlopeInMeters = millisec2meters(windowSlopeWidth);
	////if (windowSlopeInMeters < MIN_DIST_SILENCED_FRAMES)
	////{	//windowSlope expressed in meters must be greater than the minimum distance
	////	windowSlopeInMeters = MIN_DIST_SILENCED_FRAMES;
	////}

	//if (maxDistanceSourcesToListener - (windowSlopeInMeters / 2.0) < 0)
	//{ //maxDistanceSourcesToListener must exceed half the WindowSlope in meters
	//	//windowSlopeInMeters = MIN_DIST_SILENCED_FRAMES;
	//	return;
	//}	
	//windowSlopeWidth = meters2millisec(windowSlopeInMeters);	
	/*windowSlopeControl.disableEvents();
	windowSlopeControl.set(windowSlopeWidth);
	windowSlopeControl.enableEvents();*/

	//numberOfSilencedSamplesInBRIR = meters2samples(_maxDistanceSourcesToListener);		
	//numberOfSilencedFrames = floor((numberOfSilencedSamplesInBRIR - numsamplesWindowSlope/2) / myCore.GetAudioState().bufferSize);
	//if (numberOfSilencedFrames < 0)
	//{   // NumberOfSilencedFrames cannot be negative
	//	numberOfSilencedFrames = 0;
	//	windowSlopeWidth = INITIAL_WIN_SLOPE;
	//	windowSlopeControl.set(INITIAL_WIN_SLOPE);
	//}

	//float windowThreshold = 0.001 * meters2millisec(maxDistanceSourcesToListener);
	//environment->SetFadeInWindow(windowThreshold, (0.001 * windowSlopeWidth), reverbGainLinear);	
	// 
	// 
	currentMaxDistanceSourcesToListener = _maxDistanceSourcesToListener;
	maxDistanceImageSourcesToListenerControl.set(currentMaxDistanceSourcesToListener);

	SetEnvironmentFadeInWindow(currentMaxDistanceSourcesToListener); 	
	//ISMHandler->setMaxDistanceImageSources(currentMaxDistanceSourcesToListener, millisec2meters(currentWindowSlopeWidth));
	//reCreateImageSourceDSP();
	
	currentWindowThreshold = meters2millisec(currentMaxDistanceSourcesToListener);
	//winThresholdControl.setWithoutEventNotifications(windowThreshold);	
	winThresholdControl.set(currentWindowThreshold);		
	ReconfigureISM();

	if (!stopState) audioInterfaceController->StartAudioInterface();
}

void ofApp::changeWinThreshold(float& _windowThreshold)
{
	if (is_equal(currentWindowThreshold, _windowThreshold)) return;

	float maxDistanceSourcesToListener = millisec2meters(_windowThreshold);
	changeMaxDistanceImageSources(maxDistanceSourcesToListener);	

	//if (setupDone == false) return;
	//
	//if (!stopState) audioInterfaceController->StopAudioInterface();
	//stopState = true;
	//playState = false;
	//playToStopControl.set("Stop", true);
	//stopToPlayControl.set("Play", false);

	//if (_windowThreshold < windowSlopeWidth / 2) {
	//	_windowThreshold = windowSlopeWidth / 2 + 1;
	//}

	//float windowThreshold = _windowThreshold;   // in millisec
	//float maxDistanceSourcesToListener = (windowThreshold * myCore.GetMagnitudes().GetSoundSpeed()) / 1000;	
	//changeMaxDistanceImageSources(maxDistanceSourcesToListener);
	//
	//float windowThresholdInSec = 0.001 * windowThreshold;
	//environment->SetFadeInWindow(windowThresholdInSec, (0.001 * windowSlopeWidth), reverbGainLinear);
	//float windowSlopeInMeters = millisec2meters(windowSlopeWidth);
	//ISMHandler->setMaxDistanceImageSources(maxDistanceSourcesToListener, windowSlopeInMeters);
	//	
	//maxDistanceImageSourcesToListenerControl.set(maxDistanceSourcesToListener);

	//if (!stopState) audioInterfaceController->StartAudioInterface();
}


void ofApp::changeWindowSlope(int& _windowSlopeWidth)
{
	if (setupDone == false) return;

	if (is_equal(currentWindowSlopeWidth, _windowSlopeWidth)) return;

	if (!stopState) audioInterfaceController->StopAudioInterface();
	stopState = true;
	playState = false;
	playToStopControl.set("Stop", true);
	stopToPlayControl.set("Play", false);

	/*float windowSlope = (float)_windowSlopeWidth;
	
	float soundSpeed = myCore.GetMagnitudes().GetSoundSpeed();
	float sampleRate = myCore.GetAudioState().sampleRate;
	float maxDistanceSourcesToListener = ISMHandler->getMaxDistanceImageSources();*/

	//float a = millisec2meters(windowSlope);
	//if (millisec2meters(windowSlope) >= 2 * maxDistanceSourcesToListener)  // 
	//{	//  WindowSlope (window size to implement the "crossfade") must be less than the Threshold
	//	//windowSlope = meters2millisec(maxDistanceSourcesToListener); //millisecs
	//	//windowSlopeControl.set(windowSlope);
	//	//_windowSlope = windowSlope;
	//}	
	if (_windowSlopeWidth >= 2* currentWindowThreshold) {
		windowSlopeControl.setWithoutEventNotifications(currentWindowSlopeWidth);
		return;
	}

	int numSamplesThreshold = meters2samples(float(currentMaxDistanceSourcesToListener));
	int numSamplesWindowSlope = millisec2samples(float(_windowSlopeWidth) / 2);
	int numSamplesTotal = numSamplesThreshold + numSamplesWindowSlope;
	int BRIRLength = environment->GetBRIR()->GetBRIRLength();	
	if (numSamplesTotal > BRIRLength)
	{   // WindowThreshold + WindowSlope must be less than BRIR duration
		//windowSlopeControl.set(MIN_WIN_SLOPE); //millisecs
		//_windowSlopeWidth = MIN_WIN_SLOPE;       //millisecs
		windowSlopeControl.setWithoutEventNotifications(currentWindowSlopeWidth);
		return;
	}

	// TODO Is this verification the same as before?
	if (numSamplesWindowSlope/2 + 1 >= numSamplesThreshold)
	{  // NumSamples of windowSlope/2 must be greater than the NumSamples of Threshold
		/*numSamplesWindowSlope = numSamplesThreshold-2;
		_windowSlopeWidth = samples2millisec(numSamplesWindowSlope);
		windowSlopeControl.set(_windowSlopeWidth);*/
		windowSlopeControl.setWithoutEventNotifications(currentWindowSlopeWidth);
		return;
	}

	currentWindowSlopeWidth = _windowSlopeWidth;
	SetEnvironmentFadeInWindow(currentMaxDistanceSourcesToListener);
	//float windowThreshold = ((float)(currentMaxDistanceSourcesToListener)) / myCore.GetMagnitudes().GetSoundSpeed();
	////numberOfSilencedFrames = floor((numberOfSilencedSamplesInBRIR - numSamplesWindowSlope) / myCore.GetAudioState().bufferSize);
	////if (numberOfSilencedFrames < 0)
	////{  // NumberOfSilencedFrames cannot be negative 
	////	numberOfSilencedFrames = 0;
	////	currentWindowSlopeWidth = MIN_WIN_SLOPE;
	////	windowSlopeControl.set(MIN_WIN_SLOPE);
	////}

	//environment->SetFadeInWindow(windowThreshold, (0.001*currentWindowSlopeWidth), reverbGainLinear);
	//float windowSlopeInMeters = millisec2meters(currentWindowSlopeWidth);

	//ISMHandler->setMaxDistanceImageSources(currentMaxDistanceSourcesToListener, millisec2meters(currentWindowSlopeWidth));	
	ReconfigureISM();
	//reCreateImageSourceDSP();

	if (!stopState) audioInterfaceController->StartAudioInterface();
}

void ofApp::changeReverbGain(float &_reverbGain)
{
	if (setupDone == false) return;

	if (!stopState) audioInterfaceController->StopAudioInterface();
	stopState = true;
	playState = false;
	playToStopControl.set("Stop", true);
	stopToPlayControl.set("Play", false);

	reverbGainControl.set(_reverbGain);
	float reverGaindB = _reverbGain;
	reverbGainLinear = pow(10.0, ((reverGaindB) / 20.0));

	float windowThreshold = winThresholdControl.get();
	environment->SetFadeInWindow((0.001) * windowThreshold, (0.001 * currentWindowSlopeWidth), reverbGainLinear);

	if (!stopState) audioInterfaceController->StartAudioInterface();

}


float ofApp::millisec2samples(float _millisec)
{
	float sampleRate = myCore.GetAudioState().sampleRate;
	float samples = ((_millisec * sampleRate ) / 1000.0);

	return samples;
}

float ofApp::samples2millisec(float _samples)
{
	float sampleRate = myCore.GetAudioState().sampleRate;
	float millisec = (_samples * 1000.0) / sampleRate;

	return millisec;
}

float ofApp::meters2samples(float _meters)
{
	float soundSpeed = myCore.GetMagnitudes().GetSoundSpeed();
	float sampleRate = (float)myCore.GetAudioState().sampleRate;
	float samples = ((_meters * sampleRate) / soundSpeed);
	
	return samples;
}

float ofApp::samples2meters (float _samples)
{
	float soundSpeed = myCore.GetMagnitudes().GetSoundSpeed();
	float sampleRate = myCore.GetAudioState().sampleRate;
	float meters = (_samples * soundSpeed) / sampleRate;
	return meters;
}

float ofApp::millisec2meters(float _millisec)
{
	float soundSpeed = myCore.GetMagnitudes().GetSoundSpeed();
	float meters = soundSpeed * _millisec / 1000;
	return meters;
}

float ofApp::meters2millisec(float _meters)
{
	float soundSpeed = myCore.GetMagnitudes().GetSoundSpeed();
	float millisec = (_meters * 1000) / soundSpeed;
	return millisec;
}

float ofApp::meters2secs(float _meters)
{
	float soundSpeed = myCore.GetMagnitudes().GetSoundSpeed();
	float millisec = (_meters) / soundSpeed;
	return millisec;
}

void ofApp::recordIrOffline(bool &_active)
{
	recordingOffline = true;               
	boolRecordingIR = true;
	offlineRecordBuffers = 0;
	recordingPercent = 0.0f;
	offlineRecordIteration = 0;
	recordOfflineIRControl = false;

	if (!stopState) audioInterfaceController->StopAudioInterface();
	stopState = true;
	playState = false;
	playToStopControl.set("Stop", true);
	stopToPlayControl.set("Play", false);
}

void ofApp::recordWavOffline(bool& _active)
{
	recordingOffline = true;               
	boolRecordingIR = false;
	offlineRecordBuffers = 0;
	recordingPercent = 0.0f;
	offlineRecordIteration = 0;
	recordOfflineWAVControl = false;

	if (!stopState) audioInterfaceController->StopAudioInterface();
	stopState = true;
	playState = false;
	playToStopControl.set("Stop", true);
	stopToPlayControl.set("Play", false);
}

void ofApp::changeSecondsToRecordIR(float &_secondsToRecordIR)
{
	if (_secondsToRecordIR > 0 && _secondsToRecordIR <=MAX_SECONDS_TO_RECORD)
	{
		secondsToRecordIR = _secondsToRecordIR;
		numberOfSecondsToRecordControl.set(secondsToRecordIR);
	}
	   
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
	
	ofFileDialogResult openFileResult = ofSystemLoadDialog("Select a WAV file to Play");
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
			cout << "ERROR: Load new WAV File - Extension must be WAV " << endl << endl;
			if (!stopState) audioInterfaceController->StartAudioInterface();
			return;
		}
	}
	else {
		ofLogError() << "Couldn't load file";
		cout << "ERROR: Load new WAV File - Couldn't load file " << endl << endl;
		if (!stopState) audioInterfaceController->StartAudioInterface();
		return;
	}
	source1Wav.setInitialPosition();
	if (!stopState)  audioInterfaceController->StartAudioInterface();
}

void ofApp::resetAudio()
{
	if (!stopState) audioInterfaceController->StopAudioInterface();
	lock_guard < mutex > lock(audioMutex);

	anechoicSourceDSP->ResetSourceBuffers();				  //Clean buffers

	for (int i = 0; i < imageSourceDSPList.size(); i++)
		imageSourceDSPList.at(i)->ResetSourceBuffers();
	environment->ResetReverbBuffers();
	
	myCore.RemoveEnvironment(environment);



	//Environment setup
	environment = myCore.CreateEnvironment();									// Creating environment to have reverberated sound
	environment->SetReverberationOrder(reverberationOrder);		                // Setting number of ambisonic channels to use in reverberation processing
	string pathData = ofToDataPath("");
	string pathResources = ofToDataPath("resources");
	BRIR::CreateFromSofa(fullPathBRIR, environment);							// Loading SOFAcoustics BRIR file and applying it to the e
	
	// setup of the image sources
	reCreateImageSourceDSP();
}

void ofApp::playToStop(bool &_active)
{
	if (setupDone == false) return;
		
	if (playToStopControl && playState)
	{
		lock_guard < mutex > lock(audioMutex);	                  // Avoids race conditions with audio thread when cleaning buffers					
		if (!stopState) audioInterfaceController->StopAudioInterface();
		
		environment->ResetReverbBuffers();
		anechoicSourceDSP->ResetSourceBuffers();				  //Clean buffers

		//imageSourceDSPList = reCreateImageSourceDSP();
		for (int i = 0; i < imageSourceDSPList.size(); i++)
			imageSourceDSPList.at(i)->ResetSourceBuffers();
			
		stopState = true;
		playState = false;
		playToStopControl.set("Stop", true);
		stopToPlayControl.set("Play", false);
	}
	else if (!playToStopControl && stopState)
	{
		playToStopControl.set("Stop", true);
		stopToPlayControl.set("Play", false);
	}
}

void ofApp::stopToPlay(bool &_active)
{
	if (setupDone == false) return;
		
	if (stopToPlayControl && stopState) 
	{
		lock_guard < mutex > lock(audioMutex);	                  // Avoids race conditions with audio thread when cleaning buffers			
		stopState = false;
		playState = true;
		source1Wav.setInitialPosition();
		audioInterfaceController->StartAudioInterface();
		playToStopControl.set("Stop", false);
		stopToPlayControl.set("Play", true);
		
	}
	else if (!stopToPlayControl && playState) 
	{
		playToStopControl.set("Stop", false);
		stopToPlayControl.set("Play", true);
	}
}

void ofApp::changeRoomGeometry(bool &_active)
{
	string fileNameUsr;
	changeRoomGeometryControl = false;

	if (setupDone == false) return;
	
	lock_guard < mutex > lock(audioMutex);

	if (!stopState) audioInterfaceController->StopAudioInterface();

	stopState = true;
	playState = false;
	playToStopControl.set("Stop", true);
	stopToPlayControl.set("Play", false);

	ISM::RoomGeometry newRoom;
		
	string pathData = ofToDataPath("", false);
	ofFileDialogResult openFileResult;
	string fileExtension, fileName, fullPath;
	if (changeFileFromOSC) {
		string pathResources = ofToDataPath("resources");
		openFileResult.filePath = pathResources;
		openFileResult.fileName = charFilenameOSC;
		fullPath = pathResources + "\\" + charFilenameOSC;
		ofFile file(fullPath);
		if (file.exists()) {
			openFileResult.bSuccess = true;
			fileExtension = ofToUpper(file.getExtension());
		}
		else
			openFileResult.bSuccess = false;
	}
	else {
		openFileResult = ofSystemLoadDialog("Select a XML file with the new configuration of the room");
		ofFile file(openFileResult.getPath());
		fileExtension = ofToUpper(file.getExtension());
		fullPath = openFileResult.getPath();
		fileName = openFileResult.getName();
	}
	//Check if the user opened a file
	if (openFileResult.bSuccess) {
		ofLogVerbose("The file exists - now checking the type via file extension");
		if (fileExtension == "XML")
		{
			if (!xml.load(fullPath))
			{
				ofLogError() << "Couldn't load file";
				cout << "ERROR: Load new ROOM - Couldn't load file " << endl << endl;
				if (!stopState) audioInterfaceController->StartAudioInterface();
				return;
			}
		}
		else
		{
			ofLogError() << "Extension must be XML";
			cout << "ERROR: Load new ROOM - Extension must be XML " << endl << endl;
			if (!stopState) audioInterfaceController->StartAudioInterface();
			return;
		}
	}
	else {
		ofLogError() << "Couldn't load file";
		cout << "ERROR: Load new ROOM - Couldn't load file " << endl << endl;
		if (!stopState) audioInterfaceController->StartAudioInterface();
		return;
	}


		/////////////Read the XML file with the geometry of the room and absorption of the walls////////

		// select all corners and iterate through them
	auto cornersXml = xml.find("//ROOMGEOMETRY/CORNERS");
	if (cornersXml.empty()) {
		ofLogError() << "The file is not a room configuration";
		if (!stopState) audioInterfaceController->StartAudioInterface();
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
	//absortionsWalls.clear();
	/***********************/

	// select all walls and iterate through them
	auto wallsXml = xml.find("//ROOMGEOMETRY/WALLS");
	std::vector<std::vector<float>> absortionsWalls;
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
	
	//ISMHandler->setupArbitraryRoom(newRoom);
	mainRoom.setupRoomGeometry(newRoom);
	//ISMHandler->SetupRoom(mainRoom);	
	//Absortion as vector
	mainRoom.setWallAbsortion((std::vector<std::vector<float>>)  absortionsWalls);

	//ISMHandler->setReflectionOrder(0);

	//mainRoom = ISMHandler->getRoom();
	//reCreateImageSourceDSP();

	
	//listener located in the center of the room
	//Common::CVector3 roomCenter = ISMHandler->getRoom().getCenter();
	//Common::CVector3 listenerLocation(roomCenter);
	//Common::CTransform listenerPosition = Common::CTransform();
	//listenerPosition.SetPosition(listenerLocation);
	//listener->SetListenerTransform(listenerPosition);

	//moveSource(Common::CVector3(0, 0, 0));
	
	
	//ISMHandler->setReflectionOrder(INITIAL_REFLECTION_ORDER);
	reflectionOrderControl.set(INITIAL_REFLECTION_ORDER);
	//mainRoom = ISMHandler->getRoom();
	//reCreateImageSourceDSP();
		
	int numWalls = mainRoom.getWalls().size();
	guiActiveWalls.resize(numWalls);

	for (int i = 0; i < numWalls; i++)
	{
		if (guiActiveWalls.at(i) == false) 	guiActiveWalls.at(i) = true;
	}

	//mainRoom = ISMHandler->getRoom();
	//if (!stopState) audioInterfaceController->StartAudioInterface();

	cout << "Load new ROOM" << endl << endl;

#if 0
//lock_guard < mutex > lock(audioMutex);	                  // Avoids race conditions with audio thread when cleaning buffers
	stopState = false;
	playState = true;
	source1Wav.setInitialPosition();
	audioInterfaceController->StartAudioInterface();
	playToStopControl.set("Stop", false);
	stopToPlayControl.set("Play", true);
#endif
	
}

void ofApp::toggleWall(bool &_active)
{
	refreshActiveWalls();
}

void ofApp::toggleAnechoic(bool &_active)
{
	if (!setupDone)	return;

	if (stateAnechoicProcess == _active) return;

	if (stateAnechoicProcess)
	{
		anechoicSourceDSP->DisableAnechoicProcess();
		stateAnechoicProcess = false;
		anechoicEnableControl.set(false);
	}
	else
	{
		anechoicSourceDSP->EnableAnechoicProcess();
		stateAnechoicProcess = true;
		anechoicEnableControl.set(true);
	}
}

void ofApp::changeHRTF(bool& _active)
{
	changeHRTFControl = false;
	if (setupDone == false) return;

	if (!stopState) audioInterfaceController->StopAudioInterface();

	stopState = true;
	playState = false;
	playToStopControl.set("Stop", true);
	stopToPlayControl.set("Play", false);
		
	string pathData = ofToDataPath("", false);

	ofFileDialogResult openFileResult;
	string fileExtension, fileName, fullPath;
	if (changeFileFromOSC) {
		string pathResources = ofToDataPath("resources");
		openFileResult.filePath = pathResources;
		openFileResult.fileName = charFilenameOSC;
		fullPath = pathResources + "\\" + charFilenameOSC;
		ofFile file(fullPath);
		if (file.exists()) {
			openFileResult.bSuccess = true;
			fileExtension = ofToUpper(file.getExtension());
		}
		else
			openFileResult.bSuccess = false;
	}
	else {
		openFileResult = ofSystemLoadDialog("Select a SOFA file with the new HRTF");
		ofFile file(openFileResult.getPath());
		fileExtension = ofToUpper(file.getExtension());
		fullPath = openFileResult.getPath();
		fileName = openFileResult.getName();
	}

	//Check if the user opened a file
	if (openFileResult.bSuccess) {
		ofLogVerbose("The file exists - now checking the type via file extension");
		if (fileExtension == "SOFA")
		{
			fullPathHRTF = fullPath;
			bool specifiedDelays;
			bool sofaLoadResult = HRTF::CreateFromSofa(fullPathHRTF, listener, specifiedDelays);

			if (!sofaLoadResult) {
				cout << "ERROR: Error trying to load the SOFA file" << endl << endl;
				if (!stopState) audioInterfaceController->StartAudioInterface();
				return;
			}
			else
			{
				cout << "Load new HRTF File " << fullPathHRTF << endl  << endl;
			}
		}
		else
		{
			ofLogError() << "Extension must be SOFA";
			cout << "ERROR: Load new HRTF File - Extension must be SOFA " << endl << endl;
			if (!stopState) audioInterfaceController->StartAudioInterface();
			return;
		}
	}
	else 
	{
		ofLogError() << "Couldn't load file";
		cout << "ERROR: Load new HRTF File - Couldn't load file " << endl << endl;
		if (!stopState) audioInterfaceController->StartAudioInterface();
		return;
	}

	if (!stopState) audioInterfaceController->StartAudioInterface();
}

void ofApp::changeBRIR(bool& _active)
{
	changeBRIRControl = false;
	if (setupDone == false) return;

	if (!stopState) audioInterfaceController->StopAudioInterface();

	stopState = true;
	playState = false;
	playToStopControl.set("Stop", true);
	stopToPlayControl.set("Play", false);

	string pathData = ofToDataPath("", false);
	
	ofFileDialogResult openFileResult;
	string fileExtension, fileName, fullPath;
	if (changeFileFromOSC) {
		string pathResources = ofToDataPath("resources");
		openFileResult.filePath = pathResources;
		openFileResult.fileName = charFilenameOSC;
		fullPath = pathResources + "\\" + charFilenameOSC;
		ofFile file(fullPath);
		if (file.exists()) {
			openFileResult.bSuccess = true;
			fileExtension = ofToUpper(file.getExtension());
		}
		else
			openFileResult.bSuccess = false;
	}
	else {
		openFileResult = ofSystemLoadDialog("Select a SOFA file with the new BRIR of the room");
		ofFile file(openFileResult.getPath());
		fileExtension = ofToUpper(file.getExtension());
		fullPath = openFileResult.getPath();
		fileName = openFileResult.getName();
	}

	//Check if the user opened a file
	if (openFileResult.bSuccess) {
		ofLogVerbose("The file exists - now checking the type via file extension");
		if (fileExtension == "SOFA")
		{
			//char* charFilename = new char[fullPath.length() + 1];
			//strcpy(charFilename, fullPath.c_str());
			fullPathBRIR = fullPath;
			bool sofaLoadResult = BRIR::CreateFromSofa(fullPathBRIR, environment); // Loading SOFAcoustics BRIR file and applying it to the environment
			
			if (!sofaLoadResult) {
				cout << "ERROR: Error trying to load the SOFA BRIR file" << endl << endl;
				if (!stopState) audioInterfaceController->StartAudioInterface();
				return;
			}
			else
			{
				cout << "Load new BRIR File " << fullPathBRIR << endl << endl;
				int BRIRLength = environment->GetBRIR()->GetBRIRLength();
				float sampleRate = myCore.GetAudioState().sampleRate;
				float secToRecordIR = ((float)BRIRLength) / sampleRate;
				changeSecondsToRecordIR(secToRecordIR);
			}
		}
		else
		{
			ofLogError() << "Extension must be SOFA";
			cout << "ERROR: Load new BRIR File - Extension must be SOFA " << endl << endl;
			if (!stopState) audioInterfaceController->StartAudioInterface();
			return;
		}
	}
	else
	{
		ofLogError() << "Couldn't load file";
		cout << "ERROR: Load new BRIR File - Couldn't load file " << endl << endl;
		if (!stopState) audioInterfaceController->StartAudioInterface();
		return;
	}

	if (!stopState) audioInterfaceController->StartAudioInterface();
}


void ofApp::toggleBinauralSpatialisation(bool& _active)
{
	if (!setupDone) return;
			
	if (!stopState) audioInterfaceController->StopAudioInterface();

	if (stateBinauralSpatialisation)
	{
		anechoicSourceDSP->SetSpatializationMode(Binaural::TSpatializationMode::NoSpatialization);
		stateBinauralSpatialisation = false;
	}
	else
	{
		anechoicSourceDSP->SetSpatializationMode(Binaural::TSpatializationMode::HighQuality);
		stateBinauralSpatialisation = true;
	}
	
	reCreateImageSourceDSP();

	if (!stopState) audioInterfaceController->StartAudioInterface();
}

void ofApp::toggleISM(bool& active) {
	if (!setupDone) return;
	stateISMProcess = !stateISMProcess;

	if (!stateISMProcess) {
		for (int i = 0; i < imageSourceDSPList.size(); i++)
			imageSourceDSPList.at(i)->ResetSourceBuffers();
	}
}

void ofApp::toggleReverb(bool &_active)
{
	if (!setupDone) return;
	if (!stopState) audioInterfaceController->StopAudioInterface();
	stateBRIRReverbProcess = !stateBRIRReverbProcess;
	
	if (!stateBRIRReverbProcess) {
		anechoicSourceDSP->ResetSourceBuffers();	//Clean buffers
		//imageSourceDSPList = reCreateImageSourceDSP();	
		for (int i = 0; i < imageSourceDSPList.size(); i++)
			imageSourceDSPList.at(i)->ResetSourceBuffers();
		environment->ResetReverbBuffers();
	}		
	
	if (!stopState) audioInterfaceController->StartAudioInterface();
}

void ofApp::refreshActiveWalls()
{
	/*if (!stopState) audioInterfaceController->StopAudioInterface();
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
	
	float maxDistanceImageSources = maxDistanceImageSourcesToListenerControl.get();
	float windowSlopeInMeters = millisec2meters(currentWindowSlopeWidth);
	int order = (int)reflectionOrderControl.get();
	ISMHandler2->Setup(order, maxDistanceImageSources, windowSlopeInMeters, mainRoom);

	reCreateImageSourceDSP();

	if (!stopState) audioInterfaceController->StartAudioInterface();*/
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
	for (int i = 0; i < recordBuffer.left.size(); i++) {
		if (abs(recordBuffer.left[i]) > 1.0 || abs(recordBuffer.right[i]) > 1.0) {
			cout << "SAMPLES OUT OF RANGE!" << "\n";
		}
	}
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
		audioInterfaceController->StopAudioInterface();
	}
}
//---------------------------------------------------------------
void ofApp::StartSystemSoundStream()
{
	if (!systemSoundStream_Started)
	{
		systemSoundStream_Started = true;
		audioInterfaceController->StartAudioInterface();
	}
}


void ofApp::ShowRecordingDurationTime() {
	/*auto duration = std::chrono::duration_cast<std::chrono::seconds>(stopRecordingOfflineTime - startRecordingOfflineTime);
	std::cout << "Time taken to do the recording offline: "	<< duration.count() << " seconds" << endl;*/
	
	auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(stopRecordingOfflineTime - startRecordingOfflineTime);
	std::cout << "Time taken to do the recording offline: " << duration.count() << " milliseconds" << endl;
}

// OSC
void ofApp::OscCallback(const ofxOscMessage& message) {

	if (message.getAddress() == "/play")					OscCallBackPlay();
	else if (message.getAddress() == "/stop")				OscCallBackStop();
	else if (message.getAddress() == "/playAndRecord")		OscCallBackPlayAndRecord();
	else if (message.getAddress() == "/coefficients")		OscCallBackCoefficients(message);
	else if (message.getAddress() == "/reverbGain")		    OscCallBackReverbGain(message);
	else if (message.getAddress() == "/distMaxImgs")		OscCallBackDistMaxImgs(message);
	else if (message.getAddress() == "/windowSlope")		OscCallBackWindowSlope(message);
	else if (message.getAddress() == "/reflectionOrder")	OscCallBackReflectionOrder(message);
	else if (message.getAddress() == "/saveIR")	            OscCallBackSaveIR();
	else if (message.getAddress() == "/directPathEnable")	OscCallBackDirectPathEnable(message);
	else if (message.getAddress() == "/spatialisationEnable")	    OscCallBackSpatialisationEnable(message);
	else if (message.getAddress() == "/distanceAttAnechoicEnable")	OscCallBackDistanceAttenuationEnable(message);
	else if (message.getAddress() == "/distanceAttReverbEnable")    OscCallBackDistanceAttenuationReverbEnable(message);
	else if (message.getAddress() == "/reverbEnable")	    OscCallBackReverbEnable(message);
	else if (message.getAddress() == "/absortions")		    OscCallBackAbsortions(message);
	else if (message.getAddress() == "/changeRoom") OscCallBackChangeRoom (message);
	else if (message.getAddress() == "/changeHRTF") OscCallBackChangeHRTF(message);
	else if (message.getAddress() == "/changeBRIR") OscCallBackChangeBRIR (message);
	else if (message.getAddress() == "/listenerLocation") OscCallBackListenerLocation(message);
	else if (message.getAddress() == "/listenerOrientation") OscCallBackListenerOrientation(message);
	else if (message.getAddress() == "/sourceLocation") OscCallBackSourceLocation(message);
	else if (message.getAddress() == "/workFolder") OscCallBackChangeWorkFolder(message);
	else if (message.getAddress() == "/timeRecordIR") OscCallBackChangeTimeSaveIR(message);
	else if (message.getAddress() == "/reverbOrder") OscCallBackChangeReverbOrder(message);


	else std::cout << "Message OSC not recognised " << message << std::endl;
}

void ofApp::OscCallBackPlay() {
	std::cout << "Received Play" << std::endl;
	playToStopControl.set("Stop", false);
	stopToPlayControl.set("Play", true);
	
	SendOSCMessageToMatlab_Ready();
}

void ofApp::OscCallBackStop() {
	std::cout << "Received Stop" << std::endl;
	playToStopControl.set("Stop", true);
	stopToPlayControl.set("Play", false);
	
	SendOSCMessageToMatlab_Ready();
}

void ofApp::OscCallBackPlayAndRecord() {
	std::cout << "Received Play And Record" << std::endl;
}

void ofApp::OscCallBackCoefficients(const ofxOscMessage& message) {
	
	message.getNumArgs();
	std::vector<float> v;
	std::vector<float> absorWall ={0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0};
	
	for (int i = 0; i < message.getNumArgs(); i++) {
		v.push_back(message.getArgAsFloat(i));
	}
	int numWalls = mainRoom.getWalls().size();
	std::vector<std::vector<float>> absortionsWalls;
	for (int i = 0; i < numWalls; i++) {
		//absortionsWalls.at(i) = { 0.7, 0.7, 0.7, 0.7, 0.7, 0.7, 0.7, 0.7, 0.7 };
		for (int k = 0; k < 9; k++){
			absorWall[k] = v[i*9 + k];
	     }
		absortionsWalls.push_back(absorWall);
	}
	mainRoom.setWallAbsortion((std::vector<std::vector<float>>)  absortionsWalls);
	ReconfigureISM();
	// DO whatever
	//std::cout<< v[0]  << "," << v[1]  <<","  << v[2]  << "," << v[3]  << "," << v[4]  << "," << v[5]  << "," << v[6]  << ","  << v[7]  << "," << v[8] << std::endl;
	//std::cout<< v[36] << "," << v[37] << "," << v[38] << "," << v[39] << "," << v[40] << "," << v[41] << "," << v[42] << "," << v[43] << "," << v[44] << std::endl;
	//std::cout<< v[45] << "," << v[46] << "," << v[47] << "," << v[48] << "," << v[49] << "," << v[50] << "," << v[51] << ","  << v[52] << "," << v[53] << std::endl;
	for (int i = 0; i < 6; i++) {
		for (int j = 0; j < 9; j++) {
			std::cout << absortionsWalls.at(i).at(j) << ", ";
		}
		std::cout << std::endl;
	}

	recordOfflineIRScanControl.set(true);
}

void ofApp::OscCallBackReverbGain(const ofxOscMessage& message) {
	message.getNumArgs();
	
	reverbGainLinear = message.getArgAsFloat(0);
	std::cout << "Received ReverbGain Command"<<",  "<< reverbGainLinear << std::endl;
	float reverbGainDb = 20 * log10(reverbGainLinear);
	reverbGainControl.set(reverbGainDb);

	if (!stopState) audioInterfaceController->StopAudioInterface();
	playToStopControl.set("Stop", true);
	stopToPlayControl.set("Play", false);

	float windowThreshold = winThresholdControl.get();
	environment->SetFadeInWindow((0.001) * windowThreshold, (0.001 * currentWindowSlopeWidth), reverbGainLinear);

	reCreateImageSourceDSP();
	if (!stopState) audioInterfaceController->StartAudioInterface();
	SendOSCMessageToMatlab_Ready();
}


void ofApp::OscCallBackDistMaxImgs(const ofxOscMessage& message) {
	message.getNumArgs();
	
	float maxDistImagesToListener = message.getArgAsFloat(0);  //getArgAsFloat(0);	
	std::cout << "Received DistanceMaxImages Command"<<",  "<< maxDistImagesToListener << std::endl;

	if (!stopState) audioInterfaceController->StopAudioInterface();
		
	changeMaxDistanceImageSources(maxDistImagesToListener);	
	reCreateImageSourceDSP();
	SendOSCMessageToMatlab_Ready();
}

void ofApp::OscCallBackWindowSlope(const ofxOscMessage& message) {
	message.getNumArgs();

	int newWindowSlope = message.getArgAsInt(0);  //getArgAsFloat(0);	
	std::cout << "Received WindowSlope Command"<<",  " << newWindowSlope << std::endl;

	if (!stopState) audioInterfaceController->StopAudioInterface();
	
	changeWindowSlope(newWindowSlope);
	windowSlopeControl.set(newWindowSlope);
	reCreateImageSourceDSP();
	SendOSCMessageToMatlab_Ready();
}


void ofApp::OscCallBackReflectionOrder(const ofxOscMessage& message) {
	message.getNumArgs();
	
	int reflectionOrder = message.getArgAsInt(0);  
	std::cout << "Received ReflectionOrder Command" << ",  " << reflectionOrder << std::endl;

	if (!stopState) audioInterfaceController->StopAudioInterface();
	
	reflectionOrderControl.set(reflectionOrder);
	changeReflectionOrder(reflectionOrder);
	reCreateImageSourceDSP();
	SendOSCMessageToMatlab_Ready();
}

void ofApp::OscCallBackSaveIR() {

	if (!stopState) audioInterfaceController->StopAudioInterface();
	
	std::cout << "Received Save IR" << std::endl;
	float maxDistanceSourcesToListener = maxDistanceImageSourcesToListenerControl.get();
	cout << "MaxDist =" << maxDistanceSourcesToListener << "\n";
	recordOfflineIRControl.set(true);
}

void ofApp::OscCallBackDirectPathEnable(const ofxOscMessage& message) {
	message.getNumArgs();
	
	bool state = message.getArgAsBool(0);
	std::cout << "Received DirectPathEnableDisable Command" << ",  " << state << std::endl;

	if (state){
		if (anechoicEnableControl.get())
	    ;
		else {
			anechoicSourceDSP->EnableAnechoicProcess();
			//anechoicEnableControl = true;
			anechoicEnableControl.set(true);
			stateAnechoicProcess = true;
		}
	}
	else {
		if ( ! anechoicEnableControl.get())
		;
		else {
			anechoicSourceDSP->DisableAnechoicProcess();
			//anechoicEnableControl = false;
			anechoicEnableControl.set(false);
			stateAnechoicProcess = false;
		}
	}
	SendOSCMessageToMatlab_Ready();
}

void ofApp::OscCallBackSpatialisationEnable(const ofxOscMessage& message) {
	message.getNumArgs();

	bool state = message.getArgAsBool(0);
	std::cout << "Received EspatialisationEnable Command" << ",  " << state << std::endl;

	if (!stopState) audioInterfaceController->StopAudioInterface();

	if (state)
	{
		if (stateBinauralSpatialisation)
		;
		else {
			anechoicSourceDSP->SetSpatializationMode(Binaural::TSpatializationMode::HighQuality);
			binauralSpatialisationEnableControl.set(true);
			stateBinauralSpatialisation = true;
		}
	}
	else
	{
		if ( ! stateBinauralSpatialisation)
			;
		else {
			anechoicSourceDSP->SetSpatializationMode(Binaural::TSpatializationMode::NoSpatialization);
			binauralSpatialisationEnableControl.set(false);
			stateBinauralSpatialisation = false;
		}
	}

	reCreateImageSourceDSP();

	if (!stopState) audioInterfaceController->StartAudioInterface();

	SendOSCMessageToMatlab_Ready();
}


void ofApp::OscCallBackReverbEnable(const ofxOscMessage& message) {
	message.getNumArgs();

	bool state = message.getArgAsBool(0);
	std::cout << "Received ReverbPathEnableDisable Command" << ",  " << state << std::endl;
		
	stateBRIRReverbProcess = state;
	reverbEnableControl.set(stateBRIRReverbProcess);	

	//anechoicSourceDSP->ResetSourceBuffers();				//Clean buffers
	//imageSourceDSPList = reCreateImageSourceDSP();
	//for (int i = 0; i < imageSourceDSPList.size(); i++)
	//	imageSourceDSPList.at(i)->ResetSourceBuffers();
	//environment->ResetReverbBuffers();
	
	if (setupDone == false) std::chrono::milliseconds::duration(2000);

	SendOSCMessageToMatlab_Ready();
}

void ofApp::OscCallBackDistanceAttenuationEnable(const ofxOscMessage& message) {
	message.getNumArgs();

	bool state = message.getArgAsBool(0);
	std::cout << "Received DistanceAttenuationAnechoicEnableDisable Command" << ",  " << state << std::endl;
	if (state) {
		anechoicSourceDSP->EnableDistanceAttenuationAnechoic();
		stateDistanceAttenuationAnechoic = true;
	}
	else {
		anechoicSourceDSP->DisableDistanceAttenuationAnechoic();
		stateDistanceAttenuationAnechoic = false;
	}
	SendOSCMessageToMatlab_Ready();
}

void ofApp::OscCallBackDistanceAttenuationReverbEnable(const ofxOscMessage& message) {
	message.getNumArgs();

	bool state = message.getArgAsBool(0);
	std::cout << "Received DistanceAttenuationReverbEnableDisable Command" << ",  " << state << std::endl;
	if (state) {
		anechoicSourceDSP->EnableDistanceAttenuationReverb();
		stateDistanceAttenuationReverb = true;
	}
	else {
		anechoicSourceDSP->DisableDistanceAttenuationReverb();
		stateDistanceAttenuationReverb = false;
	}
	SendOSCMessageToMatlab_Ready();
}

void ofApp::OscCallBackAbsortions(const ofxOscMessage& message) {

	message.getNumArgs();
	std::vector<float> v;
	std::vector<float> absorWall = { 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 };

	std::cout << "Received Absortions Command" << std::endl;

	for (int i = 0; i < message.getNumArgs(); i++) {
		v.push_back(message.getArgAsFloat(i));
	}
	int numWalls = mainRoom.getWalls().size();
	std::vector<std::vector<float>> absortionsWalls;
	for (int i = 0; i < numWalls; i++) {
		for (int k = 0; k < 9; k++) {
			absorWall[k] = v[i * 9 + k];
		}
		absortionsWalls.push_back(absorWall);
	}
	mainRoom.setWallAbsortion((std::vector<std::vector<float>>)  absortionsWalls);
	ReconfigureISM();
	for (int j = 0; j < 9; j++) {
		std::cout << absortionsWalls.at(0).at(j) << ", ";
	}
	std::cout << std::endl;
	SendOSCMessageToMatlab_Ready();
}


void ofApp::OscCallBackChangeRoom(const ofxOscMessage& message) {
	changeFileFromOSC = true;

	std::string filemaneOSC = message.getArgAsString(0);

	charFilenameOSC = new char[filemaneOSC.length() + 1];
	strcpy(charFilenameOSC, filemaneOSC.c_str());

	std::cout << "Received ChangeRoom Command" << ",  " << charFilenameOSC << std::endl;

	changeRoomGeometryControl.set(true);

	changeFileFromOSC = false;
	SendOSCMessageToMatlab_Ready();

}

void ofApp::OscCallBackChangeHRTF(const ofxOscMessage& message) {
	changeFileFromOSC = true;

	std::string filemaneOSC = message.getArgAsString(0);

	charFilenameOSC = new char[filemaneOSC.length() + 1];
	strcpy(charFilenameOSC, filemaneOSC.c_str());

	std::cout << "Received changeHRTF Command" << ",  " << charFilenameOSC << std::endl;

	changeHRTFControl.set(true);

	changeFileFromOSC = false;
	SendOSCMessageToMatlab_Ready();
}

void ofApp::OscCallBackChangeBRIR(const ofxOscMessage& message) {
	changeFileFromOSC = true;

	std::string filemaneOSC = message.getArgAsString(0);

	charFilenameOSC = new char[filemaneOSC.length() + 1];
	strcpy(charFilenameOSC, filemaneOSC.c_str());

	std::cout << "Received changeBRIR Command" << ",  " << charFilenameOSC << std::endl;

	changeBRIRControl.set(true);

	changeFileFromOSC = false;
	SendOSCMessageToMatlab_Ready();
}

void ofApp::OscCallBackChangeWorkFolder(const ofxOscMessage& message) {
	
	std::string folderOSC = message.getArgAsString(0);

	charFolderOSC = new char[folderOSC.length() + 1];
	strcpy(charFolderOSC, folderOSC.c_str());

	std::cout << "Received changeWorkFolder Command" << ",  " << charFolderOSC << std::endl;

	SendOSCMessageToMatlab_Ready();
}

void ofApp::OscCallBackChangeTimeSaveIR(const ofxOscMessage& message) {

	float secondsToRecordIR = message.getArgAsFloat(0);  //getArgAsFloat(0);	
	std::cout << "Received Change Time to Record IR Command" << ",  " << secondsToRecordIR << std::endl;

	changeSecondsToRecordIR(secondsToRecordIR);

	SendOSCMessageToMatlab_Ready();
}

void ofApp::OscCallBackChangeReverbOrder(const ofxOscMessage& message) {

	int reverbOrder = message.getArgAsInt(0);  
	std::cout << "Received Change Reverberation Order Command" << ",  " << reverbOrder << std::endl;
	
	if (reverbOrder == 0) {
		reverberationOrder = ADIMENSIONAL;
		environment->SetReverberationOrder(reverberationOrder);
	}
	else if (reverbOrder == 1) {
		reverberationOrder = BIDIMENSIONAL;
		environment->SetReverberationOrder(reverberationOrder);
	}
	else if (reverbOrder == 2)	{
	    reverberationOrder = THREEDIMENSIONAL;
	    environment->SetReverberationOrder(reverberationOrder);
	}
	else
		std::cout << "Error: Reverberation Order out of range " << ",  " << reverberationOrder << std::endl;

	SendOSCMessageToMatlab_Ready();
}



void ofApp::OscCallBackListenerLocation(const ofxOscMessage& message) {

	message.getNumArgs();
	std::vector<float> c;
	for (int i = 0; i < message.getNumArgs(); i++) {
		c.push_back(message.getArgAsFloat(i));
	}
	std::cout << "Received Listener Location Command" << ",  " << c[0] << ", " << c[1] << ", " << c[2] << std::endl;

	Common::CTransform listenerTransformOld = listener->GetListenerTransform();
	Common::CVector3 listenerLocationOld = listenerTransformOld.GetPosition();
	Common::CTransform listenerPositionNew = Common::CTransform();
	Common::CVector3 listenerLocationNew(c[0], c[1], c[2]);

	//mainRoom = ISMHandler->getRoom();
	float distanceNearestWall;
	bool result = mainRoom.checkPointInsideRoom(listenerLocationNew, distanceNearestWall);
	if (result){
		listenerPositionNew.SetPosition(listenerLocationNew);
		listener->SetListenerTransform(listenerPositionNew);
	}

	//ISMHandler->setReflectionOrder(INITIAL_REFLECTION_ORDER);
	//reflectionOrderControl = INITIAL_REFLECTION_ORDER;
	//mainRoom = ISMHandler->getRoom();	
	//reCreateImageSourceDSP();
	ISMHandler2->SetListenerPosition();
	SendOSCMessageToMatlab_Ready();
}

void ofApp::OscCallBackListenerOrientation(const ofxOscMessage& message) {

	message.getNumArgs();
	std::vector<float> c;
	for (int i = 0; i < message.getNumArgs(); i++) {
		c.push_back(message.getArgAsFloat(i));
	}
	std::cout << "Received Listener Orientation Command" << ",  " << c[0] << ", " << c[1] << ", " << c[2] << std::endl;

	Common::CTransform lT = listener->GetListenerTransform();
	Common::CVector3 lLocation = lT.GetPosition();
	Common::CQuaternion lO = lT.GetOrientation();

	float yaw, pitch, roll;
	yaw = c[0]; pitch = c[1]; roll = c[2];
	//lT.SetOrientation (lO.FromYawPitchRoll(yaw, pitch, roll));
	lT.Rotate(Common::CVector3(0, 0, 1), yaw);
	lT.Rotate(Common::CVector3(0, 1, 0), pitch);
	lT.Rotate(Common::CVector3(1, 0, 0), roll);
	listener->SetListenerTransform(lT);
		
	//ISMHandler->setReflectionOrder(0);
	//reflectionOrderControl = 0;
	
	Common::CVector3 axis, nose;
	nose.x = lLocation.x + cos(yaw);
	nose.y = lLocation.y + sin(yaw);
	nose.z = lLocation.z;
    ofLine(lLocation.x, lLocation.y, lLocation.z,
	nose.x, nose.y, nose.z);

	SendOSCMessageToMatlab_Ready();
}


void ofApp::OscCallBackSourceLocation(const ofxOscMessage& message) {

	message.getNumArgs();
	std::vector<float> c;
	for (int i = 0; i < message.getNumArgs(); i++) {
		c.push_back(message.getArgAsFloat(i));
	}
	std::cout << "Received Source Location Command" << ",  " << c[0] << ", " << c[1] << ", " << c[2] << std::endl;
	
	Common::CVector3 newLocation = Common::CVector3(c[0], c[1], c[2]);
	//mainRoom = ISMHandler->getRoom();
	float distanceNearestWall;
	bool result = mainRoom.checkPointInsideRoom(newLocation, distanceNearestWall);
	if (result)			
	{
		ISMHandler2->setSourceLocation(newLocation);
		Common::CTransform sourcePosition;
		sourcePosition.SetPosition(newLocation);
		anechoicSourceDSP->SetSourceTransform(sourcePosition);
	}
	SendOSCMessageToMatlab_Ready();
}


void ofApp::SendOSCMessageToMatlab_Ready() {
	oscManager.SendOSCCommand_ToMatlab();
}

// DANI

void ofApp::ShowImageSourceData(std::vector<ISM::ImageSourceData>& data, const Common::CVector3& listenerLocation)
{
	auto w2 = std::setw(2);
	auto w5 = std::setw(5);
	auto w6 = std::setw(6);
	auto w7 = std::setw(7);
	std::cout << "------------------------------------------------List of Source Images ---------------------------------------------\n";
	std::cout << "  Visibility | Refl. |                Reflection coeficients                 |        Location       | Dist. (Room)\n";
	std::cout << "             | order | ";
	float freq = 62.5;
	for (int i = 0; i < NUM_BAND_ABSORTION; i++)
	{
		if (freq < 100) { std::cout << ' '; }
		if (freq < 1000) { std::cout << ((int)freq) << "Hz "; }
		else { std::cout << w2 << ((int)(freq / 1000)) << "kHz "; }
		freq *= 2;
	}
	std::cout << "|    X       Y       Z  |  \n";
	std::cout << "-------------+-------+-------------------------------------------------------+-----------------------+--------\n";
	for (int i = 0; i < data.size(); i++)
	{
		if (data.at(i).visible) std::cout << "VISIBLE "; else std::cout << "        ";
		std::cout << w5 << std::fixed << std::setprecision(2) << data.at(i).visibility;							//print source visibility 
		std::cout << "|   " << data.at(i).reflectionWalls.size();												//print number of reflection needed for this source
		std::cout << "   | ";
		for (int j = 0; j < NUM_BAND_ABSORTION; j++)
		{
			std::cout << w5 << std::fixed << std::setprecision(2) << data.at(i).reflectionBands.at(j) << " ";	//print abortion coefficientes for a source
		}
		std::cout << "| " << w6 << std::fixed << std::setprecision(2) << data.at(i).location.x << ", ";			//print source location
		std::cout << w6 << std::fixed << std::setprecision(2) << data.at(i).location.y << ", ";
		std::cout << w6 << std::fixed << std::setprecision(2) << data.at(i).location.z << "|";

		std::cout << w6 << (data.at(i).location - listenerLocation).GetDistance();								//print distance to listener and distance between first and last reflection walls
		std::cout << " (" << data.at(i).reflectionWalls.front().getMinimumDistanceFromWall(data.at(i).reflectionWalls.back()) << ")" << "\n";
	}
	//std::cout << "Shoebox \n";
	//std::cout << "X=" << shoeboxLength << "\n" << "Y=" << shoeboxWidth << "\n" << "Z=" << shoeboxHeight << "\n";

	if (stateAnechoicProcess)
		std::cout << "AnechoicProcess Enabled" << "\n";
	else
		std::cout << "AnechoicProcess Disabled" << "\n";

	if (stateBinauralSpatialisation)
		std::cout << "BinauralSpatialisation Enabled" << "\n";
	else
		std::cout << "BinauralSpatialisation Disabled" << "\n";

	if (stateDistanceAttenuationAnechoic)
		std::cout << "DistanceAttenuationAnechoic Enabled" << "\n";
	else
		std::cout << "DistanceAttenuationAnechoic Disabled" << "\n";

	if (stateDistanceAttenuationReverb)
		std::cout << "DistanceAttenuationReverb Enabled" << "\n";
	else
		std::cout << "DistanceAttenuationReverb Disabled" << "\n";

	//#if 0
	if (stateBRIRReverbProcess)
	{
		std::cout << "Reverb Enabled" << "\n";
		std::cout << "Reverberation Order: " << reverberationOrder << "\n";
		std::cout << "Number of silenced frames= " << numberOfSilencedFrames << "\n";
	}
	else
		std::cout << "Reverb Disabled" << "\n";
	//#endif

	std::cout << "Max distance images to listener = " << ISMHandler2->getMaxDistanceImageSources() << "\n";

	Common::CTransform lT = listener->GetListenerTransform();
	Common::CVector3 lLocation = lT.GetPosition();
	Common::CQuaternion lO = lT.GetOrientation();
	float yaw, pitch, roll;
	lO.ToYawPitchRoll(yaw, pitch, roll);
	std::cout << "Yaw = " << (yaw * 180 / PI) << " Pitch = " << (pitch * 180 / PI) << " Roll = " << (roll * 180 / PI) << "\n";

	std::cout << "Absortions = ";
	std::vector<std::vector<float>> absortionsWalls = mainRoom.GetWallAbsortion();	
	for (int j = 0; j < NUM_BAND_ABSORTION; j++) {
		std::cout << absortionsWalls.at(0).at(j) << ", ";
	}
	std::cout << "\n";
}

void ofApp::ShowImagesSourceSummaryData(float maxDistanceImagesToListener, std::vector<ISM::ImageSourceData>& images)
{
	std::cout << "Max distance images to listener = " << std::to_string(maxDistanceImagesToListener) << std::endl;

	int numberOfVisibleImages = 0;
	for (int i = 0; i < images.size(); i++)
	{
		if (images.at(i).visible) numberOfVisibleImages++;
	}
	cout << "Total images = " << images.size();
	cout << " -- " << numberOfVisibleImages << " visible" << "\n";

	float soundSpeed = myCore.GetMagnitudes().GetSoundSpeed();
	cout << "Sound Speed = " << soundSpeed << "\n";
}

//int ofApp::CalculateNumOfSilencedSamples(float maxDistanceSourcesToListener)
//{	
//	int samplerate = myCore.GetAudioState().sampleRate;
//	float soundSpeed = myCore.GetMagnitudes().GetSoundSpeed();
//
//	int numberOfSlilencedSamples = floor((maxDistanceSourcesToListener * (float)samplerate / soundSpeed));
//
//	return numberOfSlilencedSamples;
//}

bool ofApp::is_equal(float a, float b) {
	constexpr float epsilon = std::numeric_limits<float>::epsilon();
    return std::fabs(a - b) < epsilon;
}

void ofApp::ReconfigureISM() {
	float windowSlopeInMeters = millisec2meters(currentWindowSlopeWidth);	
	ISMHandler2->Setup(currentReflectionOrder, currentMaxDistanceSourcesToListener, windowSlopeInMeters, mainRoom);
	reCreateImageSourceDSP();
}

void ofApp::ShowMessage(std::string message) {
	//guiManager.showMessage(message, _messageType);			
	std::cout << message << std::endl;	
}

