#include "ofMain.h"
#include "Wall.h"

#ifndef THRESHOLD
#define THRESHOLD 0.0000001f
#endif


int Wall::insertCorner(float _x, float _y, float _z)
{
	Common::CVector3 tempCorner(_x, _y, _z);
	if (polygon.size() < 4)
	{
		polygon.push_back(tempCorner);
		if (polygon.size() == 3) calculate_ABCD();
	}
	else
	{
		if (_x*A + _y+ B + _z*C + D < THRESHOLD) // ¿DBL_EPSILON? ¿THRESHOLD?
		{
			polygon.push_back(tempCorner);
		}
		else {
			return 0;
		}
	}
	return 1;
}
Common::CVector3 Wall::getNormal()
{
	//Common::CVector3 normal, p1, p2; 
	Common::CVector3 p1, p2;
	float modulus;

	p1 = polygon.at(1) - polygon.at(0);
	p2 = polygon.at(2) - polygon.at(0);

	normal = p1.CrossProduct(p2);
	
	//A = normal.x;
	//B = normal.y;
	//C = normal.z;
	//D = -(A * polygon.at(2).x + B * polygon.at(2).y + C * polygon.at(2).z);

	modulus = normal.GetDistance();

	normal.x = normal.x / modulus;
	normal.y = normal.y / modulus;
	normal.z = normal.z / modulus;
		
	return normal;
}

Common::CVector3 Wall::getCenter()
{
	center = Common::CVector3::ZERO;

	for (auto i = 0; i < polygon.size(); i++) 
	{
		center.x += polygon.at(i).x;
		center.y += polygon.at(i).y;
		center.z += polygon.at(i).z;
	}
	center.x /= polygon.size();
	center.y /= polygon.size();
	center.z /= polygon.size();

	return center;
	 
}

float Wall::getDistanceFromPoint(Common::CVector3 point)
{
	float distance;
	calculate_ABCD();
	distance = fabs(A*point.x + B * point.y + C * point.z + D);
	distance = distance / sqrtf(A * A + B * B + C * C);
	return distance;
}

Common::CVector3 Wall::getImagePoint(Common::CVector3 point)
{
	float distance;
	Common::CVector3 cutPoint, imagePoint, normalRay;
	distance = getDistanceFromPoint(point);

	normalRay = getNormal();
	normalRay.x *= -(2*distance);
	normalRay.y *= -(2*distance);
	normalRay.z *= -(2*distance);

	imagePoint = point + normalRay;

	return imagePoint;
}


void Wall::calculate_ABCD()
{
	Common::CVector3 normal;
	normal = getNormal();
	A = normal.x;
	B = normal.y;
	C = normal.z;
	D = -(A * polygon.at(2).x + B * polygon.at(2).y + C * polygon.at(2).z);
}

void Wall::setupPlane (float _x, float _y, float _z,
	                   float _ax, float _by, float _cz) 
{
	// Point: (x0,y0,z0)
	x0 = _x;
    y0 = _y;
	z0 = _z;
	// General Plane Eq.: Ax + By + Cz + D = 0
	A = _ax;
	B = _by;
	C = _cz;

	D = -A*x0 + B*y0 - C*z0; 

	// Normal vector 
	this->normalVec[0] = A;
	this->normalVec[1] = B;
	this->normalVec[2] = C;
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
	A = normalVector[0];
	B = normalVector[1];
	C = normalVector[2];

	D = -A * x0 + B * y0 - C * z0;
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
void Wall::drawNormal()
{
	Common::CVector3 center;
	Common::CVector3 normalEnd;
	center = getCenter();
	normalEnd = center + getNormal();
	ofLine(center.x, center.y, center.z, normalEnd.x, normalEnd.y, normalEnd.z);
}
