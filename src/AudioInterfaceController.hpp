
#ifndef _AUDIOINTERFACE_CONTROLLER_HPP_
#define _AUDIOINTERFACE_CONTROLLER_HPP_

#include "ofMain.h"
//#include "GlobalDefinitionsBeRTA.hpp"
//#include "OutputChannelsController.hpp"

class CAudioInterfaceController {
	//using TGUIMessageType = GlobalDefinitionsBeRTA::TGUIMessageType;

public:

	struct TAudioInterfaceSelected {
		std::string API;
		int ID;		
		std::string name;
		int channels;

		TAudioInterfaceSelected() : ID{ -1 }, API{  ofSoundDevice::Api::UNSPECIFIED }, name{ "" }, channels{ 0 } { }
		TAudioInterfaceSelected(std::string _api, int _id, std::string _name, int _channels) : ID{ _id }, API{ _api }, name{ _name }, channels{ _channels } { }
		TAudioInterfaceSelected(ofSoundDevice device, int _channels) : ID{ device.deviceID }, API{ GetSoundDeviceAPIString(device.api) }, name{ device.name }, channels{ _channels } { }
		
		// Override operator ==
		bool operator==(const TAudioInterfaceSelected& other) const {
			return (API == other.API && ID == other.ID && channels == other.channels);
		}
	
	};

	struct TAudioInterface {
		int ID;
		std::string API;
		std::string name;
		int inputChannels;
		int outputChannels;

		TAudioInterface(): ID { -1 }, API { ofSoundDevice::Api::UNSPECIFIED}, name { "" }, inputChannels { 0 }, outputChannels { 0 } { }
		
		TAudioInterface(int _id, std::string _api, std::string _name, int _outputChannels, int _inputChannels)
			: ID { _id }, API{ _api }, name { _name }, inputChannels { _inputChannels }, outputChannels { _outputChannels } { }
	};

	CAudioInterfaceController(std::function<void(std::string)> _callBackGUIMessage)
		: app{ nullptr }, setupDone{ false }, audioInterfaceSelected { false }, ofAudioStarted{ false }, sampleRate{ -1 }, bufferSize{ -1 }, bufferFrames{ 4 } {
		
		callBackGUIMessage = _callBackGUIMessage;
		soundStream.close();				
	}
			
	/**
	 * @brief Configure this class
	 * @param app Point to ofApp
	 * @param _sampleRate Sample rate
	 * @param _bufferSize Buffer size
	*/	
	void Setup(ofBaseApp* _app, int _sampleRate, int _bufferSize, int _bufferFrames) {
		app = _app;
		sampleRate = _sampleRate;
		bufferSize = _bufferSize;	
		bufferFrames = _bufferFrames;
				
		setupDone = true;					
		
		
		std::vector<ofSoundDevice> audioDeviceList = GetAllAudioDevices();	// Get all available Audio Device	
		ShowListAvailableAudioInterface(audioDeviceList);					// Show list of available audio interfaces		
		bool deviceSelected = SetDefaultAudioDevice(audioDeviceList);		// Select default audio interface

		// Check if audio interface selected
		if (deviceSelected) { 
			callBackGUIMessage("Audio Default Interface selected:  " + selectedOutputAudioInterface.name);
		} else {							
			callBackGUIMessage("ERROR: No Audio Interface selected.");	
		}				
	}

	
	bool StartAudioInterface() {
		if (!audioInterfaceSelected) { return false; }
		if (ofAudioStarted) return false;
		ofAudioStarted = true;
		soundStream.start();		
		return true;
	}

	bool StopAudioInterface() {			
		if (!audioInterfaceSelected) { return false; }
		if (!ofAudioStarted) return false;		
		ofAudioStarted = false;
		soundStream.stop();		
		return true;
	}

	void CloseAudioInterface() {
		if (!audioInterfaceSelected) { return; }
		ofAudioStarted = false;
		soundStream.close();
	}

	bool isAudioInterfaceStarted() {
		return ofAudioStarted;
	}
	
