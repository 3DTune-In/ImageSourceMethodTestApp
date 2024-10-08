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

#include "WavWriter.h"
#include <fstream>
#include <iostream>

#define _USE_MATH_DEFINES 
#include <math.h>

//////////////////////////////////////

// Default constructor
//template <class T>
//WavWriter<T>::WavWriter()
WavWriter::WavWriter()
{
	nchannels = 2;		// Stereo
	samplerate = 48000;	// 44100 Hz
	bytespersample = 2; // 16 bits	
	datachunkstart = 0;
	SetupSampleRange();
}

//////////////////////////////////////

// Setup of data format
//template <class T>
//void WavWriter<T>::Setup(int _nchannels, int _samplerate, int _bitspersample)
void WavWriter::Setup(int _nchannels, int _samplerate, int _bitspersample)
{
	nchannels = _nchannels;
	samplerate = _samplerate;
	bytespersample = _bitspersample/8;	
	datachunkstart = 0;
	SetupSampleRange();
}

//////////////////////////////////////

// Create new file and start writing WAV header
//template <class T>
//void WavWriter<T>::CreateFile(string filename)
bool WavWriter::CreateWavFile(string filename)
{
	filestream.open(filename, ios_base::out | ios_base::binary);
	filestream.imbue(locale::classic());	

	// Check error
	if (filestream.fail())
		return false;

	// RIFF chunk descriptor
	WriteString("RIFF");	// ChunkID
	WriteNBytes(0, 4);		// ChunkSize (to be filled before closing)
	WriteString("WAVE");	// Format

	// fmt sub-chunk
	WriteString("fmt ");										// Subchunk1ID
	WriteNBytes(16, 4);											// Subchunk1Size (16 for PCM)
	WriteNBytes(1, 2);											// AudioFormat (1 for PCM)
	WriteNBytes(nchannels, 2);									// NumChannels (1 for mono, 2 for stereo...)
	WriteNBytes(samplerate, 4);									// SampleRate 
	WriteNBytes(samplerate * nchannels * bytespersample, 4);	// ByteRate
	WriteNBytes(nchannels * bytespersample, 2);					// BlockAlign
	WriteNBytes(bytespersample*8, 2);							// BitsPerSample

	// Start of data sub-chunk
	datachunkstart = filestream.tellp();	// Store the position on which data chunk starts
	WriteString("data");	// Subchunk2ID
	WriteNBytes(0, 4);		// Subchunk2Size (to be filled before closing)

	return true;
}

//////////////////////////////////////

// Append one buffer to the data chunk 
//template <class T>
//int WavWriter<T>::AppendToFile(CStereoBuffer<T> buffer)
size_t WavWriter::AppendToFile(CStereoBuffer<float> buffer)
{	
	// Check that file with header is already created
	if (!filestream.is_open())
		return -1;

	// Check number of channels in buffer 
	if (buffer.GetNChannels() != nchannels)
		return -1;	

	// Iterate through input buffer 	
	for (int i = 0; i < buffer.size(); i++)
	{
		WriteNBytes(ConvertFloatSample(buffer[i]), bytespersample);
	}

	return buffer.size();	// OK
}

//////////////////////////////////////

// Append one buffer to the data chunk
size_t WavWriter::AppendToFile(Common::CEarPair <CMonoBuffer<float>> bufferPair)
{
	// Check that file with header is already created
	if (!filestream.is_open())
		return -1;

	// Check length of buffers
	if (bufferPair.left.size() != bufferPair.right.size())
		return -1;

	// Iterate through input buffer 	
	for (int i = 0; i < bufferPair.left.size(); i++)
	{
		WriteNBytes(ConvertFloatSample(bufferPair.left[i]), bytespersample);
		WriteNBytes(ConvertFloatSample(bufferPair.right[i]), bytespersample);
	}

	return bufferPair.left.size();	// OK
}

//////////////////////////////////////

// Append one buffer to the data chunk 
size_t WavWriter::AppendToFile(CMonoBuffer<float> buffer)
{
	// Check that file with header is already created
	if (!filestream.is_open())
		return -1;

	// Check number of channels in buffer 
	if (buffer.GetNChannels() != nchannels)
		return -1;

	// Iterate through input buffer 	
	for (int i = 0; i < buffer.size(); i++)
	{
		WriteNBytes(ConvertFloatSample(buffer[i]), bytespersample);
	}

	return buffer.size();	// OK
}

//////////////////////////////////////

// Append one buffer to the data chunk 
size_t WavWriter::AppendToFile(float* buffer, int bufferSize)
{
	// Check that file with header is already created
	if (!filestream.is_open())
		return -1;

	// Iterate through input buffer 	
	for (int i = 0; i < bufferSize; i++)
	{
		WriteNBytes(ConvertFloatSample(buffer[i]), bytespersample);
	}

	return bufferSize;	// OK
}

//////////////////////////////////////

// Finish writing WAV header and close file
//template <class T>
//int WavWriter<T>::CloseFile()
size_t WavWriter::CloseFile()
{	
	// Check that WAV file was previously created
	if (!filestream.is_open() || (datachunkstart == 0))
		return -1;

	// Get total file size
	size_t filesize = filestream.tellp();	
	
	// Fill ChunkSize header
	filestream.seekp(0 + 4);
	WriteNBytes(filesize - 8, 4);
	
	// Fill Subchunk2Size header 
	filestream.seekp(datachunkstart + 4);		
	WriteNBytes(filesize - datachunkstart + 8, 4);

	// Close file
	filestream.flush();
	filestream.close();

	return filesize; // OK
}

//////////////////////////////////////

// Check if WAV file is already open for writing
bool WavWriter::IsWriting()
{
	return (filestream.is_open());
}

//////////////////////////////////////
// PRIVATE METHODS:
//////////////////////////////////////

// Write int value as little-endian
void WavWriter::WriteNBytes(TWavSampleType value, int nbytes)
{		
	for (int i = 0; i < nbytes * 8; i += 8)
	{
		filestream.put(value >> i);
	}
}

//////////////////////////////////////

// Write string
void WavWriter::WriteString(string value)
{
	filestream << value;
	//filestream.write(value, 4);
}

//////////////////////////////////////

int WavWriter::ConvertFloatSample(float sample)
{
	return lround(sample * maxsamplevalue) & samplemask;
}

//////////////////////////////////////

void WavWriter::SetupSampleRange()
{	
	maxsamplevalue = 1 << ((bytespersample * 8) - 1);
	samplemask = (1 << (bytespersample * 8)) - 1;
}

//////////////////////////////////////

//template class WavWriter<float>;
