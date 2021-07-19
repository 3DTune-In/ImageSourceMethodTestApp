#pragma once
#include <vector>
#include <Common/Vector3.h>

# define LENGTH_OF_NORMALS 0.2
class Wall
{
public:
	int insertCorner(float x, float y, float z);
	Common::CVector3 getNormal();
	Common::CVector3 getCenter();
	void calculate_ABCD();
	float getDistanceFromPoint(Common::CVector3 point);
	Common::CVector3 getImagePoint(Common::CVector3 point);

	Common::CVector3 getPointProjection(float x, float y, float z);

	void draw();
	void drawNormal(float length=LENGTH_OF_NORMALS);
		
private:
	std::vector<Common::CVector3> polygon; // corners of the wall
	
	float x0, y0, z0;                      // Point: (x0,y0,z0) 
	float A, B, C, D;                      // General Plane Eq.: Ax + By + Cz + D = 0
		
};