	bool IsAudioInterfaceSelected() {
		return audioInterfaceSelected;
	}

	
	/**
	 * @brief Sets the audio interfaces to be used.
	 * @param _outDevice 
	 * @param _inDevice 
	 * @return 
	 */
	bool SetupAudioDevices(TAudioInterfaceSelected _outDevice, TAudioInterfaceSelected _inDevice, bool bufferFramesChanged = false) {

		if (!setupDone) {	return false;	}
		bool running = isAudioInterfaceStarted();

		if (!bufferFramesChanged) 
		{
			if (selectedInputAudioInterface == _inDevice && selectedOutputAudioInterface == _outDevice) {
				return false;
			}
		}

		if (_outDevice.API == "" || _outDevice.ID == -1) {	return false;	}

		ofSoundDevice::Api _outDeviceAPI = GetDeviceAPI(_outDevice.API);
		ofSoundDevice outDevice = FindDevice(_outDevice.API, _outDevice.ID);

		bool result = false;
		
		if (_inDevice.API == "" || _inDevice.ID == -1) {
			// Only output device
			if (outDevice.outputChannels >= _outDevice.channels) {
				result = ConfigureBothDevices(GetDeviceAPI(_outDevice.API), outDevice, _outDevice.channels, ofSoundDevice(), 0);
			}			
		} else {
			ofSoundDevice inDevice = FindDevice(_inDevice.API, _inDevice.ID);
			if (outDevice.outputChannels >= _outDevice.channels && inDevice.inputChannels >= _inDevice.channels) {
				result = ConfigureBothDevices(_outDeviceAPI, outDevice, _outDevice.channels, inDevice, _inDevice.channels);				
			}
		}
		
		if (result) {
			ofAudioStarted = false;
			soundStream.stop();
			audioInterfaceSelected = true;			
			callBackGUIMessage("Output Audio Interface selected: " + selectedOutputAudioInterface.name + " with " + to_string(selectedOutputAudioInterface.channels) + " OUT channels.");		
			if (selectedInputAudioInterface.name != "") {
				callBackGUIMessage("Input Audio Interface selected: " + selectedInputAudioInterface.name + " with " + to_string(selectedInputAudioInterface.channels) + " IN channels.");
			}
			//outputChannelsController.SetupStereoChannels(callBackGUIMessage, sampleRate, bufferSize, outDevice.outputChannels);
		}
		
		if (running) {
			StartAudioInterface();
		}
		return result;		
	}

	/**
	 * @brief Returns the list of available audio devices. 
	 * @return list of available output audio devices
	*/
	//std::vector<TAudioInterface> GetAllAudioDeviceList() {
	//	
	//	std::vector<ofSoundDevice> audioDeviceList = GetAllAudioDevices();
	//	
	//	//Make list
	//	std::vector<TAudioInterface> returnList;		
	//	for (auto device : audioDeviceList) {
	//		TAudioInterface oneDevice(device.deviceID, GetSoundDeviceAPIString(device.api), device.name, device.outputChannels, device.inputChannels);
	//		returnList.push_back(oneDevice);
	//	}
	//	return returnList;
	//}


	/**
	 * @brief Returns the list of available output audio devices. 
	 * @return list of available output audio devices
	*/
	std::vector<TAudioInterface> GetOutputAudioDeviceList() {		
		std::vector<TAudioInterface> returnList;		
		std::vector<ofSoundDevice> audioDeviceList = GetAllAudioDevices();

		//Make list
		for (auto device : audioDeviceList) {
			if (device.outputChannels != 0) {
				TAudioInterface oneDevice(device.deviceID, GetSoundDeviceAPIString(device.api), device.name, device.outputChannels, device.inputChannels);
				returnList.push_back(oneDevice);
			}
		}
		return returnList;
	}

	/**
	 * @brief Returns the list of available input audio devices. 
	 * @return list of available output audio devices
	*/
	std::vector<TAudioInterface> GetInputAudioDeviceList() {
		std::vector<TAudioInterface> returnList;
		std::vector<ofSoundDevice> audioDeviceList = GetAllAudioDevices();

		//Make list
		for (auto device : audioDeviceList) {
			if (device.inputChannels != 0) {
				TAudioInterface oneDevice(device.deviceID, GetSoundDeviceAPIString(device.api), device.name, device.outputChannels, device.inputChannels);
				returnList.push_back(oneDevice);
			}
		}
		return returnList;
	}
	
	/**
	 * @brief Get selected device
	 * @return 
	*/
	TAudioInterfaceSelected GetSelectedOutputAudioDevice() {
		
		return selectedOutputAudioInterface;
	}

