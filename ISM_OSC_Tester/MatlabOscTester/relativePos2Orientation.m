%% This script calculates the yaw pitch and roll angles from the 
%% relative positions between the source and the listener

% Author: Fabian Arrebola (22/12/2023) 
% contact: areyesa@uma.es
% 3DDIANA research group. University of Malaga
% Project: SONICOM
% 
% Copyright (C) 2023 Universidad de Málaga

function [yaw, pitch, roll] = relativePos2Orientation(posListener, posSource)
   xA = posListener(1); yA = posListener(2); zA = posListener(3);
   xB = posSource(1); yB = posSource(2); zB = posSource(3);
   % Vector
   vecLS = [xB - xA, yB - yA, zB - zA];
   vecLSNomr= vecLS/norm(vecLS);

   if vecLSNomr(1)==1 && vecLSNomr(2)== 0 && vecLSNomr(3) == 0
       yaw=0; pitch=0; roll=0;
       rAxis = [0 0 1];
       rAngle = 0;
   else
       rAxis = cross([1 0 0], vecLSNomr );
       if rAxis == 0
           if vecLSNomr == [0 0 1]
               rAxis = [0 0 1];
               rAngle = 0;
           else
               rAxis = [0 0 1];
               rAngle = pi;
           end
       else
           rAxis = rAxis/norm(rAxis);
           rAngle = acos(dot([1 0 0], vecLSNomr));
       end
       halfAngle = rAngle / 2;
       sinHalfAngle = sin(halfAngle);
       q = [cos(halfAngle), sinHalfAngle * rAxis];
       [yaw, pitch, roll] = quat2angle(q, "ZYX");
       q2 = axang2quat([rAxis, rAngle]);
   end 
end