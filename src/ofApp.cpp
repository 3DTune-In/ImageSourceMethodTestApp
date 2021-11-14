#include "ofApp.h"

#define SAMPLERATE 44100
#define BUFFERSIZE 512

#define SOURCE_STEP 0.02f
#define LISTENER_STEP 0.01f
#define MAX_REFLECTION_ORDER 4

//--------------------------------------------------------------
void ofApp::setup(){

	// Core setup
	Common::TAudioStateStruct audioState;	    // Audio State struct declaration
	audioState.bufferSize = BUFFERSIZE;			// Setting buffer size 
	audioState.sampleRate = SAMPLERATE;			// Setting frame rate 
	myCore.SetAudioState(audioState);		    // Applying configuration to core
	myCore.SetHRTFResamplingStep(15);		    // Setting 15-degree resampling step for HRTF


	// Listener setup
	listener = myCore.CreateListener();								 // First step is creating listener
	Common::CVector3 listenerLocation(-0.5, 0, 1);
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
/*
	wall_1.insertCorner(1, 2, 0);
	wall_1.insertCorner(1, -2, 0);
	wall_1.insertCorner(1, -2, 2);
	wall_1.insertCorner(1, 2, 2);
	mainRoom.insertWall(wall_1);
	
	wall_2.insertCorner( 1, -2, 0);
	wall_2.insertCorner(-1, -3, 0);
	wall_2.insertCorner(-1, -3, 2);
	wall_2.insertCorner(1, -2, 2);
	mainRoom.insertWall(wall_2);

	wall_3.insertCorner(-1, 2, 0);
	wall_3.insertCorner(1, 2, 0);
	wall_3.insertCorner(1, 2, 2);
	wall_3.insertCorner(-1, 2, 2);
	mainRoom.insertWall(wall_3);

	wall_4.insertCorner(-1, -3, 0);
	wall_4.insertCorner(-1, 2, 0);
	wall_4.insertCorner(-1, 2, 2);
	wall_4.insertCorner(-1, -3, 2);
	mainRoom.insertWall(wall_4);

	floor.insertCorner(1, -2, 0);
	floor.insertCorner(1, 2, 0);
	floor.insertCorner(-1, 2, 0);
	//floor.insertCorner(-1, -3, 0); 
	floor.insertCorner(-1, -3, 1);      // error coord. Z	

	mainRoom.insertWall(floor);

	ceiling.insertCorner(1, 2, 2); 
	ceiling.insertCorner(1, -2, 2);
	ceiling.insertCorner(-1, -3, 2);
	ceiling.insertCorner(-1, 2, 2);

	mainRoom.insertWall(ceiling);
*/

	mainRoom.setupShoebox(7, 10, 3); //old way
	mainRoom.disableWall(4);         //
	mainRoom.disableWall(5);         //

	ISMHandler.SetupShoeBoxRoom(7, 10, 3, myCore); //new way (el core debe desaparecer)
	ISMHandler.setReflectionOrder(2);
	ISMHandler.disableWall(4);
	ISMHandler.disableWall(5);


	// Source  setup
	sourceImages.setup(myCore, Common::CVector3(-0.5, -1, 1));						//Old way
	sourceImages.createImages(mainRoom,listenerLocation, MAX_REFLECTION_ORDER);		//

	Common::CVector3 initialLocation(-0.5, -1, 1);
	ISMHandler.setSourceLocation(initialLocation);									//New way
	anechoicSourceDSP = myCore.CreateSingleSourceDSP();								// Creating audio source
	Common::CTransform sourcePosition;
	sourcePosition.SetPosition(initialLocation);
	anechoicSourceDSP->SetSourceTransform(sourcePosition);							//Set source position
	anechoicSourceDSP->SetSpatializationMode(Binaural::TSpatializationMode::HighQuality);	// Choosing high quality mode for anechoic processing
	anechoicSourceDSP->DisableNearFieldEffect();											// Audio source will not be close to listener, so we don't need near field effect
	anechoicSourceDSP->EnableAnechoicProcess();											// Enable anechoic processing for this source
	anechoicSourceDSP->EnableDistanceAttenuationAnechoic();								// Do not perform distance simulation
	anechoicSourceDSP->EnablePropagationDelay();
	
	
	LoadWavFile(source1Wav, "speech_female.wav");											// Loading .wav file										   

	//AudioDevice Setup
	//// Before getting the devices list for the second time, the strean must be closed. Otherwise,
	//// the app crashes when systemSoundStream.start(); or stop() are called.
	systemSoundStream.close();
	SetDeviceAndAudio(audioState);

}

