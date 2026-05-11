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
	stateISMProcess = true;	
	stateDistanceAttenuationAnechoic = true;
	stateDistanceAttenuationReverb = false;	
	stateBRIRReverbProcess = true;

	recordingFolder = RECORD_FOLDER;
	
	limitOrderToDrawImageRooms = 0;
	lastMouseX = -1;
	lastMouseY = -1;
	
	// Paths setup
	std::string pathData = ofToDataPath("");
	std::string pathResources = ofToDataPath("resources");

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
	//Common::CVector3 listenerLocation(-0.45, 0.02, -0.68);         // A108_ROOM
	//Common::CVector3 listenerLocation(-2.4, -1.5, -0.8);           // LAB_ROOM
	//Common::CVector3 listenerLocation(-1.5, 2.4, -0.8);            // LAB_ROOM_ROT
	Common::CTransform listenerPosition = Common::CTransform();	 // Setting listener in (0,0,0)
	//listenerPosition.SetPosition(listenerLocation);
	listener->SetListenerTransform(listenerPosition);		
	listener->DisableCustomizedITD();								 // Disabling custom head radius
	

	// Anechoic Source setup
	anechoicSourceDSP = myCore.CreateSingleSourceDSP();				// Creating audio source
	Common::CTransform sourcePosition;
	//Common::CVector3 initialLocation(2.0, 0.0, 0.15);             // Juntas_ROOM
	//Common::CVector3 initialLocation(1.55, 0.02, -0.68);            // A108_ROOM	
	//Common::CVector3 initialLocation(-2.4, -0.3, -0.8);           // LAB_ROOM
	//Common::CVector3 initialLocation(-0.3, 2.4, -0.8);            // LAB_ROOM_ROT	
	//sourcePosition.SetPosition(initialLocation);
	//anechoicSourceDSP->SetSourceTransform(sourcePosition);							//Set source position
	anechoicSourceDSP->SetSpatializationMode(Binaural::TSpatializationMode::HighQuality);	// Choosing high quality mode for anechoic processing
	anechoicSourceDSP->DisableNearFieldEffect();											// Audio source will not be close to listener, so we don't need near field effect	
	anechoicSourceDSP->EnableAnechoicProcess();										// Disable anechoic processing for this source
	// DistanceAttenuation	
	anechoicSourceDSP->DisableDistanceAttenuationReverb();
	anechoicSourceDSP->EnablePropagationDelay();
		
	// Define case studies	
	setupCaseStudies(pathResources);	
	// Load case of Study
	loadedCaseStudy = FindCaseStudy("roomB");	
	if (loadedCaseStudy.id == "") {
		std::cout << "Error loading case studies" << std::endl;
		return;	
	}	
	bool result = SetupCaseStudy(loadedCaseStudy);
	if (!result) {
		std::cout << "Error setting up case study " << loadedCaseStudy.id << std::endl;
		return;
	} else {
		std::cout << "Case study " << loadedCaseStudy.id << " setup correctly" << std::endl;		
	}

	// Recording setup
	SetDefaultSecondsToRecordIR();				
	// Load wav file
	result = SetupAudioFile(pathResources, audioState.sampleRate);           // Loading .wav file
	if (!result) return;
	
	// HYBRID REVERB setup - croosfade window setup	
	setupHybridMethod();

	// AudioDevice Setup	
	audioInterfaceController = std::make_shared<CAudioInterfaceController>(std::bind(&ofApp::ShowMessage, this, std::placeholders::_1));
	audioInterfaceController->Setup(this, audioState.sampleRate, audioState.bufferSize, 4);
	
	//The system starts its execution in STOP mode
	playState = false;
	stopState = true;
	
	// GUI setup
	SetupGUI(pathResources);
	
	// Setup active walls in GUI
	int numWalls = mainRoom.getWalls().size();
	for (int i = 0; i < numWalls; i++)
	{
		ofParameter<bool> tempWall;
		guiActiveWalls.push_back(tempWall);
		guiActiveWalls.at(i) = true;
	}
	// Setup Image Rooms
	SetupImageRooms();

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
		
	// OSC
	oscManager.Setup(OSC_DEFAULT_TARGET_PORT, OSC_DEFAULT_TARGET_IP, OSC_DEFAULT_LISTEN_PORT, std::bind(&ofApp::OscCallback, this, std::placeholders::_1));	
	changeFileFromOSC = false;
}

void ofApp::setupHybridMethod()
{	
	currentWindowSlopeWidth = INITIAL_WIN_SLOPE;

	float maxDistanceSourcesToListener = millisec2meters(loadedCaseStudy.transitionTime);
	float numSamplesThreshold = meters2samples(maxDistanceSourcesToListener);
	float numsamplesWindowSlope = millisec2samples(currentWindowSlopeWidth);
	float numSamplesTotal = numSamplesThreshold + numsamplesWindowSlope / 2;

	int BRIRLength = environment->GetBRIR()->GetBRIRLength();

	if (numSamplesTotal > BRIRLength)
	{   // WindowThreshold + WindowSlope must be less than BRIR duration		
		numberOfSilencedSamplesInBRIR = BRIRLength - millisec2samples(currentWindowSlopeWidth) / 2;
		currentMaxDistanceSourcesToListener = samples2meters(numberOfSilencedSamplesInBRIR);

	}
	else {
		currentMaxDistanceSourcesToListener = maxDistanceSourcesToListener;
	}

	// 
	SetEnvironmentFadeInWindow(currentMaxDistanceSourcesToListener);
	currentWindowThreshold = meters2millisec(currentMaxDistanceSourcesToListener);
	reverbGainLinear = 1.0;
	SetEnvironmentFadeInWindow(currentMaxDistanceSourcesToListener);

	// INIT ISM
	currentReflectionOrder = INITIAL_REFLECTION_ORDER;
	//ISMHandler->setReflectionOrder(currentReflectionOrder);

	ISMHandler2 = std::make_shared<ISM::CISM>(&myCore);		// Initialize ISM
	//ISMHandler2->enableStaticDistanceCriterion();
	ISMHandler2->disableStaticDistanceCriterion();
	ISMHandler2->setSourceLocation(FindCaseStudy("roomB").sourcePosition);
	ISMHandler2->Setup(currentReflectionOrder, currentMaxDistanceSourcesToListener, millisec2meters(currentWindowSlopeWidth), mainRoom);

	// setup of the image sources
	createImageSourceDSP();
}

