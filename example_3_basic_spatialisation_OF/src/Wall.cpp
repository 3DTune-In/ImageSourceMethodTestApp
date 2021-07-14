#include "ofMain.h"
#include "Wall.h"

void Wall::insertCorner(float _x, float _y, float _z)
{
	Common::CVector3 tempCorner(_x, _y, _z);
	if (polygon.size() < 4)
	{
		polygon.push_back(tempCorner);
	}
	else
	{
	}
}
Common::CVector3 Wall::getNormal()
{
	Common::CVector3 normal, p1, p2;
	float modulus;

	p1 = polygon.at(1) - polygon.at(0);
	p2 = polygon.at(2) - polygon.at(0);

	normal = p1.CrossProduct(p2);
	modulus = normal.GetDistance();

	normal.x = normal.x / modulus;
	normal.y = normal.y / modulus;
	normal.z = normal.z / modulus;

	ofLine(0, 0, 0, normal.x, normal.y, normal.z);

	return normal;
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
	int numberVertex=polygon.size();
	for(int i=0; i<numberVertex-1; i++)
	{
		ofLine(polygon[i].x, polygon[i].y, polygon[i].z,
			polygon[i + 1].x, polygon[i + 1].y, polygon[i+1].z);
	}
	ofLine(polygon[0].x, polygon[0].y, polygon[0].z,
		polygon[numberVertex-1].x, polygon[numberVertex-1].y, polygon[numberVertex-1].z);
}