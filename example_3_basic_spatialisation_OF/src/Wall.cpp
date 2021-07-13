#include "ofMain.h"
#include "Wall.h"

void Wall::insertCorner(float _x, float _y, float _z)
{
	Common::CVector3 tempCorner(_x, _y, _z);
	poligon.push_back(tempCorner);
}

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

void Wall::draw()
{
	int numberVertex=poligon.size();
	for(int i=0; i<numberVertex-1; i++)
	{
		ofLine(poligon[i].x, poligon[i].y, poligon[i].z,
			poligon[i + 1].x, poligon[i + 1].y, poligon[i+1].z);
	}
	ofLine(poligon[0].x, poligon[0].y, poligon[0].z,
		poligon[numberVertex-1].x, poligon[numberVertex-1].y, poligon[numberVertex-1].z);
}