void ofApp::setupCaseStudies(std::string& pathResources)
{
	std::string caseARoomGeometryFilePath = pathResources + "\\Room\\ROOM_A_EE100.xml";
	std::string caseAHRTFFilePath = pathResources + "\\HRTF\\HRTF_SADIE_II_D1_48K_24bit_256tap_FIR_SOFA_aligned.sofa";
	std::string caseABRIRFilePath = pathResources + "\\BRIR\\Room_A_listener1_sourceQuad_2m_48kHz_reverb_adjusted.sofa";
	// CaseStudyA App center vs paper diagram -4.75f, -6.69f, 0;
	TCaseStudy caseStudyA("roomA", caseARoomGeometryFilePath, caseAHRTFFilePath, caseABRIRFilePath, 58, 3, Common::CVector3(1.55, 0, 0.15f), Common::CVector3(-0.45f, 0, 0.15f));
	caseStudies.push_back(caseStudyA);

	std::string caseBRoomGeometryFilePath = pathResources + "\\Room\\ROOM_B_EE100.xml";
	std::string caseBHRTFFilePath = pathResources + "\\HRTF\\HRTF_SADIE_II_D1_48K_24bit_256tap_FIR_SOFA_aligned.sofa";
	std::string caseBBRIRFilePath = pathResources + "\\BRIR\\Room_B_listener1_sourceQuad_2m_48kHz_reverb_adjusted.sofa";
	// CaseStudyB App center vs paper diagram -6.78f, -4.97f, 0;
	TCaseStudy caseStudyB("roomB", caseBRoomGeometryFilePath, caseBHRTFFilePath, caseBBRIRFilePath, 43, 3, Common::CVector3(2, 0.03f, 0.15f), Common::CVector3(0, 0.03f, 0.15f));
	caseStudies.push_back(caseStudyB);
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

void ofApp::SetupGUI(const std::string& pathResources)
{
	//GUI setup
	logoUMA.loadImage(pathResources + "\\" + "UMA.png");
	logoUMA.resize(logoUMA.getWidth() / 10, logoUMA.getHeight() / 10);
	titleFont.load(pathResources + "\\" + "Verdana.ttf", 32);
	logoSonix.loadImage(pathResources + "\\" + "Sonix.png");
	logoSonix.resize(logoSonix.getWidth() / 5, logoSonix.getHeight() / 5);
	logoSONICOM.loadImage(pathResources + "\\" + "SONICOM.png");
	logoSONICOM.resize(logoSONICOM.getWidth() / 19, logoSONICOM.getHeight() / 19);

	leftPanel.disableHeader();
	leftPanel.setup(pathResources + "\\", "config.xml", 20, 150);
	leftPanel.setWidthElements(220);
				
	leftPanel.add(sectionLabel1.set("=== GENERAL CONFIG ==="));	

	/*zoom.addListener(this, &ofApp::changeZoom);
	leftPanel.add(zoom.setup("Zoom (Pg. up/down)", 0, -20, 20, 50, 15));*/

	audioInterfaceControl.addListener(this, &ofApp::ChangeAudioDevice);
	leftPanel.add(audioInterfaceControl.set("Change Audio Device"));
			
	//leftPanel.add(sectionLabelSeparator.set(" "));	
	leftPanel.add(sectionLabel2.set("=== RENDERING PARAM ==="));
	
	anechoicEnableControl.addListener(this, &ofApp::toggleAnechoic);
	leftPanel.add(anechoicEnableControl.set("Direct Path", stateAnechoicProcess));

	binauralSpatialisationEnableControl.addListener(this, &ofApp::toggleBinauralSpatialisation);
	leftPanel.add(binauralSpatialisationEnableControl.set("Binaural spatialisation", stateBinauralSpatialisation));
	
	ismEnableControl.addListener(this, &ofApp::toggleISM);
	leftPanel.add(ismEnableControl.set("ISM", stateISMProcess));

	reverbEnableControl.addListener(this, &ofApp::toggleReverb);
	leftPanel.add(reverbEnableControl.set("Late Reverb", stateBRIRReverbProcess));

	reverbGainControl.addListener(this, &ofApp::changeReverbGain);
	leftPanel.add(reverbGainControl.set("ReverbGain (dB)", 0, -40, 40));
	
	//leftPanel.add(sectionLabelSeparator.set(" "));
	leftPanel.add(sectionLabel3.set("=== ISM PARAMETERS ==="));

	reflectionOrderControl.addListener(this, &ofApp::changeReflectionOrder);
	leftPanel.add(reflectionOrderControl.set("Relection Order (+/-)", INITIAL_REFLECTION_ORDER, 0, MAX_REFLECTION_ORDER));

	maxDistanceImageSourcesToListenerControl.addListener(this, &ofApp::changeMaxDistanceImageSources);
	leftPanel.add(maxDistanceImageSourcesToListenerControl.set("Max Distance (m)", currentMaxDistanceSourcesToListener, MIN_DIST_SILENCED_FRAMES, MAX_DIST_SILENCED_FRAMES));
	
	winThresholdControl.addListener(this, &ofApp::changeWinThreshold);	
	leftPanel.add(winThresholdControl.set("Transition Time (ms)"
		, currentWindowThreshold
		, (MIN_DIST_SILENCED_FRAMES * 1000) / myCore.GetMagnitudes().GetSoundSpeed()
		, (MAX_DIST_SILENCED_FRAMES * 1000) / myCore.GetMagnitudes().GetSoundSpeed()));				
		
	windowSlopeControl.addListener(this, &ofApp::changeWindowSlope);
	leftPanel.add(windowSlopeControl.set("WinSlople (ms)", INITIAL_WIN_SLOPE, MIN_WIN_SLOPE, MAX_WIN_SLOPE));		

	//leftPanel.add(sectionLabelSeparator.set(" "));
	leftPanel.add(sectionLabel4.set("=== PLAYBACK CONTROLS ==="));

	stopToPlayControl.addListener(this, &ofApp::stopToPlay);
	leftPanel.add(stopToPlayControl.set("Play", false));

	playToStopControl.addListener(this, &ofApp::playToStop);
	leftPanel.add(playToStopControl.set("Stop", true));

	numberOfSecondsToRecordControl.addListener(this, &ofApp::SetSecondsToRecordIR);
	leftPanel.add(numberOfSecondsToRecordControl.set("IR record length(s)", secondsToRecordIR, 0.2, MAX_SECONDS_TO_RECORD));

	recordOfflineIRControl.addListener(this, &ofApp::recordIrOffline);
	leftPanel.add(recordOfflineIRControl.set("Save IR", false));

	recordOfflineWAVControl.addListener(this, &ofApp::recordWavOffline);
	leftPanel.add(recordOfflineWAVControl.set("Record (offline)", false));
	
	//leftPanel.add(sectionLabelSeparator.set(" "));
	leftPanel.add(sectionLabel5.set("=== PREDEFINED SETUPS ==="));

	changeToCaseStudyAControl.addListener(this, &ofApp::changeToCaseStudyA);
	leftPanel.add(changeToCaseStudyAControl.set("Load case ROOM A", false));

	changeToCaseStudyBControl.addListener(this, &ofApp::changeToCaseStudyB);
	leftPanel.add(changeToCaseStudyBControl.set("Load case ROOM B", true));
	
	//leftPanel.add(sectionLabelSeparator.set(" "));
	leftPanel.add(sectionLabel6.set("=== LOAD RESOURCES ==="));

	changeAudioToPlayControl.addListener(this, &ofApp::changeAudioToPlay);
	leftPanel.add(changeAudioToPlayControl.set("Load audio", false));

	changeRoomGeometryControl.addListener(this, &ofApp::changeRoomGeometry);
	leftPanel.add(changeRoomGeometryControl.set("Load room", false));

	changeHRTFControl.addListener(this, &ofApp::changeHRTF);
	leftPanel.add(changeHRTFControl.set("Load HRTF", false));

	changeBRIRControl.addListener(this, &ofApp::changeBRIR);
	leftPanel.add(changeBRIRControl.set("Load BRIR", false));
	
	//leftPanel.add(sectionLabelSeparator.set(" "));
	leftPanel.add(sectionLabel7.set("=== OTHERS ==="));

	helpDisplayControl.addListener(this, &ofApp::toogleHelpDisplay);
	leftPanel.add(helpDisplayControl.set("Help", false));

	aboutDisplayControl.addListener(this, &ofApp::toogleAboutDisplay);
	leftPanel.add(aboutDisplayControl.set("About", false));
}


bool ofApp::LoadHRTFSofa(const std::string& fullPath)
{		
	bool specifiedDelays;
	bool sofaLoadResult = HRTF::CreateFromSofa(fullPath, listener, specifiedDelays);
	if (!sofaLoadResult) {
		std::cout << "ERROR: Error trying to load the SOFA file - " << fullPath << endl << endl;
	}
	else {
		std::cout << "HRTF SOFA file loaded correctly - "<< fullPath << endl << endl;
		loadedHRTFFilePath = fullPath;
		loadedHRTFFileName = GetFileName(fullPath);
	}

	return sofaLoadResult;
}

/**
 * @brief 
 * @param pathResources 
 * @return 
 */
bool ofApp::LoadBRIRSofa(const std::string& fullPath)
{
	/************************/
	// Environment setup
	reverberationOrder = BIDIMENSIONAL;
	environment = myCore.CreateEnvironment();									// Creating environment to have reverberated sound
	environment->SetReverberationOrder(reverberationOrder);		// Setting number of ambisonic channels to use in reverberation processing
	
	//std::string fullPath;
	//fullPath = pathResources + "\\" + "lab138_3_KU100_reverb_120cm_adjusted_44100.sofa";                      // LAB_ROOM 
	//fullPath = pathResources + "\\BRIR\\" + "Sala108_listener1_sourceQuad_2m_48kHz_reverb_adjusted.sofa";             // A108_ROOM 
	//fullPath = pathResources + "\\" + "SalaJuntasTeleco_listener1_sourceQuad_2m_48kHz_reverb_adjusted.sofa";  // Juntas_ROOM
	//fullPath = pathResources + "\\" + "Sala108_listener1_sourceQuad_2m_48kHz_Omnidirectional_reverb.sofa";       
	//fullPath = pathResources + "\\" + "SalaJuntasTeleco_listener1_sourceQuad_2m_48kHz_Omnidirectional_reverb.sofa";   
	//ullPathBRIR = fullPath;

	bool result = BRIR::CreateFromSofa(fullPath, environment);		// Loading SOFAcoustics BRIR file and applying it to the environment
	if (!result) {
		std::cout << "ERROR: Error trying to load the BRIR SOFA file - " << fullPath << endl << endl;		
	}
	else {
		std::cout << "BRIR SOFA file loaded correctly - " << fullPath << endl << endl;
		loadedBRIRFilePath = fullPath;
		loadedBRIRFileName = GetFileName(fullPath);
	}
	return result;
}

bool ofApp::SetupRoomFromGeometryFile(const std::string& fullPath)
{
	mainRoom = ISM::Room();		// Initialize room		

	ISM::RoomGeometry newRoomGeometry;
	std::vector<std::vector<float>> absortionsWalls;
	bool result = LoadGeometryFile(fullPath, newRoomGeometry, absortionsWalls);

	if (result) {
		mainRoom.setupRoomGeometry(newRoomGeometry);
		mainRoom.setWallAbsortion(absortionsWalls);
		std::cout << "New Room loaded " << fullPath << endl << endl;
		loadedRoomGeometryFilePath = fullPath;
		loadedRoomGeometryFileName = GetFileName(fullPath);
		return true;
	}
	else {
		std::cout << "ERROR: Error trying to load the room geometry file - " << fullPath << endl << endl;
		return false;
	}
}


void ofApp::SetupShoeboxRoom(float length, float width, float height, const std::vector<std::vector<float>>& absortionsWalls) {
	mainRoom = ISM::Room();		// Initialize room	
	mainRoom.setupShoeBox(length, width, height);
	mainRoom.setWallAbsortion(absortionsWalls);
}

void ofApp::SetupImageRooms() {
	mainRoomImages.clear();
	limitOrderToDrawImageRooms = std::max(0, currentReflectionOrder - MAX_ORDER_TO_DRAW_ROOMS);
	CalculateImageRooms(mainRoom, currentReflectionOrder);
}

void ofApp::CalculateImageRooms(const ISM::Room& room, int reflectionOrder)
{	
	if (reflectionOrder <= limitOrderToDrawImageRooms) return;
	
	TImageRoomData roomData(room, reflectionOrder);
	mainRoomImages.push_back(roomData);
	
	reflectionOrder--;
	std::vector<ISM::Room> roomImages;
	room.getImageRooms(roomImages);
	for (int i = 0; i < roomImages.size(); i++)
	{
		CalculateImageRooms(roomImages.at(i), reflectionOrder);
	}	
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
	ofRotateY(cameraElevation);
	ofRotateZ(cameraAzimuth);

	//draw reference axis
	ofPushStyle();
	ofSetColor(255, 150, 150);
	ofLine(0, 0, 0, 1, 0, 0);
	ofSetColor(150, 255, 150);
	ofLine(0, 0, 0, 0, 1, 0);
	ofSetColor(150, 150, 255);
	ofLine(0, 0, 0, 0, 0, 1);
	ofPopStyle();


	//int ordReflectDraw = reflectionOrderControl;
	//drawRoom(mainRoom, std::min(ordReflectDraw, 3), 255);	
	//drawRoom(mainRoom, currentReflectionOrder, 255);
	drawRoom();

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

	std::string titleText = (ofGetWidth() > 1500)
		? "Hybrid ISM + BRIR Simulator " + APP_VERSION
		: "Hybrid Simulator " + APP_VERSION;
	titleFont.drawString(titleText, ofGetWidth() / 2 - titleFont.stringWidth(titleText) / 2, 85);
	

	drawLogos_Acknowledgements();

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
	sprintf(messageStr, "List_Pos: %.2f %.2f %.2f", listenerLocation.x, listenerLocation.y, listenerLocation.z);
	ofDrawBitmapString(messageStr, ofGetWidth() - 285, ofGetHeight() - 55);
	
	//Common::CQuaternion QListener = listenerTransform.GetOrientation();
	float yaw, pitch, roll;
	QListener.ToYawPitchRoll(yaw, pitch, roll);
	//sprintf(messageStr, "Listener Ori: %.1f %.1f %.1f %.1f", QListener.w, QListener.x, QListener.y, QListener.z);
	sprintf(messageStr, "List_Ori: %.1f(Y) %.1f(P) %.1f(R)", ofRadToDeg(yaw), ofRadToDeg(pitch), ofRadToDeg(roll));
	ofDrawBitmapString(messageStr, ofGetWidth() - 285, ofGetHeight() - 40);
	Common::CVector3 sourceLocation = ISMHandler2->getSourceLocation();
	sprintf(messageStr, "SourcePos: %.2f %.2f %.2f", sourceLocation.x, sourceLocation.y, sourceLocation.z);
	ofDrawBitmapString(messageStr, ofGetWidth() - 285, ofGetHeight() - 25);
	
	drawHelp();

	leftPanel.draw();	

	drawAbout();

	drawResourcesLoaded();
}

void ofApp::drawHelp()
{
	if (!boolToogleDisplayHelp)
	{
		ofPushStyle();
		ofSetColor(50, 150);
		ofRect(20, ofGetHeight() - 250, 390, 355);
		ofPopStyle();
		char messageStr[255];
		sprintf(messageStr, "Point of View:");
		ofDrawBitmapString(messageStr, 30, ofGetHeight() - 230);
		sprintf(messageStr, "      - Control: Mouse left-click and drag.");
		ofDrawBitmapString(messageStr, 30, ofGetHeight() - 210);
		sprintf(messageStr, "      - Scale: Mouse wheel.");
		ofDrawBitmapString(messageStr, 30, ofGetHeight() - 190);

		sprintf(messageStr, "SOURCE movement keys:");
		ofDrawBitmapString(messageStr, 30, ofGetHeight() - 170);
		sprintf(messageStr, "      - Y Axis: a/d");
		ofDrawBitmapString(messageStr, 30, ofGetHeight() - 150);
		sprintf(messageStr, "      - X Axis: w/s");
		ofDrawBitmapString(messageStr, 30, ofGetHeight() - 130);
		sprintf(messageStr, "      - Z Axis: e/q");
		ofDrawBitmapString(messageStr, 30, ofGetHeight() - 110);

		sprintf(messageStr, "LISTENER control keys:");
		ofDrawBitmapString(messageStr, 30, ofGetHeight() - 90);
		sprintf(messageStr, "      - Movement: Arrow keys and page up/down");		
		ofDrawBitmapString(messageStr, 30, ofGetHeight() - 70);		

		sprintf(messageStr, "      - Rotation: Yaw [j/l]");
		ofDrawBitmapString(messageStr, 30, ofGetHeight() - 50);
		sprintf(messageStr, "                  Pitch [i/k]");
		ofDrawBitmapString(messageStr, 30, ofGetHeight() - 30);
		sprintf(messageStr, "                  Roll [u/o]");
		ofDrawBitmapString(messageStr, 30, ofGetHeight() - 10);

		/*sprintf(messageStr, "Enable/Disable wall: 1,2,3 ... 0");
		ofDrawBitmapString(messageStr, 30, ofGetHeight() - 70);*/
	}
}

void ofApp::drawAbout()
{
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

		sprintf(string, "ABOUT HYBRID ISM + BRIR SIMULATOR");
		upPos += 5;
		ofDrawBitmapString(string, leftSide + 15, upSide + upPos);

		sprintf(string, "Version: 2.0.0");
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

		sprintf(string, "This work has been partially funded by the Ministry of Science and Technology within the National R&D Plan through the SONIX ");
		upPos += 30;
		ofDrawBitmapString(string, leftSide + 15, upSide + upPos);
		sprintf(string, "project Redefining Sonic Interaction in Extended Reality (PID2023-152547NB-I00) and by the European Union, within the ");
		upPos += 20;
		ofDrawBitmapString(string, leftSide + 15, upSide + upPos);
		sprintf(string, "framework program Horizon 2020 through the SONICOM project (agreement No. 101017743)");
		upPos += 20;
		ofDrawBitmapString(string, leftSide + 15, upSide + upPos);
	}
}

