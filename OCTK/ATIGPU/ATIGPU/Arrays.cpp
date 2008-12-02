#include "StdAfx.h"
#include "Arrays.h"
#include "Common.h"

Array::Array(CALdevice hDev, CALdeviceinfo* devInfo, CALdeviceattribs* devAttribs, long arrID, long dType, long nDims, long* size)
{
	long i;	

	this->hDev = hDev;	
	this->arrID = arrID;		
	this->dType = dType;	
	
	physNumComponents = 4;
	if(dType == TLONGREAL)
		physNumComponents = 2;

	this->dFormat = GetFormat(dType,physNumComponents);
	this->nDims = nDims;
	elemSize = GetElementSize(dType);	
	physElemSize = elemSize*physNumComponents;
	isVirtualized = FALSE;		

	this->size = new long[nDims]; 
	// total number of elements
	numElements = 1;
	for(i = 0; i < nDims; i++)
	{
		this->size[i] = size[i];
		numElements *= size[i];
	}	
	// total data size in bytes
	dataSize = numElements*elemSize;

	// does it fit to hardware memory layout requirements?
	if( ((nDims == 1) && (GetPaddedNumElements(size[0],physNumComponents) <= (long)devInfo->maxResource1DWidth)) 
		|| ((nDims == 2) && (GetPaddedNumElements(size[1],physNumComponents) <= (long)devInfo->maxResource2DWidth) && (size[0] <= (long)devInfo->maxResource2DHeight) ) )
	{
		// if yes - no memory virtualization! (logical dimensions coincides with real ones)
		nLogicDims = nDims;
		logicSize = new long[nLogicDims];
		for(i = 0; i < nLogicDims; i++)
			logicSize[i] = size[i];				
	}
	else
	{	
		// Virtualization -> represent array as 2D object

		nLogicDims = 2;

		logicSize = new long[2];
		logicSize[1] = devInfo->maxResource2DWidth;
		
		i = dataSize / elemSize;
		logicSize[0] = i / logicSize[1];
		if(logicSize[0]*logicSize[1] < i)
			logicSize[0]++;		
		
		isVirtualized = TRUE;
	}	
	
	// physical size -> account padding to multiple of physNumComponents
	physSize = new long[nLogicDims];
	physSize[0] = logicSize[0];
	if(nLogicDims == 1)
	{
		physSize[0] = GetPaddedNumElements(physSize[0],physNumComponents);
		pitch = (physSize[0]/devAttribs->pitch_alignment)*devAttribs->pitch_alignment;
		if(physSize[0] % devAttribs->pitch_alignment) pitch += devAttribs->pitch_alignment;
	}
	else if(nLogicDims == 2)
	{
		physSize[1] = GetPaddedNumElements(logicSize[1],physNumComponents);
		pitch = (physSize[1]/devAttribs->pitch_alignment)*devAttribs->pitch_alignment;
		if(physSize[1] % devAttribs->pitch_alignment) pitch += devAttribs->pitch_alignment;
	}

	// logic and physical data size in bytes
	logicDataSize = elemSize;
	physNumElements = 1;	
	for(i = 0; i < nLogicDims; i++)
	{
		logicDataSize *= logicSize[i];
		physNumElements *= physSize[i];
	}
	physDataSize = physNumElements*physElemSize;	
	
	cpuData = NULL;
	remoteRes = 0;
	localRes = 0;

	useCounter = 0;
	isReservedForGet = FALSE;
	localIsGlobalBuf = FALSE;
	remoteIsGlobalBuf = FALSE;
}

Array::~Array(void)
{
	if(size) 
		delete size;

	if(logicSize)
		delete logicSize;

	if(physSize)
		delete physSize;

	FreeLocal();
	FreeRemote();
}

CALresult Array::AllocateLocal(CALuint flags)
{
	err = CAL_RESULT_NOT_SUPPORTED;

	FreeLocal();
	
	if(nLogicDims == 2)
		err = calResAllocLocal2D(&localRes,hDev,physSize[1],physSize[0],dFormat,flags);
	else if(nLogicDims == 1)
		err = calResAllocLocal2D(&localRes,hDev,physSize[0],1,dFormat,flags);

	if(err == CAL_RESULT_OK)
	{
		if(flags && CAL_RESALLOC_GLOBAL_BUFFER) 
			localIsGlobalBuf = TRUE; 
		else
			localIsGlobalBuf = FALSE;
	}
	else
		localRes = 0;	
	
	return err;
}

