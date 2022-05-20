#include "ofApp.h"

#define SAMPLERATE 44100
#define BUFFERSIZE 512

#define SOURCE_STEP 0.02f
#define LISTENER_STEP 0.01f
#define MAX_REFLECTION_ORDER 4
#define NUMBER_OF_WALLS 6


//--------------------------------------------------------------
void ofApp::setup() {

	// Core setup
	Common::TAudioStateStruct audioState;	    // Audio State struct declaration
	audioState.bufferSize = BUFFERSIZE;			// Setting buffer size 
	audioState.sampleRate = SAMPLERATE;			// Setting frame rate 
	myCore.SetAudioState(audioState);		    // Applying configuration to core
	myCore.SetHRTFResamplingStep(15);		    // Setting 15-degree resampling step for HRTF


	// Listener setup
	listener = myCore.CreateListener();								 // First step is creating listener
	Common::CVector3 listenerLocation(0, 0, 0);
	Common::CTransform listenerPosition = Common::CTransform();		 // Setting listener in (0,0,0)
	listenerPosition.SetPosition(listenerLocation);
	listener->SetListenerTransform(listenerPosition);
	listener->DisableCustomizedITD();								 // Disabling custom head radius
	// HRTF can be loaded in SOFA (more info in https://sofacoustics.org/) Some examples of HRTF files can be found in 3dti_AudioToolkit/resources/HRTF
	bool specifiedDelays;
	bool sofaLoadResult = HRTF::CreateFromSofa("hrtf.sofa", listener, specifiedDelays);
	//bool sofaLoadResult = HRTF::CreateFromSofa("UMA_NULL_S_HRIR_512.sofa", listener, specifiedDelays);
	if (!sofaLoadResult) {
		cout << "ERROR: Error trying to load the SOFA file" << endl << endl;
	}

	/************************/
	// Environment setup
	environment = myCore.CreateEnvironment();									// Creating environment to have reverberated sound
	environment->SetReverberationOrder(TReverberationOrder::ADIMENSIONAL);		// Setting number of ambisonic channels to use in reverberation processing
	BRIR::CreateFromSofa("brir.sofa", environment);								// Loading SOFAcoustics BRIR file and applying it to the environment
	
	environment->SetNumberOfSilencedFrames(9);
	
	// Room setup
	ISM::RoomGeometry trapezoidal;

	/////////////Read the XML file with the geometry of the room and absorption of the walls////////
	string pathData = ofToDataPath("", true);
	string fileName = pathData + "\\theater_room.xml";
	if (!xml.load(pathData+"\\theater_room.xml"))
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
	shoeboxLength = 20; shoeboxWidth = 20; shoeboxHeight = 10;
	//ISMHandler->SetupShoeBoxRoom(shoeboxLength, shoeboxWidth, shoeboxHeight);
		
	

	//Absortion as escalar
	ISMHandler->setAbsortion({ 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3 });
	//Absortion as vector
	ISMHandler->setAbsortion( (std::vector<std::vector<float>>)  absortionsWalls);

	ISMHandler->setReflectionOrder(INITIAL_REFLECTION_ORDER);

	mainRoom = ISMHandler->getRoom();

	// setup of the anechoic source
	Common::CVector3 initialLocation(13, 0, -4);
	ISMHandler->setSourceLocation(initialLocation,listenerLocation);					// Source to be rendered
	anechoicSourceDSP = myCore.CreateSingleSourceDSP();								// Creating audio source
	Common::CTransform sourcePosition;
	sourcePosition.SetPosition(initialLocation);
	anechoicSourceDSP->SetSourceTransform(sourcePosition);							//Set source position
	anechoicSourceDSP->SetSpatializationMode(Binaural::TSpatializationMode::HighQuality);	// Choosing high quality mode for anechoic processing
	anechoicSourceDSP->DisableNearFieldEffect();											// Audio source will not be close to listener, so we don't need near field effect
	anechoicSourceDSP->EnableAnechoicProcess();										// Enable anechoic processing for this source
	//anechoicSourceDSP->DisableAnechoicProcess();										// Disable anechoic processing for this source
	//stateAnechoicProcess = false;
	anechoicSourceDSP->EnableDistanceAttenuationAnechoic();								// Do not perform distance simulation
	anechoicSourceDSP->EnableDistanceAttenuationReverb();
	anechoicSourceDSP->EnablePropagationDelay();

	// setup of the image sources
	imageSourceDSPList = createImageSourceDSP();

	LoadWavFile(source1Wav, "speech_female.wav");									// Loading .wav file										   
	//LoadWavFile(source1Wav, "sweep0_5.wav");											// Loading .wav file										   

	//AudioDevice Setup
	//// Before getting the devices list for the second time, the strean must be closed. Otherwise,
	//// the app crashes when systemSoundStream.start(); or stop() are called.
	systemSoundStream.close();
	SetDeviceAndAudio(audioState);

	//GUI setup
	logoUMA.loadImage("UMA.png");
	logoUMA.resize(logoUMA.getWidth() / 10, logoUMA.getHeight() / 10);
	titleFont.load("Verdana.ttf", 32);
	logoSAVLab.loadImage("SAVLab.png");
	logoSAVLab.resize(logoSAVLab.getWidth() / 10, logoSAVLab.getHeight() / 10);

	leftPanel.setup("Controls", "config.xml", 20, 150);
	leftPanel.setWidthElements(200);
	zoom.addListener(this, &ofApp::changeZoom);
	leftPanel.add(zoom.setup("Zoom", 0, -20, 20, 50, 15));
	reflectionOrderControl.addListener(this, &ofApp::changeReflectionOrder);
	leftPanel.add(reflectionOrderControl.set("Order", INITIAL_REFLECTION_ORDER, 0, 4));
	//for (int i = 0; i < NUMBER_OF_WALLS; i++)
	int numWalls = ISMHandler->getRoom().getWalls().size();
	for (int i = 0; i < numWalls; i++)
	{
		ofParameter<bool> tempWall;
		guiActiveWalls.push_back(tempWall);
		guiActiveWalls.at(i).addListener(this, &ofApp::toggleWall);
		leftPanel.add(guiActiveWalls.at(i).set(wallNames.at(i), true));
	}
}