	TAudioInterfaceSelected GetSelectedInputAudioDevice() {
		return selectedInputAudioInterface;
	}

	/**
	 * @brief Get SystemSoundStream Interface Buffer Size
	 * @return int buffer size
	 */
	int GetInterfaceBufferSize()
	{
		return soundStream.getBufferSize();
	}

	/**
	 * @brief Get SystemSoundStream Interface Sample Rate
	 * @return int sample rate
	 */
	int GetInterfaceSampleRate()
	{
		return soundStream.getSampleRate();
	}

	/**
	 * @brief 
	 */
	void SetBufferFrames(int _bufferFrames) 
	{
		if (_bufferFrames == bufferFrames) { return; } 
		bufferFrames = _bufferFrames;
		callBackGUIMessage("Buffer Frames set to: " + to_string(bufferFrames));
		//SetupAudioDevices(selectedOutputAudioInterface, selectedInputAudioInterface, true);
	}
	
	void ShowListAvailableAudioInterface() {
		std::vector<ofSoundDevice> audioDeviceList = GetAllAudioDevices();	// Get all available Audio Device	
		ShowListAvailableAudioInterface(audioDeviceList);					// Show list of available audio interfaces
	}

	////////////////////////////////////////////////
	////////// CHANNELS
	////////////////////////////////////////////////

	/*void ProcessChannel(GlobalDefinitionsBeRTA::COutputChannelSamples & _data, int _channel) {
		outputChannelsController.ProcessChannel(_data, _channel);
	}

	void ResetAllChannelsSignalLevels() {
		outputChannelsController.ResetSafetyLimiters();
		outputChannelsController.ResetEnvelopeDetectors();		
	}*/
	
	//////////////////////////////////////
	/////////////// CHANNELS CALIBRATION
	//////////////////////////////////////
	//bool IsChannelCalibrated(int _channelNumer) {
	//	return outputChannelsController.IsChannelCalibrated(_channelNumer);
	//}
	//
	//bool IsChannelInCalibrationProcess(int _channelNumer) {
	//	return outputChannelsController.IsChannelInCalibrationProcess(_channelNumer);
	//}

	//bool IsAnyChannelInCalibrationProcess() {
	//	return outputChannelsController.IsAnyChannelInCalibrationProcess();
	//}

	//bool PlayChannelCalibration(float _dBFS, int _channelNumber) {
	//	return outputChannelsController.PlayChannelCalibration(_dBFS, _channelNumber);
	//}
	//
	//void StopChannelCalibrationProcess(int _channelNumer) {
	//	outputChannelsController.StopChannelCalibrationProcess(_channelNumer);
	//}

	//void StopAllChannelsCalibrationProcess() {
	//	outputChannelsController.StopAllChannelsCalibrationProcess();
	//}
	////---

	//bool PlayChannelCalibrationTest(float _dBSPL, int _channelNumber) {
	//	return outputChannelsController.PlayChannelCalibrationTest(_dBSPL, _channelNumber);
	//}

	//void StopChannelCalibrationTest(int _channelNumer) {
	//	outputChannelsController.StopChannelCalibrationTest(_channelNumer);
	//}
	//
	//void SetChannelCalibration(float _dBFS, float _dBSPL, int _channelNumber) {
	//	outputChannelsController.SetChannelCalibration(_dBFS, _dBSPL, _channelNumber);
	//}

	//void GetChannelCalibrationRelation(int _channelNumber, float & _dBFS, float & _dBSPL) {
	//	outputChannelsController.GetChannelCalibrationRelation(_channelNumber, _dBFS, _dBSPL);
	//}

	//////////////////////////////////////
	/////////////// CHANNELS SAFETY LIMITER
	//////////////////////////////////////
	/*void SetChannelSoundLevelLimit(float _dBSPL, int _channelNumber) {
		outputChannelsController.SetChannelSoundLevelLimit(_dBSPL, _channelNumber);
	}
	
	bool IsChannelLimiting(int _channelNumber) {
		return outputChannelsController.IsChannelLimiting(_channelNumber);
	}

	bool IsAnyChannelLimiting(int & _channelNumber) {
		return outputChannelsController.IsAnyChannelLimiting(_channelNumber);
	}
	float GetChannelSafetyLimiterLastFrameLeftdBSPL(int _channelNumber) {
		return outputChannelsController.GetChannelSafetyLimiterLastFrameLeftdBSPL(_channelNumber);
	}
	float GetChannelSafetyLimiterLastFrameRightdBSPL(int _channelNumber) {
		return outputChannelsController.GetChannelSafetyLimiterLastFrameRightdBSPL(_channelNumber);
	}
	float GetChannelSafetyLimiterLastFrameUnlimitedLeftdBSPL(int _channelNumber) {
		return outputChannelsController.GetChannelSafetyLimiterLastFrameUnlimitedLeftdBSPL(_channelNumber);
	}
	float GetChannelSafetyLimiterLastFrameUnlimitedRightdBSPL(int _channelNumber) {
		return outputChannelsController.GetChannelSafetyLimiterLastFrameUnlimitedRightdBSPL(_channelNumber);
	}*/
	
