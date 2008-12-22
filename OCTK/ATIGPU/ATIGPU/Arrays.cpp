#include "StdAfx.h"
#include "Arrays.h"
#include "Common.h"

Array::Array(CALdevice hDev, CALdeviceinfo* devInfo, CALdeviceattribs* devAttribs, long arrID, long dType, long nDims, long* size)
{	
	long i;	
	
	res = 0;
	numParts = 0;	
	useCounter = 0;

	cpuData = NULL;
	parts = NULL;

	isReservedForGet = FALSE;
	isVirtualized = FALSE;
	isGlobalBuf = FALSE;

	this->hDev = hDev;
	this->arrID = arrID;		
	this->dType = dType;
	this->devInfo = devInfo;
	this->devAttribs = devAttribs;

	physNumComponents = 4;	// use quads for efficient memory accesses
	if(dType == TLONGREAL)
		physNumComponents = min(physNumComponents,2);	
	
	// copy array size and count total number of elements
	this->nDims = nDims;	
	this->size = new long[nDims]; 	
	numElements = 1;
	for(i = 0; i < nDims; i++)
	{
		this->size[i] = size[i];
		numElements *= size[i];
	}

	// total data size in bytes
	elemSize = GetElementSize(dType);	
	dataSize = numElements*elemSize;			

	// does it require virtualization?
	if( ((nDims == 1) && (GetPaddedNumElements(size[0],physNumComponents) <= (long)devInfo->maxResource1DWidth)) 
		|| ((nDims == 2) && (GetPaddedNumElements(size[1],physNumComponents) <= (long)devInfo->maxResource2DWidth) && (size[0] <= (long)devInfo->maxResource2DHeight) ) )
	{
		if( (nDims == 2) && (size[0] > 1) )
		{			
			physSize[0] = size[0];
			physSize[1] = GetPaddedNumElements(size[1],physNumComponents);

			// padding of matrix height for convenient handling with matrix multiplication
			if(physSize[0] <= 4)
				physSize[0] = 4;	// padding to multiple of 4
			else
				physSize[0] = 8*GetPaddedNumElements(physSize[0],8);	// padding to multiple of 8	
		}
		else
		{
			physSize[0] = 1;
			if(nDims == 1)
				physSize[1] = GetPaddedNumElements(size[0],physNumComponents);
			else // matrix with a single row, -> vector
			{
				physSize[1] = GetPaddedNumElements(size[1],physNumComponents);
				this->nDims = 1;
			}
		}		
		
		// compute pitch in physical elements
		physPitch = (physSize[1]/devAttribs->pitch_alignment)*devAttribs->pitch_alignment;
		if(physSize[1] % devAttribs->pitch_alignment) physPitch += devAttribs->pitch_alignment;		
	}
	else	// virtualization is required -> represent array in tiled memory layout
	{
		isVirtualized = TRUE;		

		physNumComponents = 1;	// this is for more convenient memory access
		
		physSize[1] = min(numElements,devInfo->maxResource2DWidth);		
		physSize[0] = GetPaddedNumElements(numElements,physSize[1]);

		physPitch = devInfo->maxResource2DWidth;		
	}	

	// format and size of a physical element
	dFormat = GetFormat(dType,physNumComponents);
	physElemSize = elemSize*physNumComponents;

	// total number of physical elements and total physical data size in bytes
	physNumElements = physSize[0]*physSize[1];
	physDataSize = physNumElements*physElemSize;	
}


Array::~Array(void)
{
	if(size)
		delete size;

	if(parts)
	{
		for(; numParts > 0; numParts--)
			delete parts[numParts-1];

		delete parts;
	}

	Free();
}

// free array resource
void Array::Free(void)
{
	if(res)
	{
		calResFree(res);
		res = 0;
	}	
}


ArrayPool::ArrayPool(void)
{
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

	for(i = 0; (i < nObjs) && ( Get(i)->arrID != arrID); i++);

	if(i < nObjs) 
		return i; 
	else 
		return -1;
}

