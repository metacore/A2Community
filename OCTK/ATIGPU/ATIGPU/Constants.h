#pragma once

class Constant
{
public:
	Constant(CALdevice hDev, CALcontext ctx, CALname name, CALformat dFormat, long size);
	~Constant(void);
	
	// set constant data
	CALresult SetData(void* data);	
	// fill the whole constant with data pattern
	CALresult Fill(void* pattern, long patternSize);
	CALresult err;	// error code forr last operation
		
	CALcontext ctx;			// context handle
	CALresource localRes;	// local resource
	CALresource remoteRes;	// remote resource
	CALname name;			// constant CAL name
	CALmem mem;				// memory handle

	CALformat dFormat;		// data format
	long size;				// constant size
	long dataSize;			// total data size in bytes	
	// set constant memory to the context
	CALresult SetToContext(void);
	// release constant memory from the context
	void ReleaseFromContext(void);
};
