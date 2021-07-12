#pragma once
class Wall
{
public:
	void setupPlane(float x0, float y0, float z0, float ax, float by, float cz);
	void setupPlane(float x0, float y0, float z0, float normalVec[3]);
	void setupDimensions(float width, float length, float height);


private:
	float x0, y0, z0;                      // Point: (x0,y0,z0) 
	float ax, by, cz, d;                   // General Plane Eq.: Ax + By + Cz + D = 0
	float normalVec[3];                    // Normal vector    
	float width, length, height;           // Dimensions
};