//--------------------------------------------------------------
void ofApp::update() {

}

//--------------------------------------------------------------
void ofApp::draw() {
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

	//draw room and room images
	drawRoom(mainRoom, reflectionOrderControl,255);

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

	//draw image sources 
	int numberOfVisibleImages = 0;
	std::vector<ISM::ImageSourceData> imageSourceDataList = ISMHandler->getImageSourceData(listenerLocation);
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
	/// This work has been partially funded by the Spanish project Spatial Audio Virtual Laboratory (SAVLab) - PID2019-107854GB-I00, Ministerio de Ciencia e Innovaci�n
	ofDrawBitmapString("This work has been partially", ofGetWidth() - 280, 140);
	ofDrawBitmapString("funded by the Spanish project", ofGetWidth() - 280, 155);
	ofDrawBitmapString("Spatial Audio Virtual Laboratory", ofGetWidth() - 280, 170);
	ofDrawBitmapString("(SAVLab) - PID2019-107854GB-I00", ofGetWidth() - 280, 185);
	ofDrawBitmapString("Ministerio de Ciencia e Innovacion", ofGetWidth() - 280, 200);

	/// print number of visible images
	ofPushStyle();
	ofSetColor(50, 150);
	ofRect(ofGetWidth() - 300, ofGetHeight()- 110, 270, 75);
	ofPopStyle();
	char numberOfImagesStr[255];
	sprintf(numberOfImagesStr, "Number of visible images: %d", numberOfVisibleImages);
	ofDrawBitmapString(numberOfImagesStr, ofGetWidth() - 280, ofGetHeight() - 85);
	sprintf(numberOfImagesStr, "Number of source DSPs: %d", imageSourceDSPList.size()+1);  //number of DSPs for teh images plus one for the anechoic
	ofDrawBitmapString(numberOfImagesStr, ofGetWidth() - 280, ofGetHeight()-55);

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
//	case OF_KEY_PAGE_UP:
//		scale*=0.9;
//		break;
//	case OF_KEY_PAGE_DOWN:
//		scale*=1.1;
//		break;
	case OF_KEY_PAGE_UP:
	{
		int numberOfSilencedFrames;
		numberOfSilencedFrames = environment->GetNumberOfSilencedFrames();
		numberOfSilencedFrames++;
		environment->SetNumberOfSilencedFrames(numberOfSilencedFrames);
		break;
	}
	case OF_KEY_PAGE_DOWN:
	{
		int numberOfSilencedFrames;
		numberOfSilencedFrames = environment->GetNumberOfSilencedFrames();
		numberOfSilencedFrames--;
		environment->SetNumberOfSilencedFrames(numberOfSilencedFrames);
		break;
	}

	case'r':
		if (bEnableReverb) bEnableReverb=false;
		else bEnableReverb = true;
	break;

	case 'o': // setup Room=5x5x5, Absortion=0, Listener in (1,1,1), source in (4,0,0) --> top 
	{
		systemSoundStream.stop();
		//ROOM
						
		shoeboxLength = 10; shoeboxWidth = 10; shoeboxHeight = 5;
		ISMHandler->SetupShoeBoxRoom(shoeboxLength, shoeboxWidth, shoeboxHeight);
		
		
		int numWalls = ISMHandler->getRoom().getWalls().size();
		absortionsWalls.resize(numWalls);
		
		ISMHandler->setAbsortion({ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 });
		for (int i = 0; i < numWalls; i++) {
			absortionsWalls.at(i) = { 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 };
		}
		ISMHandler->setAbsortion((std::vector<std::vector<float>>)  absortionsWalls);

		reflectionOrderControl = INITIAL_REFLECTION_ORDER;
		mainRoom = ISMHandler->getRoom();
						
		//LISTENER
		Common::CVector3 listenerLocation(1, 1, 1);
		Common::CTransform listenerPosition = Common::CTransform();		 // Setting listener in (1,1,1)
		listenerPosition.SetPosition(listenerLocation);
		listener->SetListenerTransform(listenerPosition);

				
		//SOURCE
		// Set the original anechoic source to corner
		Common::CVector3 newLocation(4, 0, 0);
		ISMHandler->setSourceLocation(newLocation,listenerLocation);
		Common::CTransform sourcePosition;
		sourcePosition.SetPosition(newLocation);
		anechoicSourceDSP->SetSourceTransform(sourcePosition);

		//WALLs
		guiActiveWalls.resize(numWalls);
		for (int i = 1; i < numWalls; i++)
			guiActiveWalls.at(i) = FALSE;

		//SOURCES DSP
		imageSourceDSPList = createImageSourceDSP();

		// Disable AnechoicProcess 

		if (anechoicSourceDSP->IsAnechoicProcessEnabled())
		{
			anechoicSourceDSP->DisableAnechoicProcess();
			stateAnechoicProcess = false;
		}
		systemSoundStream.start();
	}
	break;

	case 'p': //toggles between enabled and disabled AnechoicProcess 
	{
		if (anechoicSourceDSP->IsAnechoicProcessEnabled())
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
		ISMHandler->setSourceLocation(Location, listenerLocation);  //FIXME: when the listener is moved images should be updated
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
		ISMHandler->setSourceLocation(Location, listenerLocation); // FIXME: when the listener is moved images should be updated
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
		ISMHandler->setSourceLocation(Location, listenerLocation); // FIXME: when the listener is moved images should be updated
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
		ISMHandler->setSourceLocation(Location, listenerLocation); // FIXME: when the listener is moved images should be updated
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
		ISMHandler->setSourceLocation(Location, listenerLocation); // FIXME: when the listener is moved images should be updated
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
		ISMHandler->setSourceLocation(Location, listenerLocation); // FIXME: when the listener is moved images should be updated
		break;
	}
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
	case OF_KEY_F1://ABSORTION -- null
	{
	    systemSoundStream.stop();
		ISMHandler->setAbsortion(  {0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0});
		int numWalls = ISMHandler->getRoom().getWalls().size();
		for (int i = 0; i < numWalls; i++) {
			absortionsWalls.at(i) = { 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 };
		}
		ISMHandler->setAbsortion((std::vector<std::vector<float>>)  absortionsWalls);
		
		imageSourceDSPList = createImageSourceDSP();
		mainRoom = ISMHandler->getRoom();
		systemSoundStream.start();
		break;
	}
	case OF_KEY_F2://ABSORTION -- total
	{
		systemSoundStream.stop();
		ISMHandler->setAbsortion(  {1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0});

		int numWalls = ISMHandler->getRoom().getWalls().size();
		for (int i = 0; i < numWalls; i++) {
			absortionsWalls.at(i) = { 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0 };
		}
		ISMHandler->setAbsortion((std::vector<std::vector<float>>)  absortionsWalls);
	
		imageSourceDSPList = createImageSourceDSP();
		mainRoom = ISMHandler->getRoom();
		systemSoundStream.start();
		break;
	}
	case OF_KEY_F3://ABSORTION -- LP + HP
	{
		systemSoundStream.stop();	
		ISMHandler->setAbsortion(  {0.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 0.0});

		int numWalls = ISMHandler->getRoom().getWalls().size();
		for (int i = 0; i < numWalls; i++) {
			absortionsWalls.at(i) = { 0.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 0.0 };
		}
		ISMHandler->setAbsortion((std::vector<std::vector<float>>)  absortionsWalls);
		
		imageSourceDSPList = createImageSourceDSP();
		mainRoom = ISMHandler->getRoom();
		systemSoundStream.start();
		break;
	}
	case OF_KEY_F4://ABSORTION -- BP-250-4000
	{
		systemSoundStream.stop();
		ISMHandler->setAbsortion(  {1.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0});

		int numWalls = ISMHandler->getRoom().getWalls().size();
		for (int i = 0; i < numWalls; i++) {
			absortionsWalls.at(i) = { 1.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0 };
		}
		ISMHandler->setAbsortion((std::vector<std::vector<float>>)  absortionsWalls);
		
		imageSourceDSPList = createImageSourceDSP();
		mainRoom = ISMHandler->getRoom();
		systemSoundStream.start();
		break;
	}
	case OF_KEY_F5://ABSORTION -- BP-Narrow-1000
	{
		systemSoundStream.stop();
		ISMHandler->setAbsortion(  {1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0});

		int numWalls = ISMHandler->getRoom().getWalls().size();
		for (int i = 0; i < numWalls; i++) {
			absortionsWalls.at(i) = { 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0 };
		}
		ISMHandler->setAbsortion((std::vector<std::vector<float>>)  absortionsWalls);

		imageSourceDSPList = createImageSourceDSP();
		mainRoom = ISMHandler->getRoom();
		systemSoundStream.start();
		break;
	}
	case OF_KEY_F6://ABSORTION STOPB
	{
		systemSoundStream.stop();
		ISMHandler->setAbsortion(  {0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0});

		int numWalls = ISMHandler->getRoom().getWalls().size();
		for (int i = 0; i < numWalls; i++) {
			absortionsWalls.at(i) = { 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0 };
		}
		ISMHandler->setAbsortion((std::vector<std::vector<float>>)  absortionsWalls);

		imageSourceDSPList = createImageSourceDSP();
		mainRoom = ISMHandler->getRoom();
		systemSoundStream.start();
		break;
	}
	case OF_KEY_F7://Initial Room
	{
		systemSoundStream.stop();

		ISM::RoomGeometry InitialRoom;
		/////////////Read the XML file with the geometry of the room and absorption of the walls////////
		string pathData = ofToDataPath("", true);
		string fileName = pathData + "\\theater_room.xml";
		if (!xml.load(pathData + "\\theater_room.xml"))
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
				InitialRoom.corners.push_back(tempP3d);
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
				InitialRoom.walls.push_back(tempCornersWall);

				std::string strVectFloat = aux.getAttribute("absor").getValue();
				std::vector<float> tempAbsorsWall = parserStToFloat(strVectFloat);
				absortionsWalls.push_back(tempAbsorsWall);
			}
		}
		////////////////////////////////////////////////
		ISMHandler->setupArbitraryRoom(InitialRoom);
		
		int numWalls = ISMHandler->getRoom().getWalls().size();
		guiActiveWalls.resize(numWalls);
				
		//Absortion as escalar
		ISMHandler->setAbsortion({ 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3 });
		//Absortion as vector
		ISMHandler->setAbsortion((std::vector<std::vector<float>>)  absortionsWalls);

		//////////////////////////////////
		imageSourceDSPList = createImageSourceDSP();
		mainRoom = ISMHandler->getRoom();

		systemSoundStream.start();
		break;
	}
	case 'y': //increase room's length
		systemSoundStream.stop();
		shoeboxLength += 0.5;
		ISMHandler->SetupShoeBoxRoom(shoeboxLength, shoeboxWidth, shoeboxHeight);
				
		ISMHandler->setAbsortion({ 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3 });
		ISMHandler->setAbsortion({ {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3} });
		//ISMHandler_new->setReflectionOrder(INITIAL_REFLECTION_ORDER);
		mainRoom = ISMHandler->getRoom();
		imageSourceDSPList = createImageSourceDSP();

		systemSoundStream.start();
		break;
	case 'b': //decrease room's length
		systemSoundStream.stop();
		if (shoeboxLength > 2.5)  shoeboxLength -= 0.5;
		ISMHandler->SetupShoeBoxRoom(shoeboxLength, shoeboxWidth, shoeboxHeight);
		ISMHandler->setAbsortion(  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3});
		ISMHandler->setAbsortion({ {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3} });
		//ISMHandler_new->setReflectionOrder(INITIAL_REFLECTION_ORDER);
		mainRoom = ISMHandler->getRoom();
		imageSourceDSPList = createImageSourceDSP();

		systemSoundStream.start();
		break;
	case 'g': //decrease room's width
		systemSoundStream.stop();
		if (shoeboxWidth > 2.2) shoeboxWidth -= 0.2;
		ISMHandler->SetupShoeBoxRoom(shoeboxLength, shoeboxWidth, shoeboxHeight);
		ISMHandler->setAbsortion(  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3});
		ISMHandler->setAbsortion({ {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3} });
		//ISMHandler_new->setReflectionOrder(INITIAL_REFLECTION_ORDER);
		mainRoom = ISMHandler->getRoom();
		imageSourceDSPList = createImageSourceDSP();

		systemSoundStream.start();
		break;
	case 'h': //increase room's width
		systemSoundStream.stop();
		shoeboxWidth += 0.2;
		ISMHandler->SetupShoeBoxRoom(shoeboxLength, shoeboxWidth, shoeboxHeight);
		ISMHandler->setAbsortion(  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3});
		ISMHandler->setAbsortion({ {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3} });
		//ISMHandler_new->setReflectionOrder(INITIAL_REFLECTION_ORDER);
		mainRoom = ISMHandler->getRoom();
		imageSourceDSPList = createImageSourceDSP();

		systemSoundStream.start();
		break;
	case 'v': //decrease room's height
		systemSoundStream.stop();
		if (shoeboxHeight > 2.2) shoeboxHeight -= 0.2;
		ISMHandler->SetupShoeBoxRoom(shoeboxLength, shoeboxWidth, shoeboxHeight);
		ISMHandler->setAbsortion(  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3});
		ISMHandler->setAbsortion({ {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3} });
		//ISMHandler_new->setReflectionOrder(INITIAL_REFLECTION_ORDER);
		mainRoom = ISMHandler->getRoom();
		imageSourceDSPList = createImageSourceDSP();

		systemSoundStream.start();
		break;
	case 'n': //increase room's height
		systemSoundStream.stop();
		shoeboxHeight += 0.2;
		ISMHandler->SetupShoeBoxRoom(shoeboxLength, shoeboxWidth, shoeboxHeight);
		ISMHandler->setAbsortion(  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3});
		ISMHandler->setAbsortion({ {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3},
								  {0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3} });
		//ISMHandler_new->setReflectionOrder(INITIAL_REFLECTION_ORDER);
		mainRoom = ISMHandler->getRoom();
		imageSourceDSPList = createImageSourceDSP();

		systemSoundStream.start();
		break;
	case 't': //Test
		std::vector<ISM::ImageSourceData> data = ISMHandler->getImageSourceData(listenerLocation);
		auto w2 = std::setw(2);
		auto w5 = std::setw(5);
		auto w7 = std::setw(7);
		cout << "------------------------------------------------List of Source Images -------------------------------------\n";
		cout << "  Visibility  | Refl. |                Reflection coeficients                  |          Location  \n";
		cout << "              | order | ";
		float freq = 62.5;
		for (int i = 0; i < NUM_BAND_ABSORTION; i++)
		{
			if(freq < 100) { cout << ' '; }
			if(freq < 1000) { cout << ((int) freq) << "Hz "; }
			else { cout << w2 << ((int) (freq / 1000)) << "kHz "; }
			freq *= 2;
		}
		cout << " |     X        Y        Z    \n";
		cout << "--------------+-------+--------------------------------------------------------+---------------------------\n";
		for (int i = 0; i < data.size(); i++)
		{
			if (data.at(i).visible) cout << "VISIBLE "; else cout << "        ";
			cout << w5 << std::fixed << std::setprecision(2) << data.at(i).visibility;
			cout << " |   " << data.at(i).reflectionWalls.size();
			cout << "   | ";
			for (int j = 0; j < NUM_BAND_ABSORTION; j++)
			{ 
				cout << w5 << std::fixed << std::setprecision(2) << data.at(i).reflectionBands.at(j) << " ";
			}
			cout << " | " << w7 << std::fixed << std::setprecision(2) << data.at(i).location.x << ", ";
			cout << w7 << std::fixed << std::setprecision(2) << data.at(i).location.y << ", ";
			cout << w7 << std::fixed << std::setprecision(2) << data.at(i).location.z << "\n";
		}
		cout << "Shoebox \n";
		cout << "X=" << shoeboxLength << "\n" << "Y=" << shoeboxWidth << "\n" << "Z=" << shoeboxHeight << "\n";
		if (stateAnechoicProcess) 
			cout << "AnechoicProcess Enabled" << "\n";
		else 
			cout << "AnechoicProcess Disabled" << "\n";
		if (bEnableReverb)
			cout << "Reverb Enabled" << "\n";
		else
			cout << "Reverb Disabled" << "\n";

		cout << "NumberOfSilencedFrames = " << environment->GetNumberOfSilencedFrames() << "\n";
		
		break;
		
		
	}
}

