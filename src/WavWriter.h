/**
* \class WavWriter
*
* \brief Wav writer
*
* Class for writing audio buffers to WAV files
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
#ifndef _WAV_WRITER_H_
#define _WAV_WRITER_H_

#include <string>
#include <fstream>
#include <iostream>
#include "Common/Buffer.h"
#include "Common/CommonDefinitions.h"
using namespace std;

typedef unsigned int TWavSampleType;	// TO DO: check that this is 32 bits in all platforms

//template <class T>
class WavWriter
{
public:

	// Default constructor (for stereo, 16 bits, 44100Hz files)
	WavWriter();	

	// Setup of wave data format
	void Setup(int _nchannels, int _samplerate, int _bitspersample);

	// Create new WAV file
	bool CreateWavFile(string filename);

	// Append buffer to WAV file	
	// TO DO: generic method for CBuffer with any number of channels and with any stored type	
	size_t AppendToFile(CStereoBuffer<float> buffer);
	size_t AppendToFile(CMonoBuffer<float> buffer);
	size_t AppendToFile(Common::CEarPair <CMonoBuffer<float>> bufferPair);

	// Append buffer to WAV file
	size_t AppendToFile(float* buffer, int bufferSize);

	// Close WAV file
	size_t CloseFile();

	// Check if WAV file is already open for writing
	bool IsWriting();

private:
	// Private methods:
	void WriteNBytes(TWavSampleType value, int nbytes);
	void WriteString(string value);
	int32_t ConvertFloatSample(float sample);
	void SetupSampleRange();

	// Attributes:	
	int nchannels;
	int samplerate;
	int bytespersample;
	ofstream filestream;	
	size_t datachunkstart;
	TWavSampleType maxsamplevalue;
	TWavSampleType samplemask;
};

#endif