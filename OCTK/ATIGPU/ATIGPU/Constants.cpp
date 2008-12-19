#include "StdAfx.h"
#include "Constants.h"
#include "Common.h"

Constant::Constant(CALdevice hDev, CALcontext ctx, CALname name, CALformat dFormat, long size, CALresult* err)
{	
	this->ctx = ctx;
	this->name = name;
	this->dFormat = dFormat;
	this->size = size;	
	

	// allocate the constant
	*err = calResAllocRemote1D(&res,&hDev,1,size,dFormat,0);
	if(*err != CAL_RESULT_OK)
	{		
		res = 0;	
		return;
	}
	
	dataSize = size*GetElementSize1(dFormat);
}

Constant::~Constant(void)
{
	if(mem)
		calCtxReleaseMem(ctx,mem);

	if(res)
		calResFree(res);	
}

CALresult Constant::SetData(void* data)
{	
	CALresult err;
	void* gpuPtr;
	CALuint pitch;

	err = calResMap((void**)&gpuPtr,&pitch,res,0);
	if(err == CAL_RESULT_OK)
	{
		CopyMemory(gpuPtr,data,dataSize);
		err = calResUnmap(res);
	}

	return err;
}

CALresult Constant::Fill(void* pattern, long patternSize)
{
	CALresult err;
	char* gpuPtr;
	CALuint pitch;
	long i;

	if(patternSize <= dataSize)
	{
		err = calResMap((void**)&gpuPtr,&pitch,res,0);
		if(err == CAL_RESULT_OK)
		{
			for(i = 0; i < dataSize; i+=patternSize)		
				CopyMemory(gpuPtr+i,pattern,patternSize);

			err = calResUnmap(res);
		}
	}
	else
		return CAL_RESULT_INVALID_PARAMETER;

	return err;
}

// set constant memory to the context
CALresult Constant::SetToContext(void)
{
	CALresult err;

	// get memory handle
	err = calCtxGetMem(&mem,ctx,res);
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
