/**
* \class CAudioRecordingSettings
*
* \brief This class shows the settings window to record audio ofline
*
* \authors 3DI-DIANA Research Group (University of Malaga), in alphabetical order: M. Cuevas-Rodriguez, C. Garre,  D. Gonzalez-Toledo, E.J. de la Rubia-Cuestas, L. Molina-Tanco ||
* Coordinated by , A. Reyes-Lecuona (University of Malaga) and L.Picinali (Imperial College London) ||
* \b Contact: areyes@uma.es and l.picinali@imperial.ac.uk
*
* \b Contributions: (additional authors/contributors can be added here)
*
* \b Project: 3DTI (3D-games for TUNing and lEarnINg about hearing aids) ||
* \b Website: http://3d-tune-in.eu/
*
* \b Copyright: University of Malaga and Imperial College London - 2017
*
* \b Licence: GPL v3
*
* \b Acknowledgement: This project has received funding from the European Union's Horizon 2020 research and innovation programme under grant agreement No 644051
*/
#ifndef _CONFIG_AUDIO_RECORDING
#define _CONFIG_AUDIO_RECORDING

#include <vector>
#include <memory>
#include "ofMain.h"
#include "Control.h"
#include "Button.h"
#include "MessageDialog.h"

class CAudioRecordingSettings
{
public:                                                   // PUBLIC METHODS 
	CAudioRecordingSettings();

	/// Must be called before using the object
	void Setup();

	/// Shows the settings window
	void Launch();

	/// Draws the settings interface when it is visible
	void Draw();

	/// Returns true when the setting windows is visible
	bool GetVisible() { return visible;  }

	/// Closes the window
	void Close() { visible = false; }

	/// Returns true if the windo has been closed since the last call to this same function.
	bool HasJustBeenClosed();

	// Mouse events that this class must track
	bool MousePressed(int x, int y);  ///< Returns true when btnStart is clicked
	void MouseReleased(int x, int y); ///< Mouse released notification

									  /// Load Config Values From File
	void LoadInitialConfig();
	void SaveInitialConfig();

	void SaveRecordedFolderInSettings();

public:                                                   // PUBLIC ATTRIBUTES

	int duration_s;

	int recordingPercent;

	bool invertListenerPositionX;

	vector<Button> recordingBitNumberBtns;

	string recordFolder;    ///< Folder in which the recorded audio files will be saved
	string recordFile;      ///< File name in which the recorded audio files will be saved

	int bitsPerRecordedSample;    ///< Number of bits per sample can will be used to record audio 

private:                                                   // PRIVATE METHODS 

	/// Assigns the config variables using the current state of the visual controls
	bool GetValuesFromControls();

	/// Updates the content of the controls using the edited_variables
	void UpdateControlsFromValues();

private:                                                   // PRIVATE ATTRIBUTES

	ofTrueTypeFont titleFont;
	ofTrueTypeFont normalFont;
	ofTrueTypeFont textEdFont;

	bool visible;

	Button btnStart;
	Button btnCancel;
	Button btnBrowseFolder;
	Button btnSaveInSettings;

	bool hasJustBeenClosed_LastVisible;

	ofxTextInputField edDuration_s;
	ofxTextInputField edDuration_m;
	ofxTextInputField edRecordFolder;
	ofxTextInputField edRecordFile;

	MessageDialog dialog;
};

/// Shared instance of the CAudioRecordingSettings class
extern CAudioRecordingSettings ConfRecording;


#endif
