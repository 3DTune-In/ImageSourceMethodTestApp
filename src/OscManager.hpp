#ifndef _OSC_MANAGER_HPP_
#define _OSC_MANAGER_HPP_

//#include <string>
#include <functional>
#include "ofxOsc.h"

// OSC Command Class
class COscManager {

public:

	COscManager() {}

	void Setup(int _targetPort, std::string _targetIP, int _listenPort, std::function<void(ofxOscMessage)> _callBack) {	
		targetPort = _targetPort;
		targetIP = _targetIP;
		listenPort = _listenPort;
		
		oscSender.setup(targetIP, targetPort);
		oscReceiver.setup(listenPort);

		callBackToofApp = _callBack;											
	}


	void CreateNewConnection(std::string _ip, int _port) {
		//Open
		oscSender.setup(_ip, _port);
	}

	void SendOSCCommand(ofxOscMessage message) {
		oscSender.sendMessage(message);
	}
	

	void SendOSCCommand_ToMatlab() {
		ofxOscMessage message;
		message.setAddress("/ready");
		message.addStringArg("ready");
		oscSender.sendMessage(message);
	}

	void SendOSCCommand_ToMatlab(std::string _address) {
		ofxOscMessage message;
		message.setAddress(_address);
		oscSender.sendMessage(message);
	}

	void SendOSCCommand_ToMatlab_string(std::string _address, std::string _str) {
		ofxOscMessage message;

		message.setAddress(_address);
		message.addStringArg(_str);		
		oscSender.sendMessage(message);
	}

	void SendOSCCommand_ToMatlab_float(std::string _address, float value) {
		ofxOscMessage message;

		message.setAddress(_address);
		message.addDoubleArg(value);
		oscSender.sendMessage(message);
	}

	void SendOSCCommand_ToMatlab_struct(std::string _address, std::string _str, float value) {
		ofxOscMessage message;

		message.setAddress(_address);
		message.addStringArg(_str);
		message.addDoubleArg(value);
		oscSender.sendMessage(message);
	}


	void ReceiveOSCCommand() {
		ofxOscMessage message;		
		while (oscReceiver.hasWaitingMessages())
		{
			oscReceiver.getNextMessage(&message);
			//std::cout << std::endl << "OSC received message: " << message << std::endl;		
			callBackToofApp(message);			
		}

	}


private:

	//Vars
	int targetPort;
	std::string targetIP;
	int listenPort;

	ofxOscSender oscSender;
	ofxOscReceiver oscReceiver;
			
	std::function<void(ofxOscMessage)> callBackToofApp;

			
	template <typename T>
	void CreateCommand(std::string _commandString) {

		std::shared_ptr<T> _command = std::make_shared<T>(_commandString, callBackToofApp);
		commandsList.push_back(_command);
	}
	
	void CallbackOscMessage(ofxOscMessage _command) {
		if (callBackToofApp) { callBackToofApp(_command); }
	}

};




#endif