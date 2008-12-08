// ATIGPU.cpp : Defines the entry point for the DLL application.
//

#include "stdafx.h"
#include "ATIGPU.h"
#include "Arrays.h"
#include "Devices.h"
#include "Common.h"


#ifdef _MANAGED
#pragma managed(push, off)
#endif

/*
	Error codes returned by the library
	taken the same as in CAL
*/
//    CAL_RESULT_OK                = 0, /**< No error */
//    CAL_RESULT_ERROR             = 1, /**< Operational error */
//    CAL_RESULT_INVALID_PARAMETER = 2, /**< Parameter passed in is invalid */
//    CAL_RESULT_NOT_SUPPORTED     = 3, /**< Function used properly but currently not supported */
//    CAL_RESULT_ALREADY           = 4, /**< Stateful operation requested has already been performed */
//    CAL_RESULT_NOT_INITIALIZED   = 5, /**< CAL function was called without CAL being initialized */
//    CAL_RESULT_BAD_HANDLE        = 6, /**< A handle parameter is invalid */
//    CAL_RESULT_BAD_NAME_TYPE     = 7, /**< A name parameter is invalid */
//    CAL_RESULT_PENDING           = 8, /**< An asynchronous operation is still pending */
//    CAL_RESULT_BUSY              = 9,  /**< The resource in question is still in use */
//    CAL_RESULT_WARNING           = 10, /**< Compiler generated a warning */

// TRUE when the library is loaded by a process
BOOL isLoaded = FALSE;

// TRUE when the library is successfully initialized
BOOL isInitialized = FALSE;

// GPU devices
DevicePool* devs = NULL;

BOOL APIENTRY DllMain( HMODULE hModule,
                       DWORD  ul_reason_for_call,
                       LPVOID lpReserved
					 )
{
	CALresult err;	
	CALuint count;
	Device* dev;
	long i;

	switch (ul_reason_for_call)
	{
	case DLL_PROCESS_ATTACH:
		
		// only one process can load the library!
		if(!isLoaded) 
			isLoaded = TRUE; 
		else 
			return FALSE;

		// initialize CAL interface
		err = calInit(); isInitialized = (err == CAL_RESULT_OK);

		if(isInitialized)
		{	
			count = 0;
			err = calDeviceGetCount(&count); // get number of available devices
			if(count > 0)
			{				
				devs = new DevicePool;
				
				// create and open available devices
				for(i = 0; i < (long)count; i++)
				{
					dev = new Device(i);
					if(dev->hDev)
						devs->Add(dev);
					else
						delete dev;
				}
			}			
		}

		break;
	case DLL_THREAD_ATTACH:
		break;
	case DLL_THREAD_DETACH:
		break;
	case DLL_PROCESS_DETACH:				

		if(isInitialized)
		{	
			if(devs) // release all allocated resources
			{				
				delete devs;
				devs = NULL;
			}
			err = calShutdown();
			isInitialized = FALSE;
		}

		isLoaded = FALSE;
		
		break;
	}
    return TRUE;
}

#ifdef _MANAGED
#pragma managed(pop)
#endif


/*
	Get amount of accessible ATI GPUs

	devCount[var] - number of accessible device

	returns error code
*/
ATIGPU_API long GetDevCount(long* devCount)
{
	if(!isInitialized) 
		return CAL_RESULT_NOT_INITIALIZED;	

	*devCount = devs->Length();
	return CAL_RESULT_OK;
}

/*
	Get a new GPU compute context

	devNum - device number
	ctxNum[var] - compute context number

	returns error code
*/
ATIGPU_API long GetContext(long devNum, long* ctxNum)
{	
	long ind;
	Device* dev;
	CALresult err;

	err = CAL_RESULT_OK;

	if(!isInitialized) 
		return CAL_RESULT_NOT_INITIALIZED;
	if( (devNum < 0) || (devNum >= devs->Length()) ) 
		return CAL_RESULT_INVALID_PARAMETER;	
	
	dev = devs->Get(devNum);

	// try to find a context marked as released	
	ind = dev->ctxs->FindNotUsed();
	if(ind >= 0)	// reuse already created context	
		*ctxNum = ind;
	else	// otherwise create a new context
	{		
		err = dev->NewContext();
		*ctxNum = dev->ctxs->Length()-1;
	}

	if(err == CAL_RESULT_OK)		
		(dev->ctxs->Get(*ctxNum))->isInUse = TRUE;
	
	return err;		
}