	//////////////////////////////////////
	/////////////// CHANNELS ENVELOPE DETECTOR
	//////////////////////////////////////
	/*float GetChannelEnvelopeLeftdBSPL(int _channelNumber) {
		return outputChannelsController.GetChannelEnvelopeDetectorLeftdBFS(_channelNumber);
	}
	float GetChannelEnvelopeRightdBSPL(int _channelNumber) {
		return outputChannelsController.GetChannelEnvelopeDetectorRightdBFS(_channelNumber);
	}*/

	

private:
	

	/**
	 * @brief Sets the default SO audio interface as the one to be used.   
	*/
	bool SetDefaultAudioDevice(const std::vector<ofSoundDevice>& audioDeviceList) {
		
		if (!setupDone) { return false;	}
		
		bool control = false;		
		//std::vector<ofSoundDevice> audioDeviceList = GetAllAudioDevices();
		for (auto audioDevice : audioDeviceList) {
			if (audioDevice.isDefaultOutput && audioDevice.outputChannels >= 2) {
				

				TAudioInterfaceSelected _outDevice = TAudioInterfaceSelected(GetSoundDeviceAPIString(audioDevice.api), audioDevice.deviceID, audioDevice.name, 2);
				control = SetupAudioDevices(_outDevice, TAudioInterfaceSelected());				
				break;
			}
		}
		return control;		
	}
	

	/**
	 * @brief Returns the list of all available audio devices
	 * @return  list of available audio devices
	*/
	std::vector<ofSoundDevice> GetAllAudioDevices() {		
		
	#ifdef _WIN32
		//auto asioDeviceList = soundStream.getDeviceList(ofSoundDevice::Api::MS_ASIO);
		//auto wasapiDeviceList = soundStream.getDeviceList(ofSoundDevice::Api::MS_WASAPI);
		std::vector<ofSoundDevice> asioDeviceList = GetSpecificDeviceList(ofSoundDevice::Api::MS_ASIO);
		std::vector<ofSoundDevice> wasapiDeviceList = GetSpecificDeviceList(ofSoundDevice::Api::MS_WASAPI);
	#elif defined(__APPLE__)
		//auto osxDeviceList = soundStream.getDeviceList(ofSoundDevice::Api::OSX_CORE);		
		std::vector<ofSoundDevice> osxDeviceList = GetSpecificDeviceList(ofSoundDevice::Api::OSX_CORE);
	#endif
		// Shortcut. When an ASIO device is selected the list returns empty, I don't know why.
		if (asioDeviceList.size() ==0 && selectedOutputAudioInterface.API == "MS_ASIO") { 
			asioDeviceList = asioBackupDeviceList; 
		}
		else {	asioBackupDeviceList = asioDeviceList;	}

		// Create the final list
		std::vector<ofSoundDevice> deviceList;
	#ifdef _WIN32
		deviceList.insert(deviceList.end(), asioDeviceList.begin(), asioDeviceList.end());
		deviceList.insert(deviceList.end(), wasapiDeviceList.begin(), wasapiDeviceList.end());
	#elif defined(__APPLE__)
		deviceList = osxDeviceList;		
	#endif
		return deviceList;
	}

	/**
	 * @brief Returns the list of all available audio devices
	 * @return  list of available audio devices
	*/
	std::vector<ofSoundDevice> GetSpecificDeviceList(ofSoundDevice::Api _api) {
		std::vector<ofSoundDevice> deviceList = soundStream.getDeviceList(_api);
		return deviceList;
	}	

