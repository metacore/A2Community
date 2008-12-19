#pragma once

class Constant
{
public:
	Constant(CALdevice hDev, CALcontext ctx, CALname name, CALformat dFormat, long size, CALresult* err);
	~Constant(void);

	// set constant data
	CALresult SetData(void* data);
	// fill the whole constant space with given data pattern
	CALresult Fill(void* pattern, long patternSize);
	// set constant memory to the context
	CALresult SetToContext(void);
	// release constant memory from the context
	void ReleaseFromContext(void);

	CALcontext ctx;			// context handle
	CALresource res;		// resource	
	CALname name;			// constant CAL name
	CALmem mem;				// memory handle

	CALformat dFormat;		// data format
	long size;				// constant size
	long dataSize;			// total data size in bytes
};