/*
	Release a GPU computing context:

	devNum - device number
	ctxNum - compute context number

	returns error code
*/
ATIGPU_API long ReleaseContext(long devNum, long ctxNum)
{	
	CALresult err;
	Device* dev;		

	err = CAL_RESULT_OK;

	if(!isInitialized) 
		return CAL_RESULT_NOT_INITIALIZED;
	if( (devNum < 0) || (devNum >= devs->Length()) ) 
		return CAL_RESULT_INVALID_PARAMETER;	
	
	dev = devs->Get(devNum);

	if( (ctxNum < 0) || (ctxNum >= dev->ctxs->Length()) ) 
		return CAL_RESULT_INVALID_PARAMETER;		
	
	// mark context as released
	(dev->ctxs->Get(ctxNum))->isInUse = FALSE;

	return err;	
}


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
							   long ctxNum,
							   ArrayExpressionDesc* expr,
							   ArrayDesc* result,
							   long priority,
							   long flags
							   )
{
	long i, j, ind;
	CALresult err;
	Context* context;	
	ArrayPool* arrs;
	Array* arr;
	Device* dev;
	ArrayDesc** inArgs;
	ArrayExpression* exprI;	

	if(!isInitialized) 
		return CAL_RESULT_NOT_INITIALIZED;
	if( (devNum < 0) || (devNum >= devs->Length()) ) 
		return CAL_RESULT_INVALID_PARAMETER;	
	
	dev = devs->Get(devNum);	

	if( (ctxNum < 0) || (ctxNum >= dev->ctxs->Length()) ) 
		return CAL_RESULT_INVALID_PARAMETER;
	
	arrs = dev->arrs;

	// get context object
	context = dev->ctxs->Get(ctxNum);	
	
	// create internal expression object
	exprI = new ArrayExpression(expr->op,expr->dType,expr->nDims,expr->size,expr->transpDims);
		
	inArgs = new ArrayDesc*[3];
	inArgs[0] = expr->arg1;
	inArgs[1] = expr->arg2;
	inArgs[2] = expr->arg3;	
	
	for(i = 0; (i < 3) && inArgs[i]; i++)
	{
		// look for already existing array
		j = 0;
		while((j < devs->Length()) && ((ind = devs->Get(j)->arrs->Find(inArgs[i]->id)) == -1) ){j++;}
	
		if(ind == -1)	// create a new array
		{		
			arr = new Array(dev->hDev,&dev->info,&dev->attribs,inArgs[i]->id,inArgs[i]->dType,inArgs[i]->nDims,inArgs[i]->size);		
			arr->cpuData = inArgs[i]->data;		

			dev->arrs->Add(arr);	// add new array to the pool
		}
		else	// use already existing array	
		{
			if(j != devNum)	// array resides on another device
			{
				delete inArgs;
				delete exprI;
				return CAL_RESULT_NOT_SUPPORTED;
			}
	
			arr = devs->Get(j)->arrs->Get(ind);			
		}

		exprI->args[i] = arr;		
	}

	delete inArgs;
	
	/*
		Result array
	*/

	// look for already existing array
	j = 0;
	while((j < devs->Length()) && ((ind = devs->Get(j)->arrs->Find(result->id)) == -1) ){j++;}
	
	if(ind == -1)	// create a new array
	{		
		arr = new Array(dev->hDev,&dev->info,&dev->attribs,result->id,result->dType,result->nDims,result->size);		
		arr->cpuData = result->data;

		dev->arrs->Add(arr);	// add new array to the pool
	}
	else	// use already existing array
	{
		// FIXME: check if result fits by dimensions and size!!!

		if(j != devNum)	// array resides on another device
		{
			delete exprI;
			return CAL_RESULT_NOT_SUPPORTED;
		}

		arr = devs->Get(j)->arrs->Get(ind);
	}
	
	err = context->SetComputation(exprI,arr,priority,flags,arrs);
	if(err != CAL_RESULT_OK)
		delete exprI;

	return err;
}

