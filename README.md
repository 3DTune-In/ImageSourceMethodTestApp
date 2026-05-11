# Hybrid ISM+BRIR Simulator

Hybrid ISM+BRIR Simulator is an openFrameworks-based real-time acoustic simulation application that combines the Image Source Method (ISM) for early reflections with measured Binaural Room Impulse Responses (BRIRs) for the late reverberant tail.

The simulator allows users to listen in real time to the direct sound path and the reverberation of a room. Rooms are defined using XML files that describe the room geometry and the wall reflection coefficients. The 3D scene includes a listener and a sound source, as well as a visual representation of the room, the image rooms, and the image sources generated during rendering.

The application also allows the user to move the listener and the source interactively and configure a wide range of acoustic parameters.

Several rooms and BRIR datasets are included, including the two case studies presented in the associated research article, where the BRIRs were measured. The BRIRs are loaded from SOFA files. The repository also includes KEMAR HRTFs.

A paper describing the algorithm implemented in this simulator is currently under review.

## Precompiled Windows Release

A precompiled Windows version of the simulator is available from the Releases section of this repository:

[Download the latest Windows release](https://github.com/3DTune-In/ImageSourceMethodTestApp/releases)

The release is distributed as a ZIP file containing both an `.msi` installer and an `.exe` executable.

## Folder Content

- `resources`: complete set of files required by the application, including HRTFs, BRIRs, SOFA files, room XML files, and audio files. These resources are already included in the repository and do not need to be copied manually.
- `src`: source files of the Hybrid ISM+BRIR Simulator application.
- `vstudio`: Visual Studio project files.

## How to Build and Run in Windows

1. Download openFrameworks for Windows from:

   https://openframeworks.cc/download/

   Latest version tested:

   `of_v0.11.2_vs2017_release`

2. Clone this repository in a folder inside the openFrameworks folder.

   The repository folder name can remain as:

   `ImageSourceMethodTestApp`

3. Make sure the required submodules, including `3dti_AudioToolkit`, are available inside the openFrameworks folder.

4. Open the solution:

   `Image_Source_Method_TestApp.sln`

   located at:

   ```text
   localPath\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\vstudio````

5. Open the project with Visual Studio 2022.

	The current tested configuration is:

	- openFrameworks: of_v0.11.2_vs2017_release
	- Visual Studio: Visual Studio 2022
	- Windows SDK: 10.0.X
	- Platform Toolset: v143
	- openFrameworks project structure
	- Compile the project.
	- Run the application.

	The resources required by the application are already included in the repository, so it is no longer necessary to manually copy the files from the resources folder into the solution folder or executable folder.

### Notes

The use of the third-party library Libsofa may require the user to add to the environment variable PATH the absolute path of the folder containing the Libsofa libraries.

For example, in a 64-bit Microsoft Windows installation, this folder may be located at:

```3dti_AudioToolkit\3dti_ResourceManager\third_party_libraries\sofacoustics\libsofa\dependencies\lib\win\x64```

## Acknowledgments

This work was carried out in the context of the [SONICOM project](https://www.sonicom.eu/), which has received funding from the European Union’s Horizon 2020 research and innovation program under grant agreement No. 101017743; the [MusicSphere](https://musicsphere-eccch.eu/) project, funded by the Horizon Europe programme under grant agreement No. 101233618; and the Spanish National Project [SONIX](https://www.diana.uma.es/sonix/), PID2023-152547NB-I00.

## Citation

To be added.

## License

GNU General Public License v3.0