void ofApp::drawLogos_Acknowledgements()
{
		
	logoSonix.draw(ofGetWidth() - 190, 45);		// Logo of the SONIX project
	logoSONICOM.draw(ofGetWidth() - 240, 100);	// Logo of the SONICOM project
	ofDrawBitmapString("Funded by the Spanish project SONIX", ofGetWidth() - 310, 155);
	ofDrawBitmapString("`Redefining Sonic Interaction in", ofGetWidth() - 310, 170);
	ofDrawBitmapString("Extended Reality' (PID2023-152547NB", ofGetWidth() - 310, 185);
	ofDrawBitmapString("-I00) and the European project H2020", ofGetWidth() - 310, 200);
	ofDrawBitmapString("SONICOM (agreement No.101017743).", ofGetWidth() - 310, 215);

	/*ofDrawBitmapString("Funded by the Spanish project SONIX:", ofGetWidth() - 420, 155);
	ofDrawBitmapString("Redefining Sonic Interaction in Extended Reality'", ofGetWidth() - 420, 170);
	ofDrawBitmapString("(PID2023-152547NB-I00) and the European project", ofGetWidth() - 420, 185);	
	ofDrawBitmapString("H2020 - SONICOM (agreement No.101017743).", ofGetWidth() - 420, 200);*/
}