	/**
	 * @brief Setup audio devices into rtaudio configuration throught ofSoundStream
	 * @param _api 
	 * @param outDevice 
	 * @param inDevice 
	 *  numBuffers-> Is the number of buffers that your system will create and swap out.The more buffers,
	 *	the faster your computer will write information into the buffer, but the more memory it
	 *	will take up.You should probably use two for each channel that you�re using.Here�s an
	 *	example call : ofSoundStreamSetup(2, 0, 44100, 256, 4);
	 *	http://openframeworks.cc/documentation/sound/ofSoundStream/
	 * @return 
	 */
	bool ConfigureBothDevices(const ofSoundDevice::Api& _api, const ofSoundDevice & outDevice, int _outChannels, const ofSoundDevice & inDevice, int _inChannels) {
		ofSoundStreamSettings _settings;
		
		_settings.sampleRate = sampleRate;		
		_settings.bufferSize = bufferSize;
		_settings.numBuffers = bufferFrames;
		_settings.setOutListener(app);
		_settings.setInListener(app);
		
		//Set Api
		bool result = _settings.setApi(_api);								
		//Input device
		if (inDevice.deviceID != -1 && inDevice.api == _api) {
			_settings.numInputChannels = _inChannels;
			result = result && _settings.setInDevice(inDevice);		
			selectedInputAudioInterface = TAudioInterfaceSelected(inDevice, _inChannels);

		} else {
			_settings.numInputChannels = 0;
			selectedInputAudioInterface = TAudioInterfaceSelected();			
			if (inDevice.deviceID != -1) {
				callBackGUIMessage("Error: Audio input interface not selected, indicated API is different from the output interface." + selectedInputAudioInterface.name);
			}			
		}
		// Output device	
		if (outDevice.deviceID != -1 && outDevice.api == _api) {
			_settings.numOutputChannels = _outChannels;
			result = result && _settings.setOutDevice(outDevice);
			selectedOutputAudioInterface = TAudioInterfaceSelected(outDevice, _outChannels);
		} else {
			_settings.numOutputChannels = 0;
			selectedOutputAudioInterface = TAudioInterfaceSelected();
		}
		
		//Check if everything is ok
		if (!result) {	
			selectedInputAudioInterface = TAudioInterfaceSelected();
			selectedOutputAudioInterface = TAudioInterfaceSelected();
			return false; 
		}
		
		//Set configuration
		result = soundStream.setup(_settings);
		if (result) {						
			return true;
		} else {
			selectedInputAudioInterface = TAudioInterfaceSelected();
			selectedOutputAudioInterface = TAudioInterfaceSelected();
			return false;
		}							
	}

	/**
	 * @brief 
	 * @param API 
	 * @param ID 
	 * @return 
	 */
	ofSoundDevice FindDevice(std::string API, int ID) {
		ofSoundDevice::Api _api = GetDeviceAPI(API);		
		std::vector<ofSoundDevice> audioDeviceList = GetSpecificDeviceList(_api);

		// Work around for ASIO devices
		if (_api == ofSoundDevice::Api::MS_ASIO && audioDeviceList.size() == 0) {			
			audioDeviceList = asioBackupDeviceList;						
		}

		auto it = find_if(audioDeviceList.begin(), audioDeviceList.end(), [&_api, &ID](ofSoundDevice & item) { return (item.deviceID == ID && item.api == _api); });

		if (it == audioDeviceList.end()) {
			return ofSoundDevice();
		}

		return *it;
	}


	/**
	 * @brief Show in console the list of available audio Interfaces
	 */
	void ShowListAvailableAudioInterface(const std::vector<ofSoundDevice> & audioDeviceList) {
		
		//std::vector<ofSoundDevice> audioDeviceList = GetAllAudioDevices();		
		int longestName = FindLongestDeviceName(audioDeviceList);

		std::cout << std::endl;
		std::cout << "---------------------------------------------------------------------------------------------" << std::endl;
		std::cout << "                          List of available audio interfaces" << std::endl;
		std::cout << "---------------------------------------------------------------------------------------------" << std::endl;
		std::cout << "ID" << std::setw(3) <<' '<< "Name" << std::setw(longestName - 3) << ' ' << "OutputChannels" << std::setw(1) << ' ' << "InputChannels" << std::setw(1) << ' ' << "API" << std::endl;
		for (int i = 0; i < audioDeviceList.size(); i++) {
			cout << " " 				
				<< audioDeviceList[i].deviceID			<< std::setw(3) << ' '
				<< audioDeviceList[i].name 				<< std::setw(longestName - audioDeviceList[i].name.length() + 1) << ' '
				<< audioDeviceList[i].outputChannels	<< std::setw(13) << ' '
				<< audioDeviceList[i].inputChannels		<< std::setw(13) << ' '
				<< GetSoundDeviceAPIString(audioDeviceList[i].api) << std::setw(3) << ' '
				<< (audioDeviceList[i].isDefaultOutput ? "DefaultOutput " : "")
				<< std::endl;
		}
		std::cout << "---------------------------------------------------------------------------------------------" << std::endl;
		std::cout << std::endl;
	}
		
