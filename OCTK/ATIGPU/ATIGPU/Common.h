#pragma once
#include "cal_ext.h"
#include "cal_ext_counter.h"

#define TSHORTINT	1
#define TINTEGER	2
#define TLONGINT	3
#define THUGEINT	4 
#define TREAL		5
#define TLONGREAL	6

// Conversion from ArrayObjects data type to GPU data format
CALformat GetFormat(long dType, long numComponents);

// Get element size for a given data type
long GetElementSize(long dType);

// Get element size for a given data format
long GetElementSize1(CALformat dFormat);

// returns number of elements fitting to the size padded to the multiple of "numComponents"
long GetPaddedNumElements(long size, long numComponents);

// returns TRUE if to array sizes are equal
BOOL EqualSizes(long nDims1, long* size1, long nDims2, long* size2);

// copy data from one resource to another
CALresult ResCopy(CALcontext ctx, CALresource dstRes, CALresource srcRes);


typedef struct {
    LARGE_INTEGER start;
    LARGE_INTEGER stop;
} stopWatch;

class CStopWatch {

private:
	stopWatch timer;
	LARGE_INTEGER frequency;
	double LIToSecs( LARGE_INTEGER & L)
	{
		return ((double)L.QuadPart /(double)frequency.QuadPart);
	};

public:
	CStopWatch()
	{
		timer.start.QuadPart=0;
		timer.stop.QuadPart=0;	
		QueryPerformanceFrequency( &frequency );
	};

	void Start( ){QueryPerformanceCounter(&timer.start);};
	void Stop( ){QueryPerformanceCounter(&timer.stop);};
	double Elapsed()
	{
		LARGE_INTEGER time;
		time.QuadPart = timer.stop.QuadPart - timer.start.QuadPart;
		return LIToSecs( time) ;
	};
};