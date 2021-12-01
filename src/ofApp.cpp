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
	if (!sofaLoadResult) {
		cout << "ERROR: Error trying to load the SOFA file" << endl << endl;
	}

	// Room setup
	ISM::RoomGeometry trapezoidal;
	trapezoidal.corners = { Common::CVector3(2,2,-1),
							Common::CVector3(2,-2,-1),
							Common::CVector3(2,-2,1),
							Common::CVector3(2,2,1),
							Common::CVector3(-1,-3,-1),
							Common::CVector3(-2,2,-1),
							Common::CVector3(-2,2,1),
							Common::CVector3(-1,-3,1),
	};
	trapezoidal.walls = { {0,1,2,3},{5,0,3,6},{1,4,7,2},{4,5,6,7},{0,5,4,1},{3,2,7,6} };
	ISMHandler.setupArbitraryRoom(trapezoidal);
	ISMHandler.setAbsortion({ 0.3, 0.3, 0.3, 0.3, 0.3, 0.3 });


	shoeboxLength = 7; shoeboxWidth = 10; shoeboxHeight = 3;
	//	ISMHandler.SetupShoeBoxRoom(shoeboxLength, shoeboxWidth, shoeboxHeight);

	ISMHandler.setReflectionOrder(INITIAL_REFLECTION_ORDER);

	mainRoom = ISMHandler.getRoom();

	// setup of the anechoic source
	Common::CVector3 initialLocation(1, 0, 0);
	ISMHandler.setSourceLocation(initialLocation);									// Source to be rendered
	anechoicSourceDSP = myCore.CreateSingleSourceDSP();								// Creating audio source
	Common::CTransform sourcePosition;
	sourcePosition.SetPosition(initialLocation);
	anechoicSourceDSP->SetSourceTransform(sourcePosition);							//Set source position
	anechoicSourceDSP->SetSpatializationMode(Binaural::TSpatializationMode::HighQuality);	// Choosing high quality mode for anechoic processing
	anechoicSourceDSP->DisableNearFieldEffect();											// Audio source will not be close to listener, so we don't need near field effect
	anechoicSourceDSP->EnableAnechoicProcess();											// Enable anechoic processing for this source
	anechoicSourceDSP->EnableDistanceAttenuationAnechoic();								// Do not perform distance simulation
	anechoicSourceDSP->EnablePropagationDelay();

	// setup of the image sources
	imageSourceDSPList = createImageSourceDSP();

	LoadWavFile(source1Wav, "speech_female.wav");											// Loading .wav file										   

	//AudioDevice Setup
	//// Before getting the devices list for the second time, the strean must be closed. Otherwise,
	//// the app crashes when systemSoundStream.start(); or stop() are called.
	systemSoundStream.close();
	SetDeviceAndAudio(audioState);

	//GUI setup
	logoUMA.loadImage("UMA.png");
	logoUMA.resize(logoUMA.getWidth() / 10, logoUMA.getHeight() / 10);
	titleFont.load("Verdana.ttf", 32);

	leftPanel.setup("Controls", "config.xml", 20, 150);
	leftPanel.setWidthElements(200);
	zoom.addListener(this, &ofApp::changeZoom);
	leftPanel.add(zoom.setup("Zoom", 0, -20, 20, 50, 15));
	reflectionOrderControl.addListener(this, &ofApp::changeReflectionOrder);
	leftPanel.add(reflectionOrderControl.set("Order", INITIAL_REFLECTION_ORDER, 0, 4));
	for (int i = 0; i < NUMBER_OF_WALLS; i++)
	{
		ofParameter<bool> tempWall;
		activeWalls.push_back(tempWall);
		activeWalls.at(i).addListener(this, &ofApp::toggleWall);
		leftPanel.add(activeWalls.at(i).set(wallNames.at(i), true));
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

	ofSetColor(255, 250);									// deault drawing color is white 

	if (reflectionOrderControl > 0)
	{
		drawRoom(mainRoom);
		if (reflectionOrderControl > 1)
		{
			std::vector<ISM::Room> roomImages = mainRoom.getImageRooms();
			ofPushStyle();
			ofSetColor(255, 50);									//image rooms are drawn semi-transparent
			for (int i = 0; i < roomImages.size(); i++) drawRoom(roomImages.at(i));
			if (reflectionOrderControl > 2)
			{
				ofSetColor(255, 10);									//second image rooms are drawn almost transparent
				for (int i = 0; i < roomImages.size(); i++)
				{
					std::vector<ISM::Room> roomSecondImages = roomImages.at(i).getImageRooms();
					for (int j = 0; j < roomSecondImages.size(); j++)
					{
						drawRoom(roomSecondImages.at(j));
					}
				}
			}
		}
	}
	ofPopStyle();

	//draw lisener
	Common::CTransform listenerTransform = listener->GetListenerTransform();
	Common::CVector3 listenerLocation = listenerTransform.GetPosition();
	ofSphere(listenerLocation.x, listenerLocation.y, listenerLocation.z, 0.09);						//draw listener

	//draw anechoic source
	ofPushStyle();
	ofSetColor(255, 50, 200, 50);
	Common::CVector3 sourceLocation = ISMHandler.getSourceLocation();
	ofBox(sourceLocation.x, sourceLocation.y, sourceLocation.z, 0.2);								//draw anechoic source
	ofLine(sourceLocation.x, sourceLocation.y, sourceLocation.z,
		listenerLocation.x, listenerLocation.y, listenerLocation.z);								//draw ray from anechoic source

	//draw image sources 
	int numberOfVisibleImages = 0;
	std::vector<ISM::ImageSourceData> imageSourceDataList = ISMHandler.getImageSourceData(listenerLocation);
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

//	drawImages(sourceImages, reflectionOrder);
	ofPopStyle();
	//sourceImages.drawFirstReflectionRays(listenerPosition);
	//drawRaysToListener(sourceImages, listenerLocation, reflectionOrder);

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

	/// print number of visible images
	ofPushStyle();
	ofSetColor(50, 150);
	ofRect(ofGetWidth() - 300, 35, 270, 75);
	ofPopStyle();
	char numberOfImagesStr[255];
	sprintf(numberOfImagesStr, "Number of visible images: %d", numberOfVisibleImages);
	ofDrawBitmapString(numberOfImagesStr, ofGetWidth() - 280, 55);
	sprintf(numberOfImagesStr, "Number of source DSPs: %d", imageSourceDSPList.size()+1);  //number of DSPs for teh images plus one for the anechoic
	ofDrawBitmapString(numberOfImagesStr, ofGetWidth() - 280, 85);

	leftPanel.draw();
}

