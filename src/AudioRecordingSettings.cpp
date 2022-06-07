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

#include "AudioRecordingSettings.h"
#include "InterfaceManager.h"
#include "ofxXmlSettings.h"
#include "Config.h"

#define INITIAL_CONFIG_FILE_PATH "./InitialConfig.xml"

#define RECORDED_FILES_FOLDER "./data/Recorded"

#define DEFAULT_RECORDING_BITS_PER_SAMPLE 24

#define DIALOGS_TITLE "3D Tune-In Toolkit Binaural Test Application "

#define WINDOW_CORNER_RADIUS 20

#define TITLE_FONT_SIZE 16
#define NORMAL_FONT_SIZE 10

#define NUM_RECORDING_BITS 2
#define RECORDING_BITS_NUMBERS 16, 24

#define NUM_FRAME_SIZE_BTNS 7  

#define TOOGLE_BTNS_WIDTH  50 
#define TOOGLE_BTNS_HEIGHT 25

#define DEFAULT_BTN_WIDTH  80
#define DEFAULT_BTN_HEIGHT 30

#define EDIT_FONT_SIZE 8

CAudioRecordingSettings ConfRecording;

//--------------------------------------------------------------
CAudioRecordingSettings::CAudioRecordingSettings()
{
	hasJustBeenClosed_LastVisible = false;

	duration_s = 30;
	recordingPercent = 0;
	bitsPerRecordedSample = DEFAULT_RECORDING_BITS_PER_SAMPLE;
}
//--------------------------------------------------------------
void CAudioRecordingSettings::Setup()
{
	visible = false;

	titleFont .load( "verdana.ttf", TITLE_FONT_SIZE  );
	normalFont.load( "verdana.ttf", NORMAL_FONT_SIZE );

	dialog.Setup();

	btnStart.LoadFont();
	btnCancel.LoadFont();
	btnStart.text   = "Start";
	btnCancel.text  = "Cancel";
	btnStart.SetDims( DEFAULT_BTN_WIDTH, DEFAULT_BTN_HEIGHT );
	btnCancel.SetDims( DEFAULT_BTN_WIDTH, DEFAULT_BTN_HEIGHT );
	btnStart.x_offset = 25;
	btnCancel.x_offset = 20;

	btnBrowseFolder.LoadFont();
	btnBrowseFolder.text = "Browse";
	btnBrowseFolder.SetDims(60, DEFAULT_BTN_HEIGHT);
	btnBrowseFolder.x_offset = 8;

	btnSaveInSettings.LoadFont();
	btnSaveInSettings.text = "Save in Settings";
	btnSaveInSettings.SetDims( 115, DEFAULT_BTN_HEIGHT);
	btnSaveInSettings.x_offset = 8;

	if (!textEdFont.isLoaded())
		textEdFont.load("verdana.ttf", EDIT_FONT_SIZE);

	edDuration_s.setup();
	edDuration_s.EditingNumber = true;
	edDuration_s.setFont(textEdFont);
	edDuration_s.enable();
	edDuration_s.bounds.width  = 40;
	edDuration_s.bounds.height = 16;
	edDuration_s.MaxLenght     =  2;	

	edDuration_m.setup();
	edDuration_m.EditingNumber = true;
	edDuration_m.setFont(textEdFont);
	edDuration_m.enable();
	edDuration_m.bounds.width  = 40;
	edDuration_m.bounds.height = 16;
	edDuration_m.MaxLenght     =  2;

	edRecordFolder.setup();
	edRecordFolder.EditingNumber = false;
	edRecordFolder.setFont(textEdFont);
	edRecordFolder.enable();
	edRecordFolder.bounds.width  = 596;
	edRecordFolder.bounds.height =  16;
	edRecordFolder.MaxLenght     =  66;

	edRecordFile.setup();
	edRecordFile.EditingNumber = false;
	edRecordFile.setFont(textEdFont);
	edRecordFile.enable();
	edRecordFile.bounds.width  = 300;
	edRecordFile.bounds.height =  16;
	edRecordFile.MaxLenght     =  42;	

	int recordingBits[] = { RECORDING_BITS_NUMBERS };

	recordingBitNumberBtns.resize(NUM_RECORDING_BITS);

	for (int c = 0; c < recordingBitNumberBtns.size(); c++)
	{
		recordingBitNumberBtns[c].text = Utils.IntToString(recordingBits[c]);

		recordingBitNumberBtns[c].LoadFont();
		recordingBitNumberBtns[c].SetDims(TOOGLE_BTNS_WIDTH, TOOGLE_BTNS_HEIGHT);
		recordingBitNumberBtns[c].x_offset = 16;
	}
	LoadInitialConfig();
}
//--------------------------------------------------------------
bool CAudioRecordingSettings::MousePressed(int x, int y)
{
	     if (btnCancel.ClickedAt(x, y))  Close();
	else if (btnStart .ClickedAt(x, y))
	{ 
		if (GetValuesFromControls())
		{
			SaveInitialConfig();
			visible = false;
			return true;
		}
	}
	else if (btnBrowseFolder.ClickedAt(x, y))
	{
		string res = Utils.OpenDirDialog("Select folder");
		if (res.length() > 0)
			edRecordFolder.text = res;
	}
	else if (btnSaveInSettings.ClickedAt(x, y))
	{
		SaveRecordedFolderInSettings();
	}

	bool handled = false;
	for (int c1 = 0; c1 < recordingBitNumberBtns.size(); c1++)
	{
		handled = recordingBitNumberBtns[c1].ClickedAt(x, y);
		if (handled)
		{
			for (int c2 = 0; c2 < recordingBitNumberBtns.size(); c2++)
				recordingBitNumberBtns[c2].SetSelected(c2 == c1);
			break;
		}
	}

	if (!visible)
	{
		edDuration_s     .endEditing();
		edDuration_m     .endEditing();
		edRecordFolder   .endEditing();
		edRecordFile     .endEditing();
	}
	else
	{
		edDuration_s      .NotifyMousePressed(x, y);
		edDuration_m      .NotifyMousePressed(x, y);
		edRecordFolder    .NotifyMousePressed(x, y);
		edRecordFile      .NotifyMousePressed(x, y);
	}

	if (dialog.GetVisible())
	{
		if (dialog.AcceptedWhenMousePressedAt(x, y)){ }
	}

	return false;
}
//--------------------------------------------------------------
void CAudioRecordingSettings::MouseReleased(int x, int y)
{
	edDuration_s     .NotifyMouseReleased(x, y);
	edDuration_m     .NotifyMouseReleased(x, y);
	edRecordFolder   .NotifyMouseReleased(x, y);
	edRecordFile     .NotifyMouseReleased(x, y);
}
//--------------------------------------------------------------
void CAudioRecordingSettings::Draw()
{
	if (!visible)
		return;

	float parentWindowWidth  = ofGetWidth();
	float parentWindowHeight = ofGetHeight();

	float panelOpac = 140;
	float border = 5;
	float windowWidth = 700;
	float windowHeight = 380;
	float frameWidth = 2;

	bool centerOnListenerPanel = true;
	float x;
	if (centerOnListenerPanel)  x = (parentWindowWidth - IPL_WIDTH - IM.GetRightPanelWidth() - windowWidth) / 2 + IPL_WIDTH;
	else                        x = (parentWindowWidth - windowWidth) / 2;
	float y = (parentWindowHeight - windowHeight) / 2;

	ofPushMatrix();
	ofEnableAlphaBlending();
	ofFill();

	ofSetColor(0, 0, 0, 128);

	ofDrawRectangle(0, 0, parentWindowWidth, parentWindowHeight);

	ofSetColor(255, 255, 255, panelOpac);
	Utils.RoundedRect(x, y, windowWidth, windowHeight, WINDOW_CORNER_RADIUS);	

	ofSetColor(0, 0, 0, panelOpac);
	Utils.RoundedRect(x + frameWidth, y + frameWidth, windowWidth - 2 * frameWidth, windowHeight - 2 * frameWidth, WINDOW_CORNER_RADIUS);

	ofNoFill();
	ofDisableAlphaBlending();

	ofSetColor( 255, 255, 255 );

	const int marginH = 20;
	const int marginV = 20;
	const int stepH   = 10;
	const int stepV   = 30;

	int left  = x + marginH;
	int top   = y + marginV;

	int edLeft = 105;

	top += stepV;

	string s = recordingPercent <= 0 ? "" : " " + Utils.IntToString(recordingPercent) + "%";

	titleFont.drawString( "Offline Recording" + s, left + 30, top);

	top += 40;

	ofSetColor(255, 255, 255);
	normalFont.drawString( "Duration (mm:ss):", left, top );

	Utils.DrawEditor( edDuration_m, left + edLeft + 25, top - 15 );
	Utils.DrawEditor( edDuration_s, left + edLeft + 80, top - 15 );

	top += stepV;

	ofSetColor(255, 255, 255);
	normalFont.drawString("Folder to save recorded files:", left, top);

	top += 10;
	Utils.DrawEditor(edRecordFolder, left, top);

	btnBrowseFolder.SetPos(left + edRecordFolder.bounds.width + 10 + Utils.X, top - 4);
	btnBrowseFolder.Draw();

	// Originally suggested by Arcadio but Lorenzo suggested to save the path always
	// btnSaveInSettings.SetPos(left + edRecordFolder.bounds.width + 80, top - 4);
	// btnSaveInSettings.Draw();

	top += 40;

	ofSetColor(255, 255, 255);
	normalFont.drawString( "File name:", left, top);

	top += 10;

	Utils.DrawEditor(edRecordFile, left, top);

	top += 50;

	ofSetColor(255, 255, 255);
	normalFont.drawString("Resolution:", left, top);
	for (int c = 0; c < recordingBitNumberBtns.size(); c++)
	{
		recordingBitNumberBtns[c].SetPos(left + (TOOGLE_BTNS_WIDTH + stepH) * c, top + 10);
		recordingBitNumberBtns[c].Draw();
	}

	top = y + windowHeight - 50;
	btnStart.SetPos(left + 245, top);
	btnCancel.SetPos(btnStart.x + btnStart.width + stepH, top);

	btnStart.Draw();
	btnCancel.Draw();

	ofPopMatrix();

	if (dialog.GetVisible())
		dialog.Draw(IPL_WIDTH, IM.GetRightPanelWidth());
}
//--------------------------------------------------------------
void CAudioRecordingSettings::Launch()
{
	LoadInitialConfig();

	visible = true;

	recordingPercent = 0;

	UpdateControlsFromValues();
	hasJustBeenClosed_LastVisible = false;
}
//--------------------------------------------------------------
bool CAudioRecordingSettings::GetValuesFromControls()
{
	edDuration_s     .text = Utils.Trim( edDuration_s   .text );
	edDuration_m     .text = Utils.Trim( edDuration_m   .text );
	edRecordFolder   .text = Utils.Trim( edRecordFolder .text );
	edRecordFile     .text = Utils.Trim( edRecordFile   .text );

	duration_s = Utils.StringToInt( edDuration_m.text ) * 60 + Utils.StringToInt( edDuration_s.text );

	if (duration_s <= 0)
	{
		dialog.Launch_OkMessage(DIALOGS_TITLE, "Duration must be greater than 0 seconds");
		return false;
	}

	recordFolder = edRecordFolder.text;
	recordFile   = edRecordFile  .text;

	int recordingBits[] = { RECORDING_BITS_NUMBERS };

	for (int c = 0; c < recordingBitNumberBtns.size(); c++)
		if (recordingBitNumberBtns[c].GetSelected())
			bitsPerRecordedSample = recordingBits[c];

	return true;
}
//--------------------------------------------------------------
void CAudioRecordingSettings::UpdateControlsFromValues()
{
	edDuration_s  .text = Utils.IntToString( duration_s % 60 );
	edDuration_m  .text = Utils.IntToString( duration_s / 60 );
	edRecordFolder.text = recordFolder;

	int recordingBits[] = { RECORDING_BITS_NUMBERS };

	for (int c = 0; c < recordingBitNumberBtns.size(); c++)
		recordingBitNumberBtns[c].SetSelected(recordingBits[c] == bitsPerRecordedSample);
}
//--------------------------------------------------------------
bool CAudioRecordingSettings::HasJustBeenClosed()
{
	bool ret = !visible && hasJustBeenClosed_LastVisible;
	hasJustBeenClosed_LastVisible = visible;

	return ret;
}
//--------------------------------------------------------------
void CAudioRecordingSettings::LoadInitialConfig()
{
	Conf.LoadInitialConfig();

	recordFolder          = Conf.recordFolder;
	bitsPerRecordedSample = Conf.bitsPerRecordedSample;
}
//--------------------------------------------------------------
void CAudioRecordingSettings::SaveInitialConfig()
{
	Conf.bitsPerRecordedSample = bitsPerRecordedSample;
	Conf.recordFolder          = recordFolder;
	Conf.SaveInitialConfig();
}
//--------------------------------------------------------------
void CAudioRecordingSettings::SaveRecordedFolderInSettings()
{
	Conf.recordFolder = Utils.Trim(edRecordFolder.text);
	Conf.SaveInitialConfig();
}




 