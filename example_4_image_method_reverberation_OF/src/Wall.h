#pragma once
#include <vector>
#include <Common/Vector3.h>
class Wall
{
public:
	int insertCorner(float x, float y, float z);
	Common::CVector3 getNormal();
	Common::CVector3 getCenter();
	void calculate_ABCD();
	float getDistanceFromPoint(Common::CVector3 point);
	Common::CVector3 getImagePoint(Common::CVector3 point);
	void draw();
	void drawNormal();
	

	void setupPlane(float x0, float y0, float z0, float ax, float by, float cz);
	void setupPlane(float x0, float y0, float z0, float normalVec[3]);
	void setupDimensions(float width, float length, float height);
		

private:
	std::vector<Common::CVector3> polygon; // corners of the wall
	Common::CVector3 normal;               // Normal vector
	Common::CVector3 center;               // Center coordinates
	Common::CVector3 imagePoint;           // Image Point

	float x0, y0, z0;                      // Point: (x0,y0,z0) 
	float A, B, C, D;                      // General Plane Eq.: Ax + By + Cz + D = 0
	
	float normalVec[3];                    // Normal vector    
	float width, length, height;           // Dimensions
};