/*
	Do computation which was preliminary set by SetComputation

	devNum - used device number
	ctxNum - computation context	ID

	returns error code
*/
ATIGPU_API long DoComputation(
							   long devNum, 
							   long ctxNum
							   )
{	
	CALresult err;	
	Device* dev;

	err = CAL_RESULT_OK;

	if(!isInitialized) 
		return CAL_RESULT_NOT_INITIALIZED;
	if( (devNum < 0) || (devNum >= devs->Length()) ) 
		return CAL_RESULT_INVALID_PARAMETER;	
	
	dev = devs->Get(devNum);	

	if( (ctxNum < 0) || (ctxNum >= dev->ctxs->Length()) ) 
		return CAL_RESULT_INVALID_PARAMETER;		

	// get context object
	return (dev->ctxs->Get(ctxNum))->DoComputation();	
}

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
						  long ctxNum,						  
						  void* data
						  )
{	
	CALresult err;
	Context* context;	
	Device* dev;

	err = CAL_RESULT_OK;
	
	if(!isInitialized) 
		return CAL_RESULT_NOT_INITIALIZED;
	if( (devNum < 0) || (devNum >= devs->Length()) ) 
		return CAL_RESULT_INVALID_PARAMETER;

	dev = devs->Get(devNum);	

	if( (ctxNum < 0) || (ctxNum >= dev->ctxs->Length()) ) 
		return CAL_RESULT_INVALID_PARAMETER;

	context = dev->ctxs->Get(ctxNum);

	if(context->result)
	{
		if(context->result->remoteRes)
			err = context->result->GetDataFromRemote(context->ctx,data);	
		else
			err = context->result->GetDataFromLocal(context->ctx,data);	

		// clear flag	
		if(err == CAL_RESULT_OK)
			context->result->isReservedForGet = FALSE;
	}
	else
		err = CAL_RESULT_INVALID_PARAMETER;

	return err;
}

/*
	Get an array with given ID
	
	arrID - array ID
	data - array data address

	returns error code
*/
ATIGPU_API long GetArray(						
						 long arrID,
						 void* data
						 )
{
	long j, ind;
	CALresult err;	
	Array* arr;
	CALcontext ctx;
	void* data1;

	err = CAL_RESULT_OK;

	if(!isInitialized) 
		return CAL_RESULT_NOT_INITIALIZED;	

	// find array in device pools
	j = 0;
	while((j < devs->Length()) && ((ind = devs->Get(j)->arrs->Find(arrID)) == -1) ){j++;}
	
	if(ind >= 0)
	{
		arr = devs->Get(j)->arrs->Get(ind);
				
		data1 = data;
		if(!data1) 
			data1 = arr->cpuData;

		if(!data1)
			return CAL_RESULT_INVALID_PARAMETER;

		arr->cpuData = data1;	// set as a new data address!
		
		err = calCtxCreate(&ctx,arr->hDev);
		if(err == CAL_RESULT_OK)
		{			
			if(arr->remoteRes)
				err = arr->GetDataFromRemote(ctx,data1);	
			else
				err = arr->GetDataFromLocal(ctx,data1);	
			
			// clear flag
			if(err == CAL_RESULT_OK)			
				arr->isReservedForGet = FALSE;

			calCtxDestroy(ctx);
		}
	}
	else
		err = CAL_RESULT_INVALID_PARAMETER;

	return err;
}

/*
	Free an array with given ID
	
	arrID - array ID

	returns error code
*/
ATIGPU_API long FreeArray(long arrID)
{
	long j, ind;	
	CALresult err;
	
	err = CAL_RESULT_OK;

	if(!isInitialized) 
		return CAL_RESULT_NOT_INITIALIZED;	

	// find array in device pools
	j = 0;
	while((j < devs->Length()) && ((ind = devs->Get(j)->arrs->Find(arrID)) == -1) ){j++;}
	
	if(ind >= 0)
	{
		devs->Get(j)->arrs->Remove(ind);	
	}
	else
		err = CAL_RESULT_INVALID_PARAMETER;

	return err;
}