	static std::string GetSoundDeviceAPIString(ofSoundDevice::Api _api) {
		string type = "";		
			//	ALSA,     /*!< The Advanced Linux Sound Architecture API. */
			//	PULSE,    /*!< The Linux PulseAudio API. */
			//	OSS,      /*!< The Linux Open Sound System API. */
			//	JACK,      /*!< The Jack Low-Latency Audio Server API. */
			//	OSX_CORE,    /*!< Macintosh OS-X Core Audio API. */
			//	MS_WASAPI, /*!< The Microsoft WASAPI API. */
			//	MS_ASIO,   /*!< The Steinberg Audio Stream I/O API. */
			//	MS_DS,     /*!< The Microsoft Direct Sound API. */
		switch (_api) {
			case ofSoundDevice::Api::DEFAULT:	type = "Default";
				break;
			case ofSoundDevice::Api::ALSA:		type = "ALSA";
				break;
			case ofSoundDevice::Api::PULSE:		type = "PULSE";
				break;
			case ofSoundDevice::Api::OSS:		type = "OSS";
				break;
			case ofSoundDevice::Api::JACK:		type = "JACK";
				break;
			case ofSoundDevice::Api::OSX_CORE:	type = "OSX_CORE";
				break;
			case ofSoundDevice::Api::MS_WASAPI:	type = "MS_WASAPI";
				break;
			case ofSoundDevice::Api::MS_ASIO:	type = "MS_ASIO";
				break;			
			case ofSoundDevice::Api::MS_DS:		type = "MS_DS";
				break;
			case ofSoundDevice::Api::UNSPECIFIED: type = "UNSPECIFIED";
				break;
			default: type = "API_UNKNOWN";
				break;
			}		
		return type;
	}


	ofSoundDevice::Api GetDeviceAPI(std::string _api) {
		ofSoundDevice::Api api = ofSoundDevice::Api::UNSPECIFIED;
		if (_api == "ALSA") {
			api = ofSoundDevice::Api::ALSA;
		}
		else if (_api == "PULSE") {
			api = ofSoundDevice::Api::PULSE;
		}
		else if (_api == "OSS") {
			api = ofSoundDevice::Api::OSS;
		}
		else if (_api == "JACK") {
			api = ofSoundDevice::Api::JACK;
		}
		else if (_api == "OSX_CORE") {
			api = ofSoundDevice::Api::OSX_CORE;
		}
		else if (_api == "MS_WASAPI") {
			api = ofSoundDevice::Api::MS_WASAPI;
		}
		else if (_api == "MS_ASIO") {
			api = ofSoundDevice::Api::MS_ASIO;
		}
		else if (_api == "MS_DS") {
			api = ofSoundDevice::Api::MS_DS;
		}
		return api;
	}

	int FindLongestDeviceName(const std::vector<ofSoundDevice>& list)
	{
		int longest = 0;
		for (int i = 0; i < list.size(); i++)
		{
			if (list[i].name.length() > longest)
				longest = list[i].name.length();
		}
		return longest;
	}
			
	// Attributes	
	ofBaseApp* app;
	int sampleRate;
	int bufferSize;
	int bufferFrames;
	bool setupDone;
	bool ofAudioStarted;
	bool audioInterfaceSelected;
	
	std::function<void(std::string)> callBackGUIMessage;

	ofSoundStream soundStream;	

	TAudioInterfaceSelected selectedOutputAudioInterface;
	TAudioInterfaceSelected selectedInputAudioInterface;	
	std::vector<ofSoundDevice> asioBackupDeviceList;

	//COutputChannelsController outputChannelsController;
};
#endif