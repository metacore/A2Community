#include "StdAfx.h"
#include "Constant.h"
#include "Common.h"

Constant::Constant(Module* module, long ind, long dType, long size, long numComponents)
{
	this->dType = dType;
	this->size = size;
	this->numComponents = numComponents;

	dFormat = GetFormat(dType,numComponents);

	ctx = module->ctx;

	// allocate the constant
	err = calResAllocLocal1D(&res,module->hDev,size,dFormat,0);
	if(err != CAL_RESULT_OK)	
	{
		res = 0;	
		return;
	}
	
	// get memory handle
	err = calCtxGetMem(&mem,ctx,res);
	if(err != CAL_RESULT_OK)	
	{
		calResFree(res);
		res = 0;
		mem = 0;
		return;	
	}

	err = calCtxSetMem(ctx,module->constNames[ind],mem);
	if(err != CAL_RESULT_OK) 	
	{
		calCtxReleaseMem(ctx,mem);	
		calResFree(res);
		res = 0;
		mem = 0;
		return;		
	}
	
	dataSize = size*numComponents*GetElementSize(dType);
}

Constant::~Constant(void)
{
	if(mem)
		calCtxReleaseMem(ctx,mem);

	if(res)
		calResFree(res);
}

CALresult Constant::Set(void* data)
{
	void* gpuPtr;
	CALuint pitch;

	err = calResMap((void**)&gpuPtr,&pitch,res,0);
	if(err != CAL_RESULT_OK) return err;	
	CopyMemory(gpuPtr,data,dataSize);
	err = calResUnmap(res);

	return err;
}

CALresult Constant::Fill(void* pattern, long patternSize)
{
	char* gpuPtr;
	CALuint pitch;
	long i;

	if(patternSize <= dataSize)
	{
		err = calResMap((void**)&gpuPtr,&pitch,res,0);
		if(err != CAL_RESULT_OK) return err;	
		for(i = 0; i < dataSize; i+=patternSize)		
			CopyMemory(gpuPtr+i,pattern,patternSize);			

		err = calResUnmap(res);
	}
	else
		return CAL_RESULT_INVALID_PARAMETER;

	return err;
}