//--------------------------------------------------------------
void ofApp::keyPressed(int key){

	Common::CTransform listenerTransform = listener->GetListenerTransform();
	Common::CVector3 listenerLocation = listenerTransform.GetPosition();

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
		listenerTransform.Translate(Common::CVector3(-LISTENER_STEP, 0, 0));
		listener->SetListenerTransform(listenerTransform);
		break;
	case 'w': //Moves the listener right (X)
		listenerTransform.Translate(Common::CVector3(LISTENER_STEP, 0, 0));
		listener->SetListenerTransform(listenerTransform);
		break;
	case 'a': //Moves the listener up (Y)
		listenerTransform.Translate(Common::CVector3(0, LISTENER_STEP, 0));
		listener->SetListenerTransform(listenerTransform);
		break;
	case 'd': //Moves the listener down (-Y)
		listenerTransform.Translate(Common::CVector3(0, -LISTENER_STEP, 0));
		listener->SetListenerTransform(listenerTransform);
		break;
	case 'e': //Moves the listener up (Z)
		listenerTransform.Translate(Common::CVector3(0, 0, LISTENER_STEP));
		listener->SetListenerTransform(listenerTransform);
		break;
	case 'x': //Moves the listener up (--Z)
		listenerTransform.Translate(Common::CVector3(0, 0, -LISTENER_STEP));
		listener->SetListenerTransform(listenerTransform);
		break;
	case '+': //increases the reflection order 
		if(reflectionOrderControl<MAX_REFLECTION_ORDER) reflectionOrderControl++;
		break;
	case '-': //decreases the reflection order 
		if (reflectionOrderControl > 0) reflectionOrderControl--;
		break;
	case '1': //enable/disable wall number 1 
		activeWalls.at(0) = !activeWalls.at(0);
		refreshActiveWalls();
		break;
	case '2': //enable/disable wall number 2 
		activeWalls.at(1) = !activeWalls.at(1);
		refreshActiveWalls();
		break;
	case '3': //enable/disable wall number 3 
		activeWalls.at(2) = !activeWalls.at(2);
		refreshActiveWalls();
		break;
	case '4': //enable/disable wall number 4 
		activeWalls.at(3) = !activeWalls.at(3);
		refreshActiveWalls();
		break;
	case '5': //enable/disable wall number 5 
		activeWalls.at(4) = !activeWalls.at(4);
		refreshActiveWalls();
		break;
	case '6': //enable/disable wall number 6 
		activeWalls.at(5) = !activeWalls.at(5);
		refreshActiveWalls();
		break;
	case 'y': //increase room's length
		systemSoundStream.stop();
		shoeboxLength += 0.2;
		ISMHandler.SetupShoeBoxRoom(shoeboxLength, shoeboxWidth, shoeboxHeight);
		mainRoom = ISMHandler.getRoom();
		systemSoundStream.start();
		break;
	case 'b': //decrease room's length
		systemSoundStream.stop();
		shoeboxLength -= 0.2;
		ISMHandler.SetupShoeBoxRoom(shoeboxLength, shoeboxWidth, shoeboxHeight);
		mainRoom = ISMHandler.getRoom();
		systemSoundStream.start();
		break;
	case 'g': //decrease room's width
		systemSoundStream.stop();
		shoeboxWidth -= 0.2;
		ISMHandler.SetupShoeBoxRoom(shoeboxLength, shoeboxWidth, shoeboxHeight);
		mainRoom = ISMHandler.getRoom();
		systemSoundStream.start();
		break;
	case 'h': //increase room's width
		systemSoundStream.stop();
		shoeboxWidth += 0.2;
		ISMHandler.SetupShoeBoxRoom(shoeboxLength, shoeboxWidth, shoeboxHeight);
		mainRoom = ISMHandler.getRoom();
		systemSoundStream.start();
		break;
	case 'v': //decrease room's height
		systemSoundStream.stop();
		shoeboxHeight -= 0.2;
		ISMHandler.SetupShoeBoxRoom(shoeboxLength, shoeboxWidth, shoeboxHeight);
		mainRoom = ISMHandler.getRoom();
		systemSoundStream.start();
		break;
	case 'n': //increase room's height
		systemSoundStream.stop();
		shoeboxHeight += 0.2;
		ISMHandler.SetupShoeBoxRoom(shoeboxLength, shoeboxWidth, shoeboxHeight);
		mainRoom = ISMHandler.getRoom();
		systemSoundStream.start();
		break;
	case 't': //Test
		std::vector<ISM::ImageSourceData> data = ISMHandler.getImageSourceData(listenerLocation);
		auto w = std::setw(6);
		cout << "--------------------------------------------------\n";
		for (int i = 0; i < data.size(); i++)
		{
			if (data.at(i).visible) cout << "VISIBLE "; else cout << "        ";
			cout << w << std::setprecision(4) << data.at(i).visibility;
			cout << " - " << data.at(i).reflectionWalls.size() << " reflections - ";
			cout << "attenuation: " << std::setprecision(4) << data.at(i).reflection << " - ";
			cout << data.at(i).location.x << ", " << data.at(i).location.y << ", " << data.at(i).location.z << "\n";
		}
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
			  // will take up.You should probably use two for each channel that you’re using.Here’s an 
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

	processAnechoic(source1, bufferOutput);
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

void ofApp::processImages(CMonoBuffer<float> &bufferInput, Common::CEarPair<CMonoBuffer<float>> & bufferOutput)
{
	Common::CTransform listenerTransform = listener->GetListenerTransform();
	Common::CVector3 listenerLocation = listenerTransform.GetPosition();
	std::vector<ISM::ImageSourceData> data = ISMHandler.getImageSourceData(listenerLocation);

	if (data.size() != imageSourceDSPList.size()) { cout << "ERROR: DSP list ("<< imageSourceDSPList.size() <<") and source list ("<< data.size()<<") have different sizes \n"; }

	std::vector<CMonoBuffer<float>> bufferAbsortion(data.size(), CMonoBuffer<float>(bufferInput.size(), 0.0));
	ISMHandler.proccess(bufferInput, bufferAbsortion, listenerLocation);

	for (int i = 0; i < imageSourceDSPList.size(); i++)
	{
		if (data.at(i).visible) 
		{
			Common::CEarPair<CMonoBuffer<float>> bufferProcessed;

			imageSourceDSPList.at(i)->SetBuffer(bufferAbsortion.at(i));
			imageSourceDSPList.at(i)->ProcessAnechoic(bufferProcessed.left, bufferProcessed.right);

			bufferOutput.left += bufferProcessed.left;
			bufferOutput.right += bufferProcessed.right;
		}
	}
}


////////////////////////////////////////////////////////////////////////////////////////
//Methods for drawing 
////////////////////////////////////////////////////////////////////////////////////////
void ofApp::drawRoom(ISM::Room room)
{
	std::vector<ISM::Wall> walls = room.getWalls();
	for (int i = 0; i < walls.size(); i++)
	{
		if (walls.at(i).isActive())
		{
			drawWall(walls[i]);
			drawWallNormal(walls[i]);
		}
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
	Common::CVector3 newLocation = ISMHandler.getSourceLocation() + movement;
	ISMHandler.setSourceLocation(newLocation);	
	Common::CTransform sourcePosition;
	sourcePosition.SetPosition(newLocation);
	anechoicSourceDSP->SetSourceTransform(sourcePosition);		
}

std::vector<shared_ptr<Binaural::CSingleSourceDSP>> ofApp::createImageSourceDSP()
{
	std::vector<shared_ptr<Binaural::CSingleSourceDSP>> tempImageSourceDSPList;
	std::vector<Common::CVector3> imageSourceLocationList = ISMHandler.getImageSourceLocations();
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
	ISMHandler.setReflectionOrder(_reflectionOrder);
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
	for (int i = 0; i < activeWalls.size(); i++)
	{
		if (activeWalls.at(i))
		{
			ISMHandler.enableWall(i);
		}
		else
		{
			ISMHandler.disableWall(i);
		}
	}
	mainRoom = ISMHandler.getRoom();
	imageSourceDSPList = createImageSourceDSP();
	systemSoundStream.start();
}