CALresult Array::AllocateRemote(CALuint flags)
{
	err = CAL_RESULT_NOT_SUPPORTED;	

	FreeRemote();
	
	if(nLogicDims == 2)
		err = calResAllocRemote2D(&remoteRes,&hDev,1,physSize[1],physSize[0],dFormat,flags);
	else if(nLogicDims == 1)
		err = calResAllocRemote1D(&remoteRes,&hDev,1,physSize[0],dFormat,flags);

	if(err == CAL_RESULT_OK)
	{
		if(flags && CAL_RESALLOC_GLOBAL_BUFFER) 
			remoteIsGlobalBuf = TRUE; 
		else
			remoteIsGlobalBuf = FALSE;
	}
	else
		remoteRes = 0;

	return err;
}

void Array::FreeLocal(void)
{
	if(localRes)
	{
		calResFree(localRes); 
		localRes = 0; 		
	}
}

void Array::FreeRemote(void)
{
	if(remoteRes)
	{
		calResFree(remoteRes); 
		remoteRes = 0;
	}
}

CALresult Array::CopyRemoteToLocal(CALcontext ctx)
{	
	return Copy(ctx,localRes,remoteRes);
}

CALresult Array::CopyLocalToRemote(CALcontext ctx)
{	
	return Copy(ctx,remoteRes,localRes);
}

CALresult Array::FreeLocalKeepInRemote(CALcontext ctx)
{	
	CALresult err;

	err = CAL_RESULT_OK;
	
	// try to copy content from local to remote resource	
	if(remoteRes == 0) 
		err = AllocateRemote(0);

	if(err == CAL_RESULT_OK) 
	{
		err = CopyLocalToRemote(ctx);
		if(err != CAL_RESULT_OK) 
			FreeRemote();
		else
			FreeLocal();
	}				

	return err;
}

// set CPU data to the remote GPU memory
CALresult Array::SetDataToRemote(CALcontext ctx, void* cpuData)
{	
	CALuint pitch;
	long i, lSize, pSize;
	char* gpuPtr;
	char* cpuPtr;	

	err = CAL_RESULT_OK;
	
	_ASSERT(remoteRes);	
	
	cpuPtr = (char*)cpuData;

	err = calResMap((void**)&gpuPtr,&pitch,remoteRes,0);
	if(err != CAL_RESULT_OK) 
		return err;
	
	pitch *= physElemSize; // pitch in number of bytes

	if(nLogicDims == 2)
	{		
		lSize = logicSize[1]*elemSize;	// number of bytes in logical row
		pSize = physSize[1]*physElemSize;	// number of bytes in physical row

		if( (pSize == pitch) && (dataSize == physDataSize) )	
			CopyMemory(gpuPtr,cpuPtr,dataSize);	
		else
		{
			for(i = 0; i < logicSize[0]-1; i++)
			{
				CopyMemory(gpuPtr,cpuPtr,lSize);				
				ZeroMemory(gpuPtr+lSize,pSize-lSize);	// account padding
				gpuPtr += pitch;
				cpuPtr += lSize;
			}
			i = dataSize-(logicSize[0]-1)*lSize;
			CopyMemory(gpuPtr,cpuPtr,i);
			ZeroMemory(gpuPtr+i,physDataSize-dataSize);	// account padding
		}
	}
	else if(nLogicDims == 1)
	{
		CopyMemory(gpuPtr,cpuPtr,dataSize);
		ZeroMemory(gpuPtr+dataSize,physDataSize-dataSize);	// account padding
	}
	else
		err = CAL_RESULT_NOT_SUPPORTED;

	err = calResUnmap(remoteRes);

	return err;
}