void ofApp::drawResourcesLoaded() {	
	if (!boolToogleDisplayHelp) return;
	int leftMargin = 30;
	ofPushStyle();
	ofSetColor(50, 150);
	ofRect(leftMargin, ofGetHeight() - 85, 550, 80);
	ofPopStyle();
	
	char messageStr[1024];

	if (loadedRoomGeometryFileName.empty() && loadedHRTFFileName.empty() && loadedBRIRFileName.empty())
	{
		 snprintf(messageStr, sizeof(messageStr), "No resources loaded");
		 ofDrawBitmapString(messageStr, leftMargin + 5, ofGetHeight() - 70);
		 return;
	}

	
	if (loadedCaseStudy.id != ""){
		snprintf(messageStr, sizeof(messageStr), "Case study loaded: %s", loadedCaseStudy.id.c_str());	
	}
	else {
		snprintf(messageStr, sizeof(messageStr), "Resources loaded:");
	}	
	ofDrawBitmapString(messageStr, leftMargin + 5, ofGetHeight() - 70);

	snprintf(messageStr, sizeof(messageStr), "-Room: %s", loadedRoomGeometryFileName.c_str());
	ofDrawBitmapString(messageStr, leftMargin + 5, ofGetHeight() - 45);

	snprintf(messageStr, sizeof(messageStr), "-HRTF: %s", loadedHRTFFileName.c_str());
	ofDrawBitmapString(messageStr, leftMargin + 5, ofGetHeight() - 30);

	snprintf(messageStr, sizeof(messageStr), "-BRIR: %s", loadedBRIRFileName.c_str());
	ofDrawBitmapString(messageStr, leftMargin + 5, ofGetHeight() - 15);
}

