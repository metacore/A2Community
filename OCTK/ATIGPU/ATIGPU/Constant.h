#pragma once

#include "Modules.h"

class Constant
{
public:
	Constant(Module* module, long ind, long dType, long size, long numComponents);
	~Constant(void);
	
	// set constant data
	CALresult Set(void* data);	
	// fill the whole constant with data pattern
	CALresult Fill(void* pattern, long patternSize);
	CALresult err;	// error code forr last operation
		
	CALcontext ctx;			// context handle
	CALresource res;		// resource (only local)
	CALmem mem;				// memory handle

	long dType;				// constant data type
	CALformat dFormat;		// data format
	long size;				// constant size
	long dataSize;			// total data size in bytes
	long numComponents;
};
