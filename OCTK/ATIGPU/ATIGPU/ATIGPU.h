// The following ifdef block is the standard way of creating macros which make exporting 
// from a DLL simpler. All files within this DLL are compiled with the ATIGPU_EXPORTS
// symbol defined on the command line. this symbol should not be defined on any project
// that uses this DLL. This way any other project whose source files include this file see 
// ATIGPU_API functions as being imported from a DLL, whereas this DLL sees symbols
// defined with this macro as being exported.
#ifdef ATIGPU_EXPORTS
#define ATIGPU_API extern "C" __declspec(dllexport)
#else
#define ATIGPU_API __declspec(dllimport)
#endif

// array description
struct ArrayDesc
{
	long id;	// array ID
	long dType;	// array data type code
	long nDims;	// number of dimensions	
	long* size;	// array size
	void* data;	// array data address

	// for the case of FIR filter matrix
	ArrayDesc* kernel;	// FIR filter kernel
	long hotSpot;
	long boundary;
};

// array expression description
struct ArrayExpressionDesc
{
	long op;		// operation code
	long dType;		// data type code
	long nDims;		// number of dimensions of expression result
	long* size;		// size of expression result
	long* transpDims;	// transposed dimensions in case of transposition operation
	ArrayDesc* arg1;	// first argument desription
	ArrayDesc* arg2;	// second argument desription
	ArrayDesc* arg3;	// second argument desription	
};

/*
	Get amount of accessible ATI GPUs

	devCount[var] - number of accessible device

	returns error code
*/
ATIGPU_API long GetDevCount(long* devCount);

/*
	Get a new GPU compute context

	devNum - device number
	ctxNum[var] - compute context number

	returns error code
*/
ATIGPU_API long GetContext(long devNum, long* ctxNum);

/*
	Release a GPU computing context:

	devNum - device number
	ctxNum - compute context number

	returns error code
*/
ATIGPU_API long ReleaseContext(long devNum, long ctxNum);


/*
	Set (prepare) computation

	devNum - device number
	ctxNum - compute context number
	exprDesc - array expression description
	resultDesc - resulting array description
	priority - computation priority number
	flags - flags (currently unused)

	returns error code
*/
ATIGPU_API long SetComputation(
							   long devNum, 
							   long ctxNum,
							   ArrayExpressionDesc* exprDesc,
							   ArrayDesc* resultDesc,
							   long priority,
							   long flags
							   );


/*
	Do computation which was preliminary set by SetComputation

	devNum - device number
	ctxNum - compute context number

	returns error code
*/
ATIGPU_API long DoComputation(
							   long devNum, 
							   long ctxNum
							   );

/*
	Get result array for the last computation done by DoComputation	
	
	devNum - device number
	ctxNum - compute context number
	data - array data address

	returns error code
*/
ATIGPU_API long GetResult(
						  long devNum,
						  long ctxNum,						  
						  void* data
						  );

/*
	Get an array with given ID
	
	arrID - array ID
	data - array data address

	returns error code
*/
ATIGPU_API long GetArray(						 
						 long arrID,
						 void* data
						 );


/*
	Free an array with given ID
	
	arrID - array ID

	returns error code
*/
ATIGPU_API long FreeArray(long arrID);

/*
	Start GPU idle counter

	devNum - device number
	ctxNum - compute context number

	returns error code
*/
ATIGPU_API long StartIdleCounter(long devNum, long ctxNum);

/*
	Start GPU cache hit counter

	devNum - device number
	ctxNum - compute context number

	returns error code
*/
ATIGPU_API long StartCacheHitCounter(long devNum, long ctxNum);

/*
	Stop GPU idle counter

	devNum - device number
	ctxNum - compute context number

	returns error code
*/
ATIGPU_API long StopIdleCounter(long devNum, long ctxNum);

/*
	Stop GPU cache hit counter

	devNum - device number
	ctxNum - compute context number

	returns error code
*/
ATIGPU_API long StopCacheHitCounter(long devNum, long ctxNum);

/*
	Get GPU idle counter

	devNum - device number
	ctxNum - compute context number
	counterVal[var] - counter value

	returns error code
*/
ATIGPU_API long GetIdleCounter(long devNum, long ctxNum, float* counterVal);

/*
	Get GPU cache hit counter

	devNum - used device number
	ctxNum - compute context number
	counterVal[var] - counter value

	returns error code
*/
ATIGPU_API long GetCacheHitCounter(long devNum, long ctxNum, float* counterVal);