CALresult Array::GetDataFromRemote(CALcontext ctx, void* cpuData)
{		
	CALuint pitch;
	long i, lSize, pSize;
	char* gpuPtr;
	char* cpuPtr;

	err = CAL_RESULT_OK;
	
	_ASSERT(remoteRes);	
	
	cpuPtr = (char*)cpuData;

	err = calResMap((void**)&gpuPtr,&pitch,remoteRes,0);
	if(err != CAL_RESULT_OK) 
		return err;
	
	pitch *= physElemSize; // pitch in number of bytes

	if(nLogicDims == 2)
	{
		lSize = logicSize[1]*elemSize;	// number of bytes in logical row
		pSize = physSize[1]*physElemSize;	// number of bytes in physical row

		if( (pSize == pitch) && (dataSize == physDataSize) )	
			CopyMemory(cpuPtr,gpuPtr,dataSize);	
		else
		{
			for(i = 0; i < logicSize[0]-1; i++)
			{
				CopyMemory(cpuPtr,gpuPtr,lSize);				
				gpuPtr += pitch;
				cpuPtr += lSize;
			}
			i = dataSize-(logicSize[0]-1)*lSize;
			CopyMemory(cpuPtr,gpuPtr,i);			
		}
	}
	else if(nLogicDims == 1)	
		CopyMemory(cpuPtr,gpuPtr,dataSize);	
	else
		err = CAL_RESULT_NOT_SUPPORTED;

	err = calResUnmap(remoteRes);

	return err;
}

CALresult Array::SetDataToLocal(CALcontext ctx, void* cpuData)
{	
	err = CAL_RESULT_OK;
	
	_ASSERT(localRes);

	if(remoteRes == 0) 
		err = AllocateRemote(0);
	if(err != CAL_RESULT_OK)			
		return err;	

	err = SetDataToRemote(ctx,cpuData);
	if(err == CAL_RESULT_OK) 
		err = CopyRemoteToLocal(ctx);

	FreeRemote();	

	return err;	
}

CALresult Array::GetDataFromLocal(CALcontext ctx, void* cpuData)
{	
	_ASSERT(localRes);

	err = CAL_RESULT_OK;

	if(remoteRes == 0) 
		err = AllocateRemote(0);
	if(err != CAL_RESULT_OK) 	
		return err;
	
	err = CopyLocalToRemote(ctx);
	if(err == CAL_RESULT_OK) 
		err = GetDataFromRemote(ctx,cpuData);	

	FreeRemote();

	return err;
}

ArrayExpression::ArrayExpression(long op, long dType, long nDims, long* size, long* transpDims)
{
	long i;

	args = new Array*[3];
	args[0] = NULL;
	args[1] = NULL;
	args[2] = NULL;
	
	this->transpDims = NULL;
	
	this->op = op;
	this->dType = dType;
	this->nDims = nDims;

	this->size = new long[nDims];
	for(i = 0; i < nDims; i++) this->size[i] = size[i];
	
	if(transpDims)
	{
		this->transpDims = new long[nDims];
		for(i = 0; i < nDims; i++) this->transpDims[i] = transpDims[i];	
	}
}


ArrayExpression::~ArrayExpression(void)
{
	if(args)
		delete args;

	if(size)
		delete size;

	if(transpDims)
		delete transpDims;
}

ArrayPool::ArrayPool(void)
{
	err = CAL_RESULT_OK;
}

ArrayPool::~ArrayPool(void)
{
	RemoveAll();
}

void ArrayPool::Remove(long ind)
{
	Array* arr = Get(ind);
	if(arr) 
		delete arr;

	ObjectPool::Remove(ind);
}

Array* ArrayPool::Get(long ind)
{
	return (Array*)ObjectPool::Get(ind);
}

long ArrayPool::Find(long arrID)
{
	long i;

	for(i = 0; (i < Length()) && ( Get(i)->arrID != arrID); i++);

	if(i < Length()) 
		return i; 
	else 
		return -1;
}

Array* ArrayPool::FindMaxLocalNotInUse(Exclude* excl)
{
	long i;
	Array* arg = NULL;
	Array* arg1 = NULL;	

	for(i = 0; i < Length(); i++)
	{
		arg1 = Get(i);
				
		if( (!arg1->useCounter) && (arg1->localRes) && ((!excl) || (!excl->In(arg1))) )
		{						
			if( (!arg) || (arg->dataSize < arg1->dataSize) ) 
				arg = arg1;			
		}
	}

	return arg;
}

