#include "StdAfx.h"
#include "Constants.h"
#include "Common.h"

Constant::Constant(CALdevice hDev, CALcontext ctx, CALname name, CALformat dFormat, long size)
{	
	this->ctx = ctx;
	this->name = name;
	this->dFormat = dFormat;
	this->size = size;	
	

	// allocate the constant
	err = calResAllocLocal1D(&localRes,hDev,size,dFormat,0);
	if(err != CAL_RESULT_OK)	
	{
		localRes = 0;	
		return;
	}	

	err = calResAllocRemote1D(&remoteRes,&hDev,1,size,dFormat,0);
	if(err != CAL_RESULT_OK)	
	{
		calResFree(localRes);
		localRes = 0;
		remoteRes = 0;	
		return;
	}
	
	dataSize = size*GetElementSize(dFormat);
}

Constant::~Constant(void)
{
	if(mem)
		calCtxReleaseMem(ctx,mem);

	if(localRes)
		calResFree(localRes);

	if(remoteRes)
		calResFree(remoteRes);
}

CALresult Constant::SetData(void* data)
{
	void* gpuPtr;
	CALuint pitch;
	CALmem srcMem, dstMem;
	CALevent ev;		

	err = calResMap((void**)&gpuPtr,&pitch,remoteRes,0);
	if(err == CAL_RESULT_OK)
	{
		CopyMemory(gpuPtr,data,dataSize);
		err = calResUnmap(remoteRes);
		if(err == CAL_RESULT_OK)
		{
			err = calCtxGetMem(&dstMem,ctx,localRes);
			if(err == CAL_RESULT_OK)
			{
				err = calCtxGetMem(&srcMem,ctx,remoteRes);
				if(err == CAL_RESULT_OK)
				{
					err = calMemCopy(&ev,ctx,srcMem,dstMem,0);	
					if(err == CAL_RESULT_OK)
						while(calCtxIsEventDone(ctx,ev) == CAL_RESULT_PENDING);

					calCtxReleaseMem(ctx,srcMem);
					calCtxReleaseMem(ctx,dstMem);
				}
				else
					calCtxReleaseMem(ctx,dstMem);
			}
		}
	}
/*
	// this is easier but 1.5 times slower

	void* gpuPtr;
	CALuint pitch;	
	err = calResMap((void**)&gpuPtr,&pitch,localRes,0);
	if(err != CAL_RESULT_OK) return err;	
	CopyMemory(gpuPtr,data,dataSize);
	err = calResUnmap(localRes);
*/
	return err;
}

CALresult Constant::Fill(void* pattern, long patternSize)
{
	char* gpuPtr;
	CALuint pitch;
	long i;

	if(patternSize <= dataSize)
	{
		err = calResMap((void**)&gpuPtr,&pitch,localRes,0);
		if(err != CAL_RESULT_OK) return err;	
		for(i = 0; i < dataSize; i+=patternSize)		
			CopyMemory(gpuPtr+i,pattern,patternSize);			

		err = calResUnmap(localRes);
	}
	else
		return CAL_RESULT_INVALID_PARAMETER;

	return err;
}
// set constant memory to the context
CALresult Constant::SetToContext(void)
{
	// get memory handle
	err = calCtxGetMem(&mem,ctx,localRes);
	if(err == CAL_RESULT_OK)	
	{
		// set memory to the context
		err = calCtxSetMem(ctx,name,mem);
		if(err != CAL_RESULT_OK)
		{
			calCtxReleaseMem(ctx,mem); 
			mem = 0;
		}
	}
	else	
		mem = 0;

	return err;
}

// release constant memory from the context
void Constant::ReleaseFromContext(void)
{
	if(mem)
	{
		calCtxReleaseMem(ctx,mem); 
		mem = 0;
	}
}