//--------------------------------------------------------------
void ofApp::keyReleased(int key){

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
			  // will take up.You should probably use two for each channel that you�re using.Here�s an 
			 // example call : ofSoundStreamSetup(2, 0, 44100, 256, 4);
			//     http://openframeworks.cc/documentation/sound/ofSoundStream/
		);
		cout << "Device selected : " << "ID: " << dev.deviceID << "  Name: " << dev.name << endl;

	}
	else
	{
		cout << "Could not find any usable sound Device" << endl;
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
void ofApp::audioOut(float * output, int bufferSize, int nChannels) {

	// The requested frame size is not allways supported by the audio driver:
	if (myCore.GetAudioState().bufferSize != bufferSize)
		return;

	// Prepare output chunk
	Common::CEarPair<CMonoBuffer<float>> bOutput;
	bOutput.left.resize(bufferSize);
	bOutput.right.resize(bufferSize);
	
	// Process audio
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

/// Process audio using the 3DTI Toolkit methods
void ofApp::audioProcess(Common::CEarPair<CMonoBuffer<float>> & bufferOutput, int uiBufferSize)
{
	// Declaration, initialization and filling mono buffers
	CMonoBuffer<float> source1(uiBufferSize);  //FIXME cambiar el nombre source1
	
	source1Wav.FillBuffer(source1);
	CMonoBuffer<float> &bufferInput = source1;
	anechoicSourceDSP->SetBuffer(bufferInput);

	processAnechoic(source1, bufferOutput);

	if (bEnableReverb) 
	{
		processReverb(source1, bufferOutput);
	}

	Common::CTransform lisenerTransform = listener->GetListenerTransform();
	Common::CVector3 lisenerPosition = lisenerTransform.GetPosition();

	processImages(source1, bufferOutput);
	
}

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
	environment->ProcessVirtualAmbisonicReverb(bufferReverb.left, bufferReverb.right);
	// Adding reverberated sound to the direct path
	bufferReverb.left.ApplyGain(0.25);
	bufferReverb.right.ApplyGain(0.25);
	bufferOutput.left += bufferReverb.left;
	bufferOutput.right += bufferReverb.right;

}


void ofApp::processImages(CMonoBuffer<float> &bufferInput, Common::CEarPair<CMonoBuffer<float>> & bufferOutput)
{
	Common::CTransform listenerTransform = listener->GetListenerTransform();
	Common::CVector3 listenerLocation = listenerTransform.GetPosition();
	std::vector<ISM::ImageSourceData> data = ISMHandler->getImageSourceData(listenerLocation);

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
	/*
	float distanceNearestWall;
	bool state;
	Common::CVector3 point = Common::CVector3::ZERO;
	point.x = 5.2; point.y = 5.2; point.z = 5.2;
	state = room.checkPointInsideRoom(point, distanceNearestWall);
	*/
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
	ISMHandler->setSourceLocation(newLocation,listenerLocation);
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

////////////////////////////////////////////////////////////////////////////////////////
//Methods for managing GUI 
////////////////////////////////////////////////////////////////////////////////////////

void ofApp::changeZoom(int &zoom) 
{
	scale = DEFAULT_SCALE * pow(1.1, zoom);
}

void ofApp::changeReflectionOrder(int &_reflectionOrder)
{
	systemSoundStream.stop();
	ISMHandler->setReflectionOrder(_reflectionOrder);
	imageSourceDSPList = createImageSourceDSP();
	systemSoundStream.start();
}

void ofApp::toggleWall(bool &_active)
{
	refreshActiveWalls();
}
void ofApp::refreshActiveWalls()
{
	systemSoundStream.stop();
	Common::CTransform listenerTransform = listener->GetListenerTransform();
	Common::CVector3 listenerLocation = listenerTransform.GetPosition();
	for (int i = 0; i < guiActiveWalls.size(); i++)
	{
		if (guiActiveWalls.at(i))
		{
			ISMHandler->enableWall(i, listenerLocation);
		}
		else
		{
			ISMHandler->disableWall(i, listenerLocation);
		}
	}
	mainRoom = ISMHandler->getRoom();
	imageSourceDSPList = createImageSourceDSP();
	systemSoundStream.start();
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