long ArrayPool::FindMaxLocalNotInUse1(Exclude* excl)
{
	long i, ind;
	Array* arr = NULL;
	Array* arr1 = NULL;
			
	ind = -1;

	for(i = 0; i < Length(); i++)
	{
		arr1 = Get(i);

		if( (!arr1->useCounter) && (arr1->localRes) && ((!excl) || (!excl->In(arr1))) )
		{				
			if( (!arr) || (arr->dataSize < arr1->dataSize) )
			{
				ind = i;
				arr = arr1;
			}			
		}
	}

	return ind;
}

Array* ArrayPool::FindMinLocalNotInUse(Exclude* excl)
{
	long i;
	Array* arr = NULL;
	Array* arr1 = NULL;	

	for(i = 0; i < Length(); i++)
	{
		arr1 = Get(i);

		if( (!arr1->useCounter) && (arr1->localRes) && ((!excl) || (!excl->In(arr1))) )
		{			
			if( (!arr) || (arr->dataSize > arr1->dataSize) )
				arr = arr1;
		}
	}

	return arr;
}

long ArrayPool::FindMinLocalNotInUse1(Exclude* excl)
{
	long i, ind;
	Array* arr = NULL;
	Array* arr1 = NULL;
			
	ind = -1;

	for(i = 0; i < Length(); i++)
	{
		arr1 = Get(i);

		if( (!arr1->useCounter) && (arr1->localRes) && ((!excl) || (!excl->In(arr1))) )
		{			
			if( (!arr) || (arr->dataSize > arr1->dataSize) )
			{
				ind = i;
				arr = arr1;
			}
		}
	}

	return ind;
}




// copy data from one resource to another
CALresult Array::Copy(CALcontext ctx, CALresource dstRes, CALresource srcRes)
{
	CALmem srcMem, dstMem;
	CALevent ev;

	_ASSERT(srcRes);
	_ASSERT(dstRes);

	err = calCtxGetMem(&dstMem,ctx,dstRes);
	if(err != CAL_RESULT_OK) 
		return err;

	err = calCtxGetMem(&srcMem,ctx,srcRes);
	if(err != CAL_RESULT_OK)
	{
		calCtxReleaseMem(ctx,dstMem);
		return err;
	}

	err = calMemCopy(&ev,ctx,srcMem,dstMem,0);
	if(err != CAL_RESULT_OK) 
	{
		calCtxReleaseMem(ctx,srcMem);
		calCtxReleaseMem(ctx,dstMem);	
		return err;
	}

	while(calCtxIsEventDone(ctx,ev) == CAL_RESULT_PENDING);

	calCtxReleaseMem(ctx,srcMem);
	calCtxReleaseMem(ctx,dstMem);

	return err;
}

// get named local memory handle for given context
CALresult Array::GetNamedLocalMem(CALcontext ctx, CALname name, CALmem* mem)
{		
	_ASSERT(localRes);

	err = calCtxGetMem(mem,ctx,localRes);
	if(err != CAL_RESULT_OK)	
	{
		*mem = 0;
		return err;	
	}
	err = calCtxSetMem(ctx,name,*mem);
	if(err != CAL_RESULT_OK) 	
	{
		calCtxReleaseMem(ctx,*mem);	
		*mem = 0;
	}

	return err;
}

// returns TRUE if array is scalar and equal to zero
BOOL Array::IsZeroScalar(void)
{	
	if(cpuData && IsScalar())
	{
		switch(dType)
		{
			case TSHORTINT: return *((char*)cpuData) == 0;			
			case TINTEGER:	return *((short*)cpuData) == 0;
			case TLONGINT:	return *((long*)cpuData) == 0;
			case TREAL:		return *((float*)cpuData) == 0;
			case TLONGREAL:	return *((double*)cpuData) == 0;
			default:
				return FALSE;
		}
	}
	else
		return FALSE;
}

// returns TRUE if array is a scalar
BOOL Array::IsScalar(void)
{
	return (dataSize == elemSize);
}