ArrayExpression::ArrayExpression(long op, long dType, long nDims, long* size, long* transpDims)
{
	long i;
	
	args[0] = NULL;
	args[1] = NULL;
	args[2] = NULL;
	
	this->transpDims = NULL;
	this->size = NULL;
	
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
	if(size)
		delete size;

	if(transpDims)
		delete transpDims;
}


// allocate array resource
CALresult Array::Allocate(CALuint flags)
{
	CALresult err;

	_ASSERT(!res);
	
	err = calResAllocLocal2D(&res,hDev,physSize[1],physSize[0],dFormat,flags);
	
	if(err == CAL_RESULT_WARNING)	// account warnings
		err = CAL_RESULT_OK;

	if(err == CAL_RESULT_OK)
	{		
		if(flags && CAL_RESALLOC_GLOBAL_BUFFER) 
			isGlobalBuf = TRUE;
		else
			isGlobalBuf = FALSE;
	}
	else
		res = 0;


	return err;
}

// copy data from one resource to another
CALresult Array::Copy(CALcontext ctx, CALresource dstRes, CALresource srcRes)
{
	CALresult err;
	CALmem srcMem, dstMem;
	CALevent ev;	

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

// sets data to GPU memory
CALresult Array::SetData(CALcontext ctx, void* cpuData)
{
	CALresult err;
	CALresource remoteRes;
	long i;	

	if(res)
	{		
		// first copy data to the remote memory,  then to the local using DMA
		err = calResAllocRemote2D(&remoteRes,&hDev,1,physSize[1],physSize[0],dFormat,0);
		if(err == CAL_RESULT_OK)
		{
			if( (err = SetDataToRes(remoteRes,cpuData)) == CAL_RESULT_OK )		
				err = Copy(ctx,res,remoteRes);

			calResFree(remoteRes);
		}
	}
	else if(parts)
	{		
		err = calResAllocRemote2D(&remoteRes,&hDev,1,parts[0]->physSize[1],parts[0]->physSize[0],dFormat,0);
		if(err == CAL_RESULT_OK)
		{
			for(i = 0; (i < numParts) && (err == CAL_RESULT_OK); i++)
			{
				if( (err = SetDataPartToRes(remoteRes,cpuData,i)) == CAL_RESULT_OK)
					err = Copy(ctx,parts[i]->res,remoteRes);
			}

			calResFree(remoteRes);
		}		
	}
	else
		err = CAL_RESULT_ERROR;

	return err;
}

// gets data from GPU memory
CALresult Array::GetData(CALcontext ctx, void* cpuData)
{
	CALresult err;
	CALresource remoteRes;
	long i;
	
	if(res)
	{		
		// first copy data to the remote memory,  then to the local using DMA
		err = calResAllocRemote2D(&remoteRes,&hDev,1,physSize[1],physSize[0],dFormat,0);
		if(err == CAL_RESULT_OK)
		{
			if( (err = Copy(ctx,remoteRes,res)) == CAL_RESULT_OK )										
				err = GetDataFromRes(remoteRes,cpuData);		
			
			calResFree(remoteRes);
		}		
	}	
	else if(parts)
	{
		err = calResAllocRemote2D(&remoteRes,&hDev,1,parts[0]->physSize[1],parts[0]->physSize[0],dFormat,0);
		if(err == CAL_RESULT_OK)
		{
			for(i = 0; (i < numParts) && (err == CAL_RESULT_OK); i++)
			{
				if( (err = Copy(ctx,remoteRes,parts[i]->res)) == CAL_RESULT_OK )
					err = GetDataPartFromRes(remoteRes,cpuData,i);				
			}

			calResFree(remoteRes);
		}
	}
	else
		err = CAL_RESULT_ERROR;

	return err;
}

// Set data to a resource
CALresult Array::SetDataToRes(CALresource res, void* cpuData)
{
	CALresult err;
	CALuint gpuPitch;
	long i, numCpuPitch, cpuPitch, pSize;
	char* gpuPtr;
	char* cpuPtr;

	cpuPtr = (char*)cpuData;

	err = calResMap((void**)&gpuPtr,&gpuPitch,res,0);
	if(err != CAL_RESULT_OK) 
		return err;

	gpuPitch *= physElemSize; // pitch in number of bytes

	if( (nDims == 1) && !isVirtualized )
	{
		CopyMemory(gpuPtr,cpuPtr,dataSize);
		ZeroMemory(gpuPtr+dataSize,physDataSize-dataSize);	// account padding
	}
	else
	{			
		if(!isVirtualized)
		{
			cpuPitch = size[1];
			numCpuPitch = size[0];			
		}
		else
		{			
			cpuPitch = physSize[1];
			numCpuPitch = physSize[0]; // integer number of CPU pitches
		}
		
		cpuPitch *= elemSize;
		pSize = physSize[1]*physElemSize;	// number of bytes in physical row		

		if( (pSize == gpuPitch) && (dataSize == physDataSize) )	
			CopyMemory(gpuPtr,cpuPtr,dataSize);	
		else
		{			
			for(i = 0; i < numCpuPitch-1; i++)
			{
				CopyMemory(gpuPtr,cpuPtr,cpuPitch);				
				ZeroMemory(gpuPtr+cpuPitch,pSize-cpuPitch);	// account padding
				gpuPtr += gpuPitch;
				cpuPtr += cpuPitch;
			}
			i = dataSize-(numCpuPitch-1)*cpuPitch;			
			CopyMemory(gpuPtr,cpuPtr,i);			
			ZeroMemory(gpuPtr+i,physSize[0]*gpuPitch-(numCpuPitch-1)*gpuPitch-i);	// account padding
		}
		
	}		

	err = calResUnmap(res);	

	return err;
}

// Set data part to a resource
CALresult Array::SetDataPartToRes(CALresource res, void* cpuData, long iPart)
{
	CALresult err;
	CALuint gpuPitch;
	long i, numCpuPitch, cpuPitch, pSize;
	char* gpuPtr;
	char* cpuPtr;	

	cpuPtr = (char*)cpuData;

	err = calResMap((void**)&gpuPtr,&gpuPitch,res,0);
	if(err != CAL_RESULT_OK) 
		return err;

	gpuPitch *= physElemSize;		// gpu pitch in number of bytes
	cpuPitch = size[1]*elemSize;	// cpu pitch in number of bytes

	cpuPtr += iPart*cpuPitch;

	pSize = parts[iPart]->physSize[1]*physElemSize;	// number of bytes in physical row
	
	numCpuPitch = size[0]/numParts;
	if(size[0]-numCpuPitch*numParts >= iPart+1) numCpuPitch++;
	for(i = 0; i < numCpuPitch; i++)
	{
		CopyMemory(gpuPtr,cpuPtr,cpuPitch);
		ZeroMemory(gpuPtr+cpuPitch,pSize-cpuPitch);	// account padding

		gpuPtr += gpuPitch;
		cpuPtr += cpuPitch*numParts;
	}
	ZeroMemory(gpuPtr,parts[iPart]->physSize[0]*gpuPitch-numCpuPitch*gpuPitch);	// account padding

	err = calResUnmap(res);	

	return err;
}

// Get data part from a resource
CALresult Array::GetDataPartFromRes(CALresource res, void* cpuData, long iPart)
{
	CALresult err;
	CALuint gpuPitch;
	long i, numCpuPitch, cpuPitch, pSize;
	char* gpuPtr;
	char* cpuPtr;	

	cpuPtr = (char*)cpuData;

	err = calResMap((void**)&gpuPtr,&gpuPitch,res,0);
	if(err != CAL_RESULT_OK) 
		return err;

	gpuPitch *= physElemSize;		// gpu pitch in number of bytes
	cpuPitch = size[1]*elemSize;	// cpu pitch in number of bytes

	cpuPtr += iPart*cpuPitch;

	pSize = parts[iPart]->physSize[1]*physElemSize;	// number of bytes in physical row
	
	numCpuPitch = size[0]/numParts;
	if(size[0]-numCpuPitch*numParts >= iPart+1) numCpuPitch++;
	for(i = 0; i < numCpuPitch; i++)
	{
		CopyMemory(cpuPtr,gpuPtr,cpuPitch);		

		gpuPtr += gpuPitch;
		cpuPtr += cpuPitch*numParts;
	}	

	err = calResUnmap(res);	

	return err;
}


CALresult Array::GetDataFromRes(CALresource res, void* cpuData)
{
	CALresult err;
	CALuint gpuPitch;
	long i, numCpuPitch, cpuPitch, pSize;
	char* gpuPtr;
	char* cpuPtr;	

	cpuPtr = (char*)cpuData;

	err = calResMap((void**)&gpuPtr,&gpuPitch,res,0);
	if(err != CAL_RESULT_OK) 
		return err;

	float* gpuPtr0 = (float*)gpuPtr;

	gpuPitch *= physElemSize; // pitch in number of bytes

	if( (nDims == 1) && !isVirtualized )	
		CopyMemory(cpuPtr,gpuPtr,dataSize);	
	else
	{			
		if(!isVirtualized)
		{
			cpuPitch = size[1];
			numCpuPitch = size[0];			
		}
		else
		{			
			cpuPitch = physSize[1];
			numCpuPitch = physSize[0]; // integer number of CPU pitches
		}
		
		cpuPitch *= elemSize;
		pSize = physSize[1]*physElemSize;	// number of bytes in physical row		

		if( (pSize == gpuPitch) && (dataSize == physDataSize) )	
			CopyMemory(cpuPtr,gpuPtr,dataSize);
		else
		{			
			for(i = 0; i < numCpuPitch-1; i++)
			{
				CopyMemory(cpuPtr,gpuPtr,cpuPitch);				
				gpuPtr += gpuPitch;
				cpuPtr += cpuPitch;
			}
			i = dataSize-(numCpuPitch-1)*cpuPitch;			
			CopyMemory(cpuPtr,gpuPtr,i);			
		}
		
	}		

	err = calResUnmap(res);

	return err;
}

// get named local memory handle for given context
CALresult Array::GetNamedLocalMem(CALcontext ctx, CALname name, CALmem* mem)
{		
	CALresult err;

	_ASSERT(res);

	err = calCtxGetMem(mem,ctx,res);
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

/* allocate an array */
CALresult ArrayPool::AllocateArray(Array* arr, CALuint flags)
{
	CALresult err;

	err = arr->Allocate(flags);

	// FIXME: provide flexible way of allocating with possible freeing (or moving to remote memory) of unused arrays

	return err;
}

// allocated a matrix splitted in given number of parts parts
CALresult ArrayPool::AllocateSplittedMatrix(Array* arr, long numParts, CALuint flags)
{
	CALresult err;
	long i, size[2];	

	_ASSERT(arr->nDims == 2);
	_ASSERT(!arr->parts);

	err = CAL_RESULT_OK;	
	
	size[0] = GetPaddedNumElements(arr->size[0],numParts);	// padding to multiple of numParts
	if(size[0] > 0)
	{
		size[1] = arr->size[1];
		
		arr->parts = new Array*[numParts];
		for(i = 0; i < numParts; i++)
			arr->parts[i] = new Array(arr->hDev,arr->devInfo,arr->devAttribs,arr->arrID,arr->dType,2,&size[0]);

		for(i = 0; (i < numParts) && (err == CAL_RESULT_OK); i++)
			err = AllocateArray(arr->parts[i],flags);

		if(err == CAL_RESULT_OK)
			arr->numParts = numParts;
		else
		{
			for(i = 0; i < numParts; i++)
				delete arr->parts[i];

			delete arr->parts;
			arr->parts = NULL;
		}
	}
	else
		return CAL_RESULT_INVALID_PARAMETER;

	return err;
}
