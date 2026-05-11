

function [resourcesFolder, pathSc]= verOpenF ()

    oF11 = 'C:\Repos\of_v0.11.2_vs2017_release';
    oF12 = 'C:\Repos\of_v0.12.0_vs_release';

    if exist(oF12, 'dir') == 7
        resourcesFolder = 'C:\Repos\of_v0.12.0_vs_release\ImageSourceMethodTestApp\bin\data\resources\';
        pathSc = 'C:\Repos\of_v0.12.0_vs_release\ImageSourceMethodTestApp\ISM_OSC_Tester\MatlabOscTester';
    else
        resourcesFolder = 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\';
        pathSc = 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\ISM_OSC_Tester\MatlabOscTester';
    end

end