#include "ofApp.h"

#define SAMPLERATE 44100
#define BUFFERSIZE 512

#define SOURCE_STEP 0.02f
#define LISTENER_STEP 0.02f

//--------------------------------------------------------------
void ofApp::setup(){
	
	// Room setup

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
	floor.insertCorner(-1, 2, 0); 
	//floor.insertCorner(-1, -3, 1);  	// error coord. Z

	mainRoom.insertWall(floor);

	ceiling.insertCorner(1, 2, 2); 
	ceiling.insertCorner(1, -2, 2);
	ceiling.insertCorner(-1, -3, 2);
	ceiling.insertCorner(-1, 2, 2);

	mainRoom.insertWall(ceiling);


	// Core setup
	Common::TAudioStateStruct audioState;	    // Audio State struct declaration
	audioState.bufferSize = BUFFERSIZE;			// Setting buffer size 
	audioState.sampleRate = SAMPLERATE;			// Setting frame rate 
	myCore.SetAudioState(audioState);		    // Applying configuration to core
	myCore.SetHRTFResamplingStep(15);		    // Setting 15-degree resampling step for HRTF


	// Listener setup
	listener = myCore.CreateListener();								 // First step is creating listener
	Common::CTransform listenerPosition = Common::CTransform();		 // Setting listener in (0,0,0)
	listenerPosition.SetPosition(Common::CVector3(-0.5, 0, 1));
	listener->SetListenerTransform(listenerPosition);
	listener->DisableCustomizedITD();								 // Disabling custom head radius
	// HRTF can be loaded in SOFA (more info in https://sofacoustics.org/) Some examples of HRTF files can be found in 3dti_AudioToolkit/resources/HRTF
	bool specifiedDelays;
	bool sofaLoadResult = HRTF::CreateFromSofa("hrtf.sofa", listener, specifiedDelays);			
	if (!sofaLoadResult) { 
		cout << "ERROR: Error trying to load the SOFA file" << endl<<endl;
	}																			

	// Source  setup
	sourceImages.setup(myCore, Common::CVector3(0.5, -1, 1));
	sourceImages.createImages(mainRoom);
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
	float scale = 100;
	ofScale(scale);
	ofScale(1, -1, 1);
	ofTranslate(ofGetWidth() / (scale * 2), -ofGetHeight() / (scale * 2), 0);
	ofRotateZ(90);
	ofRotateY(elevation);
	ofRotateZ(azimuth);
		
	mainRoom.draw();
	//draw lisener
	Common::CTransform lisenerTransform = listener->GetListenerTransform();
	Common::CVector3 lisenerPosition = lisenerTransform.GetPosition();
	ofSphere(lisenerPosition.x, lisenerPosition.y, lisenerPosition.z, 0.09);

	ofPushStyle();
	ofSetColor(255, 50, 200);
	sourceImages.drawSource();
	ofSetColor(255, 150, 200);
	sourceImages.drawImages();
	ofPopStyle();
	sourceImages.drawRaysToListener(lisenerPosition);


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
	case 'k': //Moves the source left (-X)
		sourceImages.setLocation(sourceImages.getLocation() + Common::CVector3(-SOURCE_STEP, 0, 0));
		break;
	case 'i': //Moves the source right (+X)
		sourceImages.setLocation(sourceImages.getLocation() + Common::CVector3(SOURCE_STEP, 0, 0));
		break;
	case 'j': //Moves the source up (+Y)
		sourceImages.setLocation(sourceImages.getLocation() + Common::CVector3(0, SOURCE_STEP, 0));
		break;
	case 'l': //Moves the source down (-Y)
		sourceImages.setLocation(sourceImages.getLocation() + Common::CVector3(0, -SOURCE_STEP, 0));
		break;
	case 'u': //Moves the source up (Z)
		sourceImages.setLocation(sourceImages.getLocation() + Common::CVector3(0, 0, SOURCE_STEP));
		break;
	case 'm': //Moves the source down (-Z)
		sourceImages.setLocation(sourceImages.getLocation() + Common::CVector3(0, 0, -SOURCE_STEP));
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
	k = (k++) % 5;                                         // Changes active image
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
	CMonoBuffer<float> source1(uiBufferSize);
	source1Wav.FillBuffer(source1);

	// Declaration of stereo buffer
	Common::CEarPair<CMonoBuffer<float>> bufferProcessed;

	// Anechoic process of original source
	//source1DSP = sourceImages.getSourceDSP();
	//source1DSP->SetBuffer(source1);
	//source1DSP->ProcessAnechoic(bufferProcessed.left, bufferProcessed.right);

	// Anechoic process of a image Source
	source1DSP = sourceImages.getImageSourceDSPs().at(k);
	source1DSP->SetBuffer(source1);
	source1DSP->ProcessAnechoic(bufferProcessed.left, bufferProcessed.right);

	// Adding anechoic processed first source to the output mix
	bufferOutput.left += bufferProcessed.left;
	bufferOutput.right += bufferProcessed.right;
}



void ofApp::LoadWavFile(SoundSource & source, const char* filePath)
{	
	if (!source.LoadWav(filePath)) {
		cout << "ERROR: file " << filePath << " doesn't exist." << endl<<endl;
	}
}