void ofApp::DrawRecordingOffline()
{
	uint64_t frameStart = ofGetElapsedTimeMillis();	

	if (offlineRecordBuffers == 0) {		
		std::string fileNameUsr;
		std::string pathData = ofToDataPath("");
		
		std::string defaultPath = pathData + recordingFolder + "\\sample.wav";
		ofFileDialogResult saveFileResult = ofSystemSaveDialog(defaultPath, "Save output audio");
		fileNameUsr = saveFileResult.getPath();
		fileNameUsr += ".wav";
		//if (boolRecordingIR)
		//{					
		//	fileNameUsr = pathData + recordingFolder+ "\\ImpulseResponse.wav";
		//	fileNameUsr = GetFileIncrementalName(fileNameUsr);
		//}
		//else
		//{
		//	std::string defaultPath = pathData + recordingFolder+ "\\sample.wav";
		//	ofFileDialogResult saveFileResult = ofSystemSaveDialog(defaultPath, "Save output audio");
		//	fileNameUsr = saveFileResult.getPath();
		//	//fileNameUsr += ".wav";
		//}
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

		

			StartWavRecord(fileNameUsr, 16);                        // Open wav file
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
		OfflineWavRecordOneLoopIteration(myCore.GetAudioState().bufferSize);  //audioProcess + wavWriter_AppendToFile + offlineRecordBuffers++
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
	{
		MoveListener(Common::CVector3(0, LISTENER_STEP, 0));		
		break;
	}		
	case OF_KEY_RIGHT:
	{
		MoveListener(Common::CVector3(0, -LISTENER_STEP, 0));		
		break;
	}		
	case OF_KEY_UP:
	{
		MoveListener(Common::CVector3(LISTENER_STEP, 0, 0));
		break;
	}
	case OF_KEY_DOWN:
	{
		MoveListener(Common::CVector3(-LISTENER_STEP, 0, 0));		
		break;
	}
	case OF_KEY_PAGE_UP:
	{
		MoveListener(Common::CVector3(0, 0, LISTENER_STEP));
		break;
	}
	case OF_KEY_PAGE_DOWN:
	{
		MoveListener(Common::CVector3(0, 0, -LISTENER_STEP));
		break;
	}
	
	case 's': //Moves the source back (-X)
		moveSource(Common::CVector3(-SOURCE_STEP, 0, 0));
		break;
	case 'w': //Moves the source front (+X)
		moveSource(Common::CVector3(SOURCE_STEP, 0, 0));
		break;
	case 'a': //Moves the source left (+Y)
		moveSource(Common::CVector3(0, SOURCE_STEP, 0));
		break;
	case 'd': //Moves the source right (-Y)
		moveSource(Common::CVector3(0, -SOURCE_STEP, 0));
		break;
	case 'e': //Moves the source up (Z)
		moveSource(Common::CVector3(0, 0, SOURCE_STEP));
		break;
	case 'q': //Moves the source down (-Z)
		moveSource(Common::CVector3(0, 0, -SOURCE_STEP));
		break;	

	case 'j': //Yaw
	{
		listenerTransform.Rotate(Common::CVector3(0, 0, 1), PI / 32);
		listener->SetListenerTransform(listenerTransform);
		break;
	}
	case 'l': //Yaw
	{
		listenerTransform.Rotate(Common::CVector3(0, 0, 1), -PI / 32);
		listener->SetListenerTransform(listenerTransform);
		break;
	}
	case 'i': //Pitch
	{
		listenerTransform.Rotate(Common::CVector3(0, 1, 0), PI / 32);
		listener->SetListenerTransform(listenerTransform);
		break;
	}
	case 'k': //Pitch
	{
		listenerTransform.Rotate(Common::CVector3(0, 1, 0), -PI / 32);
		listener->SetListenerTransform(listenerTransform);
		break;
	}
	case 'u': //Roll
	{
		listenerTransform.Rotate(Common::CVector3(1, 0, 0), -PI / 32);
		listener->SetListenerTransform(listenerTransform);
		break;
	}
	case 'p': //Roll
	{
		listenerTransform.Rotate(Common::CVector3(1, 0, 0), PI / 32);
		listener->SetListenerTransform(listenerTransform);
		break;
	}
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
	//if (key == 32 /*space*/) {
	//	std::cout << "Starting profilling" << std::endl;
	//	std::this_thread::sleep_for(10ms);		// In case "cout" will create some kind of interference with the profile measurement.
	//	profilling = true;
	//}
}

//--------------------------------------------------------------
void ofApp::mouseMoved(int x, int y ){

}

//--------------------------------------------------------------
void ofApp::mouseDragged(int x, int y, int button){
	// Rotation is only applied if it is the main (left) button.
	if (button == 0) {		
		// 1. Calculate the displacement (delta) from the last position
		float deltaX = x - lastMouseX;
		float deltaY = y - lastMouseY;

		// 2. Update azimuth and elevation based on movement
		// Horizontal Movement (X) -> Controls Azimuth (Left/Right)		
		cameraAzimuth += deltaX * 0.25;
		// Vertical Movement (Y) -> Controls Elevation (Up/Down)		
		cameraElevation -= deltaY * 0.25; 

		// 3. Limit (optional)
		// elevation = ofClamp(elevation, -90, 90);

		// 4. Update last mouse position for next frame
		lastMouseX = x;
		lastMouseY = y;
	}
}

//--------------------------------------------------------------
void ofApp::mousePressed(int x, int y, int button){
	// We are only interested in the left button (typically button == 0).
	if (button == 0) {
		lastMouseX = x;
		lastMouseY = y;
	}
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

void ofApp::mouseScrolled(int x, int y, float scrollX, float scrollY) {
	// scrollY is the vertical scroll value of the wheel.
	// Positive for "up" (zooming out), Negative for "down" (zooming in).

	// If the wheel scrolls upwards (scroll forward)
	if (scrollY > 0) {		
		scale *= 1.1;
	}
	// If the wheel scrolls downwards (scroll backwards)
	else if (scrollY < 0) {		
		scale *= 0.9;
	}	
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
//void ofApp::drawRoom(const ISM::Room& room, int reflectionOrder,int transparency)
//{
//	if (reflectionOrder > 0)
//	{
//		ofPushStyle();
//		ofSetColor(200, transparency);
//		reflectionOrder--;		
//		std::vector<ISM::Wall> walls = room.getWalls();
//		for (int i = 0; i < walls.size(); i++)
//		{
//			if (walls.at(i).isActive())
//			{
//				drawWall(walls[i]);
//				drawWallNormal(walls[i]);
//			}
//		}
//		std::vector<ISM::Room> roomImages;
//		room.getImageRooms(roomImages);
//		for (int i = 0; i < roomImages.size(); i++)
//		{
//			drawRoom(roomImages.at(i), reflectionOrder, transparency/2);
//		}
//		ofPopStyle();
//	}	
//}

void ofApp::drawRoom()
{	
	ofPushStyle();
		
	for (auto& roomData : mainRoomImages) {
		
		int opacity = calculateOpacity(roomData.reflectionOrder, currentReflectionOrder, 24);

		if (roomData.reflectionOrder == currentReflectionOrder) {
			ofSetColor(ofColor::hotPink, opacity);
		}
		else {
			ofSetColor(ofColor(200), opacity);
		}
				
		std::vector<ISM::Wall> walls = roomData.room.getWalls();		
		for (auto& wall : walls){
			if (wall.isActive()) {
				drawWall(wall);
				drawWallNormal(wall);
			}
		}		
	}	

	//Draw the original room with full opacity (255)
	ofSetColor(ofColor::hotPink, 255);
	std::vector<ISM::Wall> walls = mainRoom.getWalls();
	for (auto& wall : walls) {
		if (wall.isActive()) {
			drawWall(wall);
			drawWallNormal(wall);
		}
	}

	ofPopStyle();
}

/**
 * @brief Calculates the opacity (alpha value) for a mirrored room, decreasing
 * linearly from max opacity (255) at maxOrder to minOpacity at order 1.
 * * @param currentOrder The current recursion level (n). Must be >= 1.
 * @param maxOrder The initial, maximum recursion level (N). Must be >= 1.
 * @param minOpacity The minimum opacity value for order 1. [0-255].
 * @return unsigned char The opacity (alpha) value [0-255].
 */
int ofApp::calculateOpacity(int currentOrder, int maxOrder, unsigned char minOpacity) {

	// --- Edge Cases and Clamping ---

	// If maxOrder is 1 or less, return full opacity or minOpacity (whichever is higher/more sensible).
	if (maxOrder <= 1) {
		return std::max((unsigned char)255, minOpacity);
	}

	// Clamp the currentOrder to the valid range [1, maxOrder]
	currentOrder = std::max(1, currentOrder);
	currentOrder = std::min(maxOrder, currentOrder);

	// If it's the maximum order (N), return full opacity (255).
	if (currentOrder == maxOrder) {
		return 255;
	}

	// If it's the minimum order (1), return the minimum configurable opacity.
	if (currentOrder == 1) {
		return minOpacity;
	}

	// --- Linear Interpolation ---

	// Total range of opacity difference: (255 - minOpacity)
	const double opacityRange = 255.0 - minOpacity;

	// Total range of orders: (N - 1)
	const double orderRange = (double)(maxOrder - 1);

	// Progress factor: How far is 'currentOrder' along the [1, N] range, scaled to [0.0, 1.0].
	// factor = (n - 1) / (N - 1)
	const double progressFactor = (currentOrder - 1) / orderRange;

	// Calculate final opacity using linear interpolation (Lerp):
	// alpha = minOpacity + (opacityRange * progressFactor)
	double calculatedOpacity = minOpacity + (opacityRange * progressFactor);

	// Convert the result to unsigned char, ensuring proper rounding.
	return (int)std::round(calculatedOpacity);
}

void ofApp::drawWall(const ISM::Wall& wall)
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

void ofApp::drawWallNormal(const ISM::Wall& wall, float length)
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
	SetupImageRooms();

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

	bool retFlag;
	UpdateMaxDistanceAndWinThresholdParameters(_maxDistanceSourcesToListener, retFlag);
	if (retFlag) return;

	if (!stopState) audioInterfaceController->StartAudioInterface();
}

void ofApp::UpdateMaxDistanceAndWinThresholdParameters(const float& _maxDistanceSourcesToListener, bool& retFlag)
{
	retFlag = true;
	float numSamplesThreshold = meters2samples(_maxDistanceSourcesToListener);
	float numsamplesWindowSlope = millisec2samples(currentWindowSlopeWidth);
	float numSamplesTotal = numSamplesThreshold + numsamplesWindowSlope / 2;

	int BRIRLength = environment->GetBRIR()->GetBRIRLength();

	if (numSamplesTotal > BRIRLength)
	{   // WindowThreshold + WindowSlope must be less than BRIR duration		
		maxDistanceImageSourcesToListenerControl.setWithoutEventNotifications(currentMaxDistanceSourcesToListener);
		return;
	}

	if (numSamplesThreshold - numsamplesWindowSlope / 2 <= 0) {
		maxDistanceImageSourcesToListenerControl.setWithoutEventNotifications(currentMaxDistanceSourcesToListener);
		return;
	}
	// 
	currentMaxDistanceSourcesToListener = _maxDistanceSourcesToListener;
	maxDistanceImageSourcesToListenerControl.set(currentMaxDistanceSourcesToListener);

	SetEnvironmentFadeInWindow(currentMaxDistanceSourcesToListener);

	currentWindowThreshold = meters2millisec(currentMaxDistanceSourcesToListener);
	winThresholdControl.set(currentWindowThreshold);
	ReconfigureISM();
	retFlag = false;
}

void ofApp::changeWinThreshold(float& _windowThreshold)
{
	if (is_equal(currentWindowThreshold, _windowThreshold)) return;

	float maxDistanceSourcesToListener = millisec2meters(_windowThreshold);
	changeMaxDistanceImageSources(maxDistanceSourcesToListener);		
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
	BRIR::CreateFromSofa(loadedBRIRFilePath, environment);							// Loading SOFAcoustics BRIR file and applying it to the e
	
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


bool ofApp::SetupCaseStudy(const TCaseStudy& caseStudy) {
	// HRTF setup
	bool result = LoadHRTFSofa(caseStudy.hrtfFilePath); //TODO check samplerate
	if (!result) return false;

	// Environment setup
	result = LoadBRIRSofa(caseStudy.brirFilePath); //TODO check samplerate
	if (!result) return false;

	// Room setup	
	result = SetupRoomFromGeometryFile(caseStudy.geometryFilePath);
	if (!result) return false;

	// Move listener
	Common::CTransform listenerPosition = Common::CTransform();	 // Setting listener in (0,0,0)
	listenerPosition.SetPosition(caseStudy.listenerPosition);
	listener->SetListenerTransform(listenerPosition);

	// Move source
	Common::CTransform sourcePosition = Common::CTransform();
	sourcePosition.SetPosition(caseStudy.sourcePosition);
	anechoicSourceDSP->SetSourceTransform(sourcePosition);

	// ISM setup
	currentReflectionOrder = caseStudy.reflectionOrder;

	return true;
}
void ofApp::ClearLoadedCaseStudy() {
	loadedCaseStudy = TCaseStudy();
	changeToCaseStudyBControl.setWithoutEventNotifications(false);
	changeToCaseStudyAControl.setWithoutEventNotifications(false);
}

void ofApp::changeToCaseStudyA(bool& active) {
	bool result = changeToCaseStudy("roomA");
	if (result) {
		changeToCaseStudyBControl.setWithoutEventNotifications(false);
	}
}

void ofApp::changeToCaseStudyB(bool& active) {
	bool result = changeToCaseStudy("roomB");
	if (result) {
		changeToCaseStudyAControl.setWithoutEventNotifications(false);
	}
}

bool ofApp::changeToCaseStudy(std::string _id) {
	if (!setupDone) return false;

	TCaseStudy _caseStudy = FindCaseStudy(_id);
	if (loadedRoomGeometryFilePath == _caseStudy.geometryFilePath) {
		cout << "Case Study "<< _caseStudy.id <<" already loaded" << endl << endl;
		return false;
	}	
	bool result = changeToCaseStudy(_caseStudy);
	if (result) {
		loadedCaseStudy = _caseStudy;		
	}
	return result;
}

bool ofApp::changeToCaseStudy(const TCaseStudy& caseStudy) {

	lock_guard < mutex > lock(audioMutex);
	if (!stopState) audioInterfaceController->StopAudioInterface();

	setupDone = false;
	stopState = true;
	playState = false;
	playToStopControl.set("Stop", true);
	stopToPlayControl.set("Play", false);

	/// Load Room geometry
	ISM::RoomGeometry newRoomGeometry;
	std::vector<std::vector<float>> absortionsWalls;
	bool result = LoadGeometryFile(caseStudy.geometryFilePath, newRoomGeometry, absortionsWalls);

	if (result) {
		
		mainRoom.setupRoomGeometry(newRoomGeometry);
		mainRoom.setWallAbsortion((std::vector<std::vector<float>>)  absortionsWalls);
		
		bool retFlag;
		UpdateMaxDistanceAndWinThresholdParameters(millisec2meters(caseStudy.transitionTime), retFlag);
		if (retFlag) return false;

		SetupImageRooms();
		loadedRoomGeometryFilePath = caseStudy.geometryFilePath;
		loadedRoomGeometryFileName = GetFileName(loadedRoomGeometryFilePath);
		std::cout << "New Room loaded " << loadedRoomGeometryFilePath << endl << endl;
	} else {
		std::cout << "ERROR: Load new ROOM - Couldn't load file " << caseStudy.geometryFilePath << endl << endl;
		if (!stopState) audioInterfaceController->StartAudioInterface();
		return false;
	}
	// Load new HRTF file
	bool specifiedDelays;
	bool sofaLoadResult = HRTF::CreateFromSofa(caseStudy.hrtfFilePath, listener, specifiedDelays);

	if (!sofaLoadResult) {
		cout << "ERROR: Error trying to load the SOFA file" << endl << endl;
		if (!stopState) audioInterfaceController->StartAudioInterface();
		return false;
	}
	else
	{
		loadedHRTFFilePath = caseStudy.hrtfFilePath;
		loadedHRTFFileName = GetFileName(loadedHRTFFilePath);
		cout << "Load new HRTF File " << loadedHRTFFilePath << endl << endl;
	}
	// Load new BRIR file	
	sofaLoadResult = BRIR::CreateFromSofa(caseStudy.brirFilePath, environment); // Loading SOFAcoustics BRIR file and applying it to the environment

	if (!sofaLoadResult) {
		cout << "ERROR: Error trying to load the SOFA BRIR file" << endl << endl;
		if (!stopState) audioInterfaceController->StartAudioInterface();
		return false;
	}
	else
	{
		loadedBRIRFilePath = caseStudy.brirFilePath;
		loadedBRIRFileName = GetFileName(loadedBRIRFilePath);
		cout << "Load new BRIR File " << loadedBRIRFilePath << endl << endl;
		SetDefaultSecondsToRecordIR();
	}
		
	if (!stopState) audioInterfaceController->StartAudioInterface();
	setupDone = true;
	return true;
}


void ofApp::changeRoomGeometry(bool &_active)
{
	
	changeRoomGeometryControl = false;
	if (!setupDone) return;
	
	lock_guard < mutex > lock(audioMutex);

	if (!stopState) audioInterfaceController->StopAudioInterface();

	stopState = true;
	playState = false;
	playToStopControl.set("Stop", true);
	stopToPlayControl.set("Play", false);
			
	//string pathData = ofToDataPath("", false);
	ofFileDialogResult openFileResult;
	std::string fileExtension, fileName, fullPath;
	if (changeFileFromOSC) {
		std::string pathResources = ofToDataPath("resources");
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

	// Check if the user opened a file
	if (!openFileResult.bSuccess) {
		//ofLogError() << "Couldn't load file";
		std::cout << "ERROR: Couldn't load ROOM file -  " << fullPath << endl << endl;
		if (!stopState) audioInterfaceController->StartAudioInterface();
		return;
	}
		
	if (fileExtension != "XML") {
		//ofLogError() << "Extension must be XML";
		std::cout << "ERROR: Load new ROOM - File extension must be XML " << endl << endl;
		if (!stopState) audioInterfaceController->StartAudioInterface();
		return;
	}

	ISM::RoomGeometry newRoomGeometry;
	std::vector<std::vector<float>> absortionsWalls;
	bool result = LoadGeometryFile(fullPath, newRoomGeometry, absortionsWalls);

	if (result) {
		mainRoom.setupRoomGeometry(newRoomGeometry);
		mainRoom.setWallAbsortion((std::vector<std::vector<float>>)  absortionsWalls);
		ReconfigureISM();
		SetupImageRooms();

		loadedRoomGeometryFilePath = fullPath;
		loadedRoomGeometryFileName = GetFileName(loadedRoomGeometryFilePath);
		
		ClearLoadedCaseStudy();
		std::cout << "New Room loaded " << fullPath << endl << endl;
	} else {
		std::cout << "ERROR: Load new ROOM - Couldn't load file " << fullPath << endl << endl;
	}
		
	if (!stopState) audioInterfaceController->StartAudioInterface();		
}

/**
 * @brief Read the XML file with the geometry of the room and absorption of the walls
 * @param fullPath full path of the XML file
 * @return 
 */
bool ofApp::LoadGeometryFile(const std::string& fullPath, ISM::RoomGeometry& newRoom, std::vector<std::vector<float>>& absortionsWalls) {
	
	bool result = xml.load(fullPath);
	if (!result)
	{		
		std::cout << "ERROR: Couldn't load ROOM file " << fullPath << endl << endl;
		//if (!stopState) audioInterfaceController->StartAudioInterface();
		return false;
	}
	
	// select all corners and iterate through them
	auto cornersXml = xml.find("//ROOMGEOMETRY/CORNERS");
	if (cornersXml.empty()) {
		std::cout << "ERROR: The file is not a room configuration" << endl;
		//if (!stopState) audioInterfaceController->StartAudioInterface();
		return false;
	}

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
			newRoom.corners.push_back(tempP3d);
		}
	}

	/***********************/
	//absortionsWalls.clear();
	/***********************/

	// select all walls and iterate through them
	auto wallsXml = xml.find("//ROOMGEOMETRY/WALLS");
	if (wallsXml.empty()) {
		std::cout << "ERROR: The file is not a room configuration" << endl;		
		return false;
	}
	
	for (auto& currentWall : wallsXml) {
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
	return true;
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
			//fullPathHRTF = fullPath;
			bool specifiedDelays;
			bool sofaLoadResult = HRTF::CreateFromSofa(fullPath, listener, specifiedDelays);

			if (!sofaLoadResult) {
				cout << "ERROR: Error trying to load the SOFA file" << endl << endl;
				if (!stopState) audioInterfaceController->StartAudioInterface();
				return;
			}
			else
			{
				loadedHRTFFilePath = fullPath;
				loadedHRTFFileName = GetFileName(fullPath);
				
				ClearLoadedCaseStudy();

				cout << "Load new HRTF File " << loadedHRTFFilePath << endl  << endl;
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
			//fullPathBRIR = fullPath;
			bool sofaLoadResult = BRIR::CreateFromSofa(fullPath, environment); // Loading SOFAcoustics BRIR file and applying it to the environment
			
			if (!sofaLoadResult) {
				cout << "ERROR: Error trying to load the SOFA BRIR file" << endl << endl;
				if (!stopState) audioInterfaceController->StartAudioInterface();
				return;
			}
			else
			{
				loadedBRIRFilePath = fullPath;
				loadedBRIRFileName = GetFileName(loadedBRIRFilePath);
				
				ClearLoadedCaseStudy();
				cout << "Load new BRIR File " << loadedBRIRFilePath << endl << endl;
				SetDefaultSecondsToRecordIR();
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

void ofApp::StartWavRecord(std::string& filename, int bitspersample)
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

	SetSecondsToRecordIR(secondsToRecordIR);

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

std::string ofApp::GetFileIncrementalName(const std::string& _fileName) {
	std::string newFileNamePath = _fileName;
	std::string extension = ofFilePath().getFileExt(newFileNamePath);
	std::string folderPath = ofFilePath().getEnclosingDirectory(newFileNamePath, false);
	std::string fileName = ofFilePath().getBaseName(newFileNamePath);

	int i = 0;
	while (FileExist(newFileNamePath)) {
		i++;
		std::string fileNameTemp = fileName + "_" + std::to_string(i) + "." + extension;
		newFileNamePath = ofFilePath().join(ofFilePath().addTrailingSlash(folderPath), fileNameTemp);
	}
	return newFileNamePath;
}

bool ofApp::FileExist(const std::string& _filePath) {
	return ofFile(_filePath, ofFile::Reference).exists();
}

std::string ofApp::GetFileName(const std::string& fullPath)
{
	// get file name with extension using ofFilePath
	std::string fileNameWithExtension = ofFilePath().getFileName(fullPath);
	return fileNameWithExtension;
}

// Others
void ofApp::SetDefaultSecondsToRecordIR()
{
	int BRIRLength = environment->GetBRIR()->GetBRIRLength();
	float sampleRate = myCore.GetAudioState().sampleRate;
	float _secondsToRecordIR = ((float)BRIRLength) / sampleRate;
	SetSecondsToRecordIR(_secondsToRecordIR);	
}

void ofApp::SetSecondsToRecordIR(float & _secondsToRecordIR)
{
	if (_secondsToRecordIR > 0 && _secondsToRecordIR <= MAX_SECONDS_TO_RECORD)
	{
		secondsToRecordIR = _secondsToRecordIR;
		numberOfSecondsToRecordControl.set(secondsToRecordIR);
	}
}


TCaseStudy ofApp::FindCaseStudy(std::string _id) {
	int index = std::find_if(caseStudies.begin(), caseStudies.end(), [&_id](const TCaseStudy& cs) { return cs.id == _id; }) - caseStudies.begin();

	if (index != -1) {
		return caseStudies.at(index);
	}
	else {
		std::cout << "Error: Case Study not found with id " << _id << std::endl;
		return TCaseStudy();
	}	
}