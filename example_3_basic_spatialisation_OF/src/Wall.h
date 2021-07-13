#pragma once
#include <vector>
#include <Common/Vector3.h>
class Wall
{
public:
	void insertCorner(float x, float y, float z);
	void setupPlane(float x0, float y0, float z0, float ax, float by, float cz);
	void setupPlane(float x0, float y0, float z0, float normalVec[3]);
	void setupDimensions(float width, float length, float height);

	void draw();

private:
	std::vector<Common::CVector3> poligon; // corners of teh wall
	float x0, y0, z0;                      // Point: (x0,y0,z0) 
	float ax, by, cz, d;                   // General Plane Eq.: Ax + By + Cz + D = 0
	float normalVec[3];                    // Normal vector    
	float width, length, height;           // Dimensions
};