/*
	Start GPU idle counter

	devNum - used device number
	ctxNum - compute context number

	returns error code
*/
ATIGPU_API long StartIdleCounter(long devNum, long ctxNum)
{		
	Device* dev;

	if(!isInitialized) 
		return CAL_RESULT_NOT_INITIALIZED;
	if( (devNum < 0) || (devNum >= devs->Length()) ) 
		return CAL_RESULT_INVALID_PARAMETER;

	dev = devs->Get(devNum);

	if( (ctxNum < 0) || (ctxNum >= dev->ctxs->Length()) ) 
		return CAL_RESULT_INVALID_PARAMETER;		
	
	return dev->ctxs->Get(ctxNum)->StartIdleCounter();	
}

/*
	Start GPU cache hit counter

	devNum - used device number
	ctxNum - compute context number	

	returns error code
*/
ATIGPU_API long StartCacheHitCounter(long devNum, long ctxNum)
{	
	Device* dev;

	if(!isInitialized) 
		return CAL_RESULT_NOT_INITIALIZED;
	if( (devNum < 0) || (devNum >= devs->Length()) ) 
		return CAL_RESULT_INVALID_PARAMETER;	

	dev = devs->Get(devNum);

	if( (ctxNum < 0) || (ctxNum >= dev->ctxs->Length()) ) 
		return CAL_RESULT_INVALID_PARAMETER;
		
	return dev->ctxs->Get(ctxNum)->StartCacheHitCounter();	
}

/*
	Stop GPU idle counter

	devNum - used device number
	ctxNum - compute context number	

	returns error code
*/
ATIGPU_API long StopIdleCounter(long devNum, long ctxNum)
{		
	Device* dev;

	if(!isInitialized) 
		return CAL_RESULT_NOT_INITIALIZED;
	if( (devNum < 0) || (devNum >= devs->Length()) ) 
		return CAL_RESULT_INVALID_PARAMETER;	
	
	dev = devs->Get(devNum);

	if( (ctxNum < 0) || (ctxNum >= dev->ctxs->Length()) ) 
		return CAL_RESULT_INVALID_PARAMETER;

	return dev->ctxs->Get(ctxNum)->StopIdleCounter();
}

/*
	Stop GPU cache hit counter

	devNum - used device number
	ctxNum - compute context number

	returns error code
*/
ATIGPU_API long StopCacheHitCounter(long devNum, long ctxNum)
{	
	Device* dev;

	if(!isInitialized) 
		return CAL_RESULT_NOT_INITIALIZED;
	if( (devNum < 0) || (devNum >= devs->Length()) ) 
		return CAL_RESULT_INVALID_PARAMETER;	
	
	dev = devs->Get(devNum);

	if( (ctxNum < 0) || (ctxNum >= dev->ctxs->Length()) ) 
		return CAL_RESULT_INVALID_PARAMETER;

	return dev->ctxs->Get(ctxNum)->StopCacheHitCounter();
}

/*
	Get GPU idle counter

	devNum - used device number
	ctxNum - compute context number
	counterVal[var] - counter value

	returns error code
*/
ATIGPU_API long GetIdleCounter(long devNum, long ctxNum, float* counterVal)
{	
	Device* dev;

	if(!isInitialized) 
		return CAL_RESULT_NOT_INITIALIZED;
	if( (devNum < 0) || (devNum >= devs->Length()) ) 
		return CAL_RESULT_INVALID_PARAMETER;	
	
	dev = devs->Get(devNum);

	if( (ctxNum < 0) || (ctxNum >= dev->ctxs->Length()) ) 
		return CAL_RESULT_INVALID_PARAMETER;

	return dev->ctxs->Get(ctxNum)->GetIdleCounter(counterVal);	
}

/*
	Get GPU cache hit counter

	devNum - used device number
	ctxNum - compute context number
	counterVal[var] - counter value

	returns error code
*/
ATIGPU_API long GetCacheHitCounter(long devNum, long ctxNum, float* counterVal)
{	
	Device* dev;

	if(!isInitialized) 
		return CAL_RESULT_NOT_INITIALIZED;
	if( (devNum < 0) || (devNum >= devs->Length()) ) 
		return CAL_RESULT_INVALID_PARAMETER;	
	
	dev = devs->Get(devNum);

	if( (ctxNum < 0) || (ctxNum >= dev->ctxs->Length()) ) 
		return CAL_RESULT_INVALID_PARAMETER;

	return dev->ctxs->Get(ctxNum)->GetCacheHitCounter(counterVal);	
}
