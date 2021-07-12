#include "Wall.h"
void Wall::setupPlane (float _x, float _y, float _z, 
	                   float _ax, float _by, float _cz) 
{
	// Point: (x0,y0,z0)
	x0 = _x;
    y0 = _y;
	z0 = _z;
	// General Plane Eq.: Ax + By + Cz + D = 0
	ax = _ax;
	by = _by;
	cz = _cz;

	d = -ax * x0 - by * y0 - cz * z0; 

	// Normal vector 
	this->normalVec[0] = _ax;
	this->normalVec[1] = _by;
	this->normalVec[2] = _cz;
}
void Wall::setupPlane(float _x, float _y, float _z,
	            float normalVector[3])
{
	// Point: (x0,y0,z0)
	x0 = _x;
	y0 = _y;
	z0 = _z;
	// Normal vector 
	this->normalVec[0] = normalVector[0];
	this->normalVec[1] = normalVector[1];
	this->normalVec[2] = normalVector[2];
	// General Plane Eq.: Ax + By + Cz + D = 0
	ax = normalVector[0];
	by = normalVector[1];
	cz = normalVector[2];

	d = -ax * x0 - by * y0 - cz * z0;

	
}
