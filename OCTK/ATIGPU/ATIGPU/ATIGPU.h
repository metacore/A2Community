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

#include "Arrays.h"

/*
	Get amount of accessible ATI GPUs:

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
ATIGPU_API long GetContext(long devNum, long* ctxId);

/*
	Release a GPU computing context:

	devNum - device number
	ctxNum - compute context number

	returns error code
*/
ATIGPU_API long ReleaseContext(long devNum, long ctxId);


/*
	Set (prepare) computation

	devNum - used device number
	ctxNum - compute context number
	expr - array expression description
	result - resulting array
	priority - computation priority number
	flags - flags (currently unused)

	returns error code
*/
ATIGPU_API long SetComputation(
							   long devNum, 
							   long ctxId,
							   ArrayExpressionDesc* expr,
							   ArrayDesc* result,
							   long priority,
							   long flags
							   );


/*
	Do computation which was preliminary set by SetComputation

	devNum - used device number
	ctxNum - compute context number

	returns error code
*/
ATIGPU_API long DoComputation(
							   long devNum, 
							   long ctxId
							   );

/*
	Get result array for the last computation
	(has to be called after DoComputation)
	
	devNum - used device number
	ctxNum - compute context number
	data - array data address

	returns error code
*/
ATIGPU_API long GetResult(
						  long devNum,
						  long ctxId,						  
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

	devNum - used device number
	ctxNum - compute context number

	returns error code
*/
ATIGPU_API long StartIdleCounter(long devNum,long ctxId);

/*
	Start GPU cache hit counter

	devNum - used device number
	ctxNum - compute context number

	returns error code
*/
ATIGPU_API long StartCacheHitCounter(long devNum,long ctxId);

/*
	Stop GPU idle counter

	devNum - used device number
	ctxNum - compute context number

	returns error code
*/
ATIGPU_API long StopIdleCounter(long devNum,long ctxId);

/*
	Stop GPU cache hit counter

	devNum - used device number
	ctxNum - compute context number

	returns error code
*/
ATIGPU_API long StopCacheHitCounter(long devNum,long ctxId);

/*
	Get GPU idle counter

	devNum - used device number
	ctxNum - compute context number
	counterVal[var] - counter value

	returns error code
*/
ATIGPU_API long GetIdleCounter(long devNum,long ctxId, float* counterVal);

/*
	Get GPU cache hit counter

	devNum - used device number
	ctxNum - compute context number
	counterVal[var] - counter value

	returns error code
*/
ATIGPU_API long GetCacheHitCounter(long devNum,long ctxId, float* counterVal);
