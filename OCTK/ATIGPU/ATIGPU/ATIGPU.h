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
	Create a new CPU computing context:

	devNum - device number
	ctxNum[var] - context number

	returns error code
*/
ATIGPU_API long CreateContext(long devNum, long* ctx);

/*
	Destroy an already existing CPU computing context:

	devNum - device number
	ctxNum - context number

	returns error code
*/
ATIGPU_API long DestroyContext(long devNum, long ctx);

//
///*
//	Set first argument of an array expression:
//
//	devNum - used device number
//	ctx - used context
//	argID - argument ID 
//	dType - data type code
//	nDims - number of dimensions
//	size - size for each dimensions	
//	data - data to set
//
//	returns error code	
//*/
//ATIGPU_API long SetArg1(long devNum, long ctx, long argID, long dType, long nDims, long* size, void* data);
//
///*
//	Set second argument of an array expression:
//
//	devNum - used device number
//	ctx - used context
//	argID - argument ID 
//	dType - data type code
//	nDims - number of dimensions
//	size - size for each dimensions	
//	data - data to set
//
//	returns error code	
//*/
//ATIGPU_API long SetArg2(long devNum, long ctx, long argID, long dType, long nDims, long* size, void* data);
//
///*
//	Set return argument of an array expression
//
//	devNum - used device number
//	ctx - used context
//	argID - argument ID 
//	dType - data type code
//	nDims - number of dimensions
//	size - size for each dimensions	
//	data - data to set
//	bSetData - if 0 the data will not be set
//
//	returns error code	
//*/
//ATIGPU_API long SetReturnArg(long devNum, long ctx, long argID, long dType, long nDims, long* size, void* data, long bSetData);
//
///*
//	Get an argument:
//
//	devNum - used device number
//	ctx - used context	
//	data - data for writing
//
//	returns error code
//
//	takes already set return argument and copies data from local/remote GPU memory to CPU memory
//*/
//ATIGPU_API long GetReturnArg(long devNum, long ctx);
//
///*
//	Get an argument from GPU local/remote memory
//	
//	argID - ID of the argument to get
//
//	returns error code
//
//	Copies argument data from local/remote GPU memory to CPU memory
//*/
//ATIGPU_API long GetArg(long argID);
//
//
///*
//	Compute an op operation using already set Arg1, Arg2, RetArg
//
//	devNum - used device number
//	ctx - used context	
//	op - operation code
//
//	returns error code
//*/
//ATIGPU_API long Do(long devNum, long ctx, long op);
//
///*
//	Free an argument with given ID
//*/
//ATIGPU_API long FreeArg(long argID);
//


/*
	Set (prepare) computation

	devNum - used device number
	ctx - computation context
	expr - array expression description
	result - resulting array
	priority - computation priority number
	flags - flags (currently unused)

	returns error code
*/
ATIGPU_API long SetComputation(
							   long devNum, 
							   long ctx,
							   ArrayExpressionDesc* expr,
							   ArrayDesc* result,
							   long priority,
							   long flags
							   );


/*
	Do computation which was preliminary set by SetComputation

	devNum - used device number
	ctx - used context	

	returns error code
*/
ATIGPU_API long DoComputation(
							   long devNum, 
							   long ctx
							   );

/*
	Get result array for the last computation
	(has to be called after DoComputation)
	
	devNum - used device number
	ctx - computation context
	data - array data address

	returns error code
*/
ATIGPU_API long GetResult(
						  long devNum,
						  long ctx,						  
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