//--------------------------------------------------------------
void ofApp::update(){

}

//--------------------------------------------------------------
void ofApp::draw(){
	//////////////////////////////////////begin of 3D drawing//////////////////////////////////////
	ofPushMatrix();
	ofScale(scale);
	ofScale(1, -1, 1);
	ofTranslate(ofGetWidth() / (scale * 2), -ofGetHeight() / (scale * 2), 0);
	ofRotateZ(90);
	ofRotateY(elevation);
	ofRotateZ(azimuth);

	ofSetColor(255, 250);									// deault drawing color is white 
		
	if (reflectionOrder > 0)
	{
		drawRoom(mainRoom);
		if (reflectionOrder > 1)
		{
			std::vector<Room> roomImages = mainRoom.getImageRooms();
			ofPushStyle();
			ofSetColor(255, 50);									//image rooms are drawn semi-transparent
			for (int i = 0; i < roomImages.size(); i++) drawRoom(roomImages.at(i));
			if (reflectionOrder > 2)
			{
				ofSetColor(255, 10);									//second image rooms are drawn almost transparent
				for (int i = 0; i < roomImages.size(); i++)
				{
					std::vector<Room> roomSecondImages = roomImages.at(i).getImageRooms();
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
	Common::CVector3 listenerPosition = listenerTransform.GetPosition();
	ofSphere(listenerPosition.x, listenerPosition.y, listenerPosition.z, 0.09);
	ofLine(sourceImages.getLocation().x, sourceImages.getLocation().y, sourceImages.getLocation().z, listenerPosition.x, listenerPosition.y, listenerPosition.z);

	//draw sources
	ofPushStyle();
	ofSetColor(255, 50, 200,50);
	drawSource(sourceImages);
	ofSetColor(255, 150, 200,50);
	drawImages(sourceImages, reflectionOrder);
	ofPopStyle();
	//sourceImages.drawFirstReflectionRays(listenerPosition);
	drawRaysToListener(sourceImages, listenerPosition, reflectionOrder);

	ofPopMatrix();
	//////////////////////////////////////end of 3D drawing//////////////////////////////////////

	/// print number of visible images
	ofPushStyle();
	ofSetColor(50, 150);
	ofRect(ofGetWidth() - 300, 30, 270, 35);
	ofPopStyle();
	char numberOfImagesStr[255];
	sprintf(numberOfImagesStr, "Number of visible images: %d", sourceImages.getNumberOfVisibleImages(reflectionOrder, listenerPosition));
	ofDrawBitmapString(numberOfImagesStr, ofGetWidth() - 280, 50);


/*
	//Common::CVector3 P(-0.5, 0.5, 0.5);

	Common::CVector3 sourceLocation = sourceImages.getLocation();

	Common::CVector3 P(sourceLocation.x, sourceLocation.y, sourceLocation.z);

	Common::CVector3 R(0, 0, 0), Q(0,0,0);
		
	Q = wall_1.getImagePoint(P);
	ofLine(P.x, P.y, P.z, Q.x, Q.y, Q.z);
	R = wall_1.getIntersectionPointWithLine(Q, lisenerPosition);
	ofLine(Q.x, Q.y, Q.z, R.x, R.y, R.z);
	ofLine(R.x, R.y, R.z, lisenerPosition.x, lisenerPosition.y, lisenerPosition.z);
	//proof R is in wall
	bool proof = FALSE;
	proof = wall_1.checkPointInsideWall(R);
	if (proof) ofBox(R.x, R.y, R.z, 0.03);

	Q = wall_2.getImagePoint(P);
	ofLine(P.x, P.y, P.z, Q.x, Q.y, Q.z);
	R = wall_2.getIntersectionPointWithLine(Q, lisenerPosition);
	ofLine(Q.x, Q.y, Q.z, R.x, R.y, R.z);
	ofLine(R.x, R.y, R.z, lisenerPosition.x, lisenerPosition.y, lisenerPosition.z);
	//proof R is in wall
	proof = FALSE;
	proof = wall_2.checkPointInsideWall(R);
	if (proof) ofBox(R.x, R.y, R.z, 0.03);

	Q = wall_3.getImagePoint(P);
	ofLine(P.x, P.y, P.z, Q.x, Q.y, Q.z);
	R = wall_3.getIntersectionPointWithLine(Q, lisenerPosition);
	ofLine(Q.x, Q.y, Q.z, R.x, R.y, R.z);
	ofLine(R.x, R.y, R.z, lisenerPosition.x, lisenerPosition.y, lisenerPosition.z);
	//proof R is in wall
	proof = FALSE;
	proof = wall_3.checkPointInsideWall(R);
	if (proof) ofBox(R.x, R.y, R.z, 0.03);

	Q = wall_4.getImagePoint(P);
	ofLine(P.x, P.y, P.z, Q.x, Q.y, Q.z);
	R = wall_4.getIntersectionPointWithLine(Q, lisenerPosition);
	ofLine(Q.x, Q.y, Q.z, R.x, R.y, R.z);
	ofLine(R.x, R.y, R.z, lisenerPosition.x, lisenerPosition.y, lisenerPosition.z);
	//proof R is in wall
	proof = FALSE;
	proof = wall_4.checkPointInsideWall(R);
	if (proof) ofBox(R.x, R.y, R.z, 0.03);

*/
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
	case OF_KEY_PAGE_UP:
		scale*=0.9;
		break;
	case OF_KEY_PAGE_DOWN:
		scale*=1.1;
		break;
	case 'k': //Moves the source left (-X)
		sourceImages.setLocation(sourceImages.getLocation() + Common::CVector3(-SOURCE_STEP, 0, 0));			//Old way
		moveSource(Common::CVector3(-SOURCE_STEP, 0, 0));
		break;
	case 'i': //Moves the source right (+X)
		sourceImages.setLocation(sourceImages.getLocation() + Common::CVector3(SOURCE_STEP, 0, 0));				//Old way
		moveSource(Common::CVector3(SOURCE_STEP, 0, 0));
		break;
	case 'j': //Moves the source up (+Y)
		sourceImages.setLocation(sourceImages.getLocation() + Common::CVector3(0, SOURCE_STEP, 0));				//Old way
		moveSource(Common::CVector3(0, SOURCE_STEP, 0));
		break;
	case 'l': //Moves the source down (-Y)
		sourceImages.setLocation(sourceImages.getLocation() + Common::CVector3(0, -SOURCE_STEP, 0));			//Old way
		moveSource(Common::CVector3(0, -SOURCE_STEP, 0));
		break;
	case 'u': //Moves the source up (Z)
		sourceImages.setLocation(sourceImages.getLocation() + Common::CVector3(0, 0, SOURCE_STEP));				//Old way
		moveSource(Common::CVector3(0, 0, SOURCE_STEP));
		break;
	case 'm': //Moves the source down (-Z)
		sourceImages.setLocation(sourceImages.getLocation() + Common::CVector3(0, 0, -SOURCE_STEP));			//Old way
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
		reflectionOrder++;
		if (reflectionOrder > MAX_REFLECTION_ORDER) reflectionOrder = MAX_REFLECTION_ORDER;
		break;
	case '-': //decreases the reflection order 
		reflectionOrder--;
		if (reflectionOrder <0) reflectionOrder = 0;
		break;
	case '1': //enable/disable wall number 1 
		if (mainRoom.getWalls().at(0).isActive())  //Ols way
		{
			mainRoom.disableWall(0);
			systemSoundStream.stop();
			sourceImages.refreshImages(mainRoom, listenerLocation, MAX_REFLECTION_ORDER);			
			systemSoundStream.start();
		}
		else
		{
			mainRoom.enableWall(0);
			systemSoundStream.stop();
			sourceImages.refreshImages(mainRoom, listenerLocation, MAX_REFLECTION_ORDER);
			systemSoundStream.start();

		}
		break;
	case '2': //enable/disable wall number 2 
		if (mainRoom.getWalls().at(1).isActive())
		{
			mainRoom.disableWall(1);
			systemSoundStream.stop();
			sourceImages.refreshImages(mainRoom, listenerLocation, MAX_REFLECTION_ORDER);
			systemSoundStream.start();
		}
		else
		{
			mainRoom.enableWall(1);
			systemSoundStream.stop();
			sourceImages.refreshImages(mainRoom, listenerLocation, MAX_REFLECTION_ORDER);
			systemSoundStream.start();
		}
		break;

	case '3': //enable/disable wall number 2 
		if (mainRoom.getWalls().at(2).isActive())
		{
			mainRoom.disableWall(2);
			systemSoundStream.stop();
			sourceImages.refreshImages(mainRoom, listenerLocation, MAX_REFLECTION_ORDER);
			systemSoundStream.start();
		}
		else
		{
			mainRoom.enableWall(2);
			systemSoundStream.stop();
			sourceImages.refreshImages(mainRoom, listenerLocation, MAX_REFLECTION_ORDER);
			systemSoundStream.start();
		}
		break;
	case '4': //enable/disable wall number 2 
		if (mainRoom.getWalls().at(3).isActive())
		{
			mainRoom.disableWall(3);
			systemSoundStream.stop();
			sourceImages.refreshImages(mainRoom, listenerLocation, MAX_REFLECTION_ORDER);
			systemSoundStream.start();
		}
		else
		{
			mainRoom.enableWall(3);
			systemSoundStream.stop();
			sourceImages.refreshImages(mainRoom, listenerLocation, MAX_REFLECTION_ORDER);
			systemSoundStream.start();
		}
		break;
	case '5': //enable/disable wall number 2 
		if (mainRoom.getWalls().at(4).isActive())
		{
			mainRoom.disableWall(4);
			systemSoundStream.stop();
			sourceImages.refreshImages(mainRoom, listenerLocation, MAX_REFLECTION_ORDER);
			systemSoundStream.start();
		}
		else
		{
			mainRoom.enableWall(4);
			systemSoundStream.stop();
			sourceImages.refreshImages(mainRoom, listenerLocation, MAX_REFLECTION_ORDER);
			systemSoundStream.start();
		}
		break;
	case '6': //enable/disable wall number 2 
		if (mainRoom.getWalls().at(5).isActive())
		{
			mainRoom.disableWall(5);
			systemSoundStream.stop();
			sourceImages.refreshImages(mainRoom, listenerLocation, MAX_REFLECTION_ORDER);
			systemSoundStream.start();
		}
		else
		{
			mainRoom.enableWall(5);
			systemSoundStream.stop();
			sourceImages.refreshImages(mainRoom, listenerLocation, MAX_REFLECTION_ORDER);
			systemSoundStream.start();
		}
		break;
	case 't': //Test
		std::vector<Common::CVector3> location = ISMHandler.getImageSourceLocations();
		cout << "--------------------------------------------------\n";
		for (int i = 0; i < location.size(); i++)
		{
			cout << location.at(i).x << ", " << location.at(i).y << ", " << location.at(i).z << "\n";
 		}
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

/// Read de audio the list of devices of the user computer, allowing the user to select which device to use. Configure the Audio using openFramework
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
	sourceImages.processImages(source1, bufferOutput, lisenerPosition, reflectionOrder);
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


////////////////////////////////////////////////////////////////////////////////////////
//Methods for drawing 
////////////////////////////////////////////////////////////////////////////////////////
void ofApp::drawRoom(Room room)
{
	std::vector<Wall> walls = room.getWalls();
	for (int i = 0; i < walls.size(); i++)
	{
		if (walls.at(i).isActive())
		{
			drawWall(walls[i]);
			drawWallNormal(walls[i]);
		}
	}
}

void ofApp::drawWall(Wall wall)
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

void ofApp::drawWallNormal(Wall wall, float length)
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

void ofApp::drawSource(SourceImages source)
{
	Common::CVector3 sourceLocation = source.getLocation();
	ofBox(sourceLocation.x, sourceLocation.y, sourceLocation.z, 0.2);

}

void ofApp::drawImages(SourceImages source, int reflectionOrder)
{
	std::vector<Common::CVector3> imageLocations;
	source.getImageLocations(imageLocations, reflectionOrder);
	for (int i = 0; i < imageLocations.size(); i++)
	{
		ofBox(imageLocations[i].x, imageLocations[i].y, imageLocations[i].z, 0.2);
	}
}

void ofApp::drawRaysToListener(SourceImages source, Common::CVector3 _listenerLocation, int _reflectionOrder)
{
//	float distanceToBorder;
	std::vector<SourceImages> images = source.getImages();
	if (_reflectionOrder > 0)
	{
		_reflectionOrder--;
		for (int i = 0; i < images.size(); i++)
		{
			Common::CVector3 tempImageLocation = images.at(i).getLocation();
			Common::CVector3 reflectionPoint = images.at(i).getReflectionWall().getIntersectionPointWithLine(tempImageLocation, _listenerLocation);
			float distanceToBorder, sharpness;
			if (images.at(i).getReflectionWall().checkPointInsideWall(reflectionPoint, distanceToBorder, sharpness) > 0)
			{
				//if (fabs(distanceToBorder) > THRESHOLD_BORDER)
				if (sharpness >= 1.0f)
				{
					ofBox(reflectionPoint.x, reflectionPoint.y, reflectionPoint.z, 0.05);
					ofLine(tempImageLocation.x, tempImageLocation.y, tempImageLocation.z, _listenerLocation.x, _listenerLocation.y, _listenerLocation.z);
					drawRaysToListener(images.at(i), _listenerLocation, _reflectionOrder);
				}
				else
				{
					//float sharpness = 0.5 + distanceToBorder / (2.0 * THRESHOLD_BORDER);
					ofPushStyle();
					ofSetColor(0, 0, 255, int(200.0*sharpness));
					ofBox(reflectionPoint.x, reflectionPoint.y, reflectionPoint.z, 0.2);
					ofPopStyle();
				}
			}
		}
	}
}

void ofApp::drawFirstReflectionRays(SourceImages source, Common::CVector3 _listenerLocation)
{
	std::vector<SourceImages> images = source.getImages();
	Common::CVector3 sourceLocation = source.getLocation();
	for (int i = 0; i < images.size(); i++)
	{
		Common::CVector3 reflectionPoint = images.at(i).getReflectionWall().getIntersectionPointWithLine(images[i].getLocation(), _listenerLocation);
		float distanceToBorder, sharpness;
		if (images.at(i).getReflectionWall().checkPointInsideWall(reflectionPoint, distanceToBorder, sharpness) == 1)
		{
			ofBox(reflectionPoint.x, reflectionPoint.y, reflectionPoint.z, 0.05);
			ofLine(sourceLocation.x, sourceLocation.y, sourceLocation.z, reflectionPoint.x, reflectionPoint.y, reflectionPoint.z);
			ofLine(reflectionPoint.x, reflectionPoint.y, reflectionPoint.z, _listenerLocation.x, _listenerLocation.y, _listenerLocation.z);
		}
	}
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
