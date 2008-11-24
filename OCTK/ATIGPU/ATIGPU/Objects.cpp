#include <stdafx.h>
#include "Objects.h"
#include "kernels.h"

// Conversion from ArrayObjects data type to GPU data format
long GetFormat(long dType)
{
	switch(dType)
	{
		case TSHORTINT: 
			return CAL_FORMAT_BYTE_1;
		case TINTEGER: 
			return CAL_FORMAT_SHORT_1;
		case TLONGINT: 
			return CAL_FORMAT_INT_1;		
		case TREAL: 
			return CAL_FORMAT_FLOAT_1;

		case TLONGREAL: 
			return CAL_FORMAT_DOUBLE_1;
		default: 
			return -1;
	}	
}

// Get element size for a given data format
long GetElementSize(CALformat dFormat)
{
	switch(dFormat)
	{
		case CAL_FORMAT_BYTE_1: 
			return 1;
		case CAL_FORMAT_SHORT_1: 
			return 2;
		case CAL_FORMAT_INT_1: 
			return 4;		
		case CAL_FORMAT_FLOAT_1: 
			return 4;
		case CAL_FORMAT_DOUBLE_1: 
			return 8;		
		default: 
			return 0;
	}	
}


ObjectPool::ObjectPool(void)
{	
	objs = NULL;
	nObjs = 0;	

	InitializeCriticalSection(&cs);
}

ObjectPool::~ObjectPool(void)
{		
	RemoveAll();	

	DeleteCriticalSection(&cs);
}

long ObjectPool::Length()
{
	return nObjs;
}

void* ObjectPool::Get(long ind)
{
	void* obj = NULL;
	
	if( (ind >= 0) && (ind < nObjs) ) 
		obj = objs[ind];

	return obj;
}

void* ObjectPool::GetLast(void)
{
	if(nObjs) 
		return objs[nObjs-1];
	else 
		return NULL;
}

void ObjectPool::Add(void* obj)
{	
	if(objs == NULL) 
		objs = (void**)malloc((nObjs+1)*sizeof(void*));	
	else 
		objs = (void**)realloc(&objs[0],(nObjs+1)*sizeof(void*));

	objs[nObjs] = obj;
	nObjs++;	
}

void ObjectPool::Remove(long ind)
{
	long i;
	
	if( (ind >= 0) && (ind < nObjs) )
	{		
		if(nObjs > 1)
		{
			for(i = ind; i < nObjs-1; i++) 
				objs[i] = objs[i+1];
			objs = (void**)realloc(&objs[0],(nObjs-1)*sizeof(void*));
			nObjs--;	
		}
		else
		{
			free(objs);
			objs = NULL;
			nObjs = 0;
		}
	}
}

void ObjectPool::RemoveAll(void)
{
	while(Length()) Remove(0);
}

long ObjectPool::Find(void* obj)
{
	long i;
	for(i = 0; (i < nObjs) && (objs[i] != obj); i++);
	if(i < nObjs) 
		return i; 
	else 
		return -1;
}


/*
	Argument
*/

// returns nearest number which is multiple of 4
long PaddedToMultipleOf4(long val)
{
	long k = val/4;
	
	if(k*4 >= val)
		return k*4;
	else
		return (k+1)*4;
}

Argument::Argument(CALdevice hDev, CALdeviceinfo* devInfo, long argID, CALformat dFormat, long nDims, long* size, void* data)
{
	long i;	

	this->hDev = hDev;	
	this->argID = argID;		
	this->dFormat = dFormat;
	this->nDims = nDims;

	isVirtualized = FALSE;		

	this->size = new long[nDims]; 
	// total data size in bytes
	dataSize = GetElementSize(dFormat);
	for(i = 0; i < nDims; i++)
	{
		this->size[i] = size[i];
		dataSize *= size[i];
	}	

	// does it fit to hardware memory layout requirements?
	if( ((nDims == 1) && (size[0] <= (long)devInfo->maxResource1DWidth)) 
		|| ((nDims == 2) && (size[1] <= (long)devInfo->maxResource2DWidth) && (size[0] <= (long)devInfo->maxResource2DHeight) ) )
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
		
		i = dataSize / GetElementSize(dFormat);
		logicSize[0] = i / logicSize[1];
		if(logicSize[0]*logicSize[1] < i)
			logicSize[0]++;

		physSize = new long[2];
		physSize[0] = logicSize[0];
		physSize[1] = PaddedToMultipleOf4(logicSize[1]);
		
		isVirtualized = TRUE;
	}	
	
	// physical size -> account padding to multiple of 4
	physSize = new long[nLogicDims];
	physSize[0] = logicSize[0];
	if(nLogicDims == 1)
		physSize[0] = PaddedToMultipleOf4(physSize[0]);
	else if(nLogicDims == 2)
		physSize[1] = PaddedToMultipleOf4(logicSize[1]);

	// logic and physical data size in bytes
	logicDataSize = GetElementSize(dFormat);
	physDataSize = logicDataSize;
	for(i = 0; i < nLogicDims; i++)
	{
		logicDataSize *= logicSize[i];
		physDataSize *= physSize[i];
	}
	
	cpuData = data;
	remoteRes = 0;
	localRes = 0;

	useCounter = 0;
	isReservedForGet = FALSE;
	isModified = FALSE;
}

Argument::~Argument(void)
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

CALresult Argument::AllocateLocal(CALuint flags)
{
	CALresult err = CAL_RESULT_NOT_SUPPORTED;

	FreeLocal();
	
	if(nLogicDims == 2)
		err = calResAllocLocal2D(&localRes,hDev,physSize[1],physSize[0],dFormat,flags);
	else if(nLogicDims == 1)
		err = calResAllocLocal1D(&localRes,hDev,physSize[0],dFormat,flags);

	if(err != CAL_RESULT_OK) localRes = 0;
	
	return err;
}

CALresult Argument::AllocateRemote(CALuint flags)
{
	CALresult err = CAL_RESULT_NOT_SUPPORTED;	

	FreeRemote();
	
	if(nLogicDims == 2)
		err = calResAllocRemote2D(&remoteRes,&hDev,1,physSize[1],physSize[0],dFormat,flags);
	else if(nLogicDims == 1)
		err = calResAllocRemote1D(&remoteRes,&hDev,1,physSize[0],dFormat,flags);

	if(err != CAL_RESULT_OK) remoteRes = 0;

	return err;
}

void Argument::FreeLocal(void)
{
	if(localRes)
	{
		calResFree(localRes); 
		localRes = 0; 		
	}
}

void Argument::FreeRemote(void)
{
	if(remoteRes)
	{
		calResFree(remoteRes); 
		remoteRes = 0;
	}
}

CALresult Argument::FreeLocalKeepInRemote(CALcontext ctx)
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

CALresult Argument::SetDataToLocal(CALcontext ctx)
{
	CALresult err;		

	err = CAL_RESULT_OK;
	
	if(localRes == 0) 
		err = AllocateLocal(0);
	if(err != CAL_RESULT_OK) 
		return err;

	if(remoteRes == 0) 
		err = AllocateRemote(0);
	if(err != CAL_RESULT_OK)			
		return err;	

	err = SetDataToRemote(ctx);
	if(err == CAL_RESULT_OK) 
		err = CopyRemoteToLocal(ctx);

	FreeRemote();	

	return err;	
}

CALresult Argument::SetDataToRemote(CALcontext ctx)
{
	CALresult err;
	CALuint pitch;
	long i, elemSize, lSize, pSize;
	char* gpuPtr;
	char* cpuPtr;

	err = CAL_RESULT_OK;
	
	if(remoteRes == 0) 
		err = AllocateRemote(0);

	if(err != CAL_RESULT_OK) 
		return err;
	
	cpuPtr = (char*)cpuData;

	err = calResMap((void**)&gpuPtr,&pitch,remoteRes,0);
	if(err != CAL_RESULT_OK) 
		return err;

	elemSize = GetElementSize(dFormat);
	pitch *= elemSize; // pitch in number of bytes

	if(nLogicDims == 2)
	{		
		lSize = logicSize[1]*elemSize;	// number of bytes in logical row
		pSize = physSize[1]*elemSize;	// number of bytes in physical row

		if( (lSize == pitch) && (dataSize == physDataSize) )	
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

CALresult Argument::GetDataFromLocal(CALcontext ctx)
{
	CALresult err;

	_ASSERT(localRes != 0);

	err = CAL_RESULT_OK;

	if(remoteRes == 0) 
		err = AllocateRemote(0);
	if(err != CAL_RESULT_OK) 	
		return err;
	
	err = CopyLocalToRemote(ctx);
	if(err == CAL_RESULT_OK) 
		err = GetDataFromRemote(ctx);	

	FreeRemote();

	return err;
}

CALresult Argument::GetDataFromRemote(CALcontext ctx)
{	
	CALresult err;
	CALuint pitch;
	long i, elemSize, lSize, pSize;
	char* gpuPtr;
	char* cpuPtr;

	err = CAL_RESULT_OK;
	
	if(remoteRes == 0) 
		err = AllocateRemote(0);

	if(err != CAL_RESULT_OK) 
		return err;
	
	cpuPtr = (char*)cpuData;

	err = calResMap((void**)&gpuPtr,&pitch,remoteRes,0);
	if(err != CAL_RESULT_OK) 
		return err;

	elemSize = GetElementSize(dFormat);
	pitch *= elemSize; // pitch in number of bytes

	if(nLogicDims == 2)
	{
		lSize = logicSize[1]*elemSize;	// number of bytes in logical row
		pSize = physSize[1]*elemSize;	// number of bytes in physical row

		if( (lSize == pitch) && (dataSize == physDataSize) )	
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

CALresult Argument::CopyRemoteToLocal(CALcontext ctx)
{
	CALresult err;
	CALmem localMem, remoteMem;
	CALevent ev;

	_ASSERT(localRes);
	_ASSERT(remoteRes);

	err = calCtxGetMem(&remoteMem,ctx,remoteRes);
	if(err != CAL_RESULT_OK) 
		return err;

	err = calCtxGetMem(&localMem,ctx,localRes);
	if(err != CAL_RESULT_OK)
	{
		calCtxReleaseMem(ctx,remoteMem);
		return err;
	}

	err = calMemCopy(&ev,ctx,remoteMem,localMem,0);
	if(err != CAL_RESULT_OK) 
	{
		calCtxReleaseMem(ctx,localMem);
		calCtxReleaseMem(ctx,remoteMem);	
		return err;
	}

	while(calCtxIsEventDone(ctx,ev) == CAL_RESULT_PENDING);

	calCtxReleaseMem(ctx,localMem);
	calCtxReleaseMem(ctx,remoteMem);

	return err;
}

CALresult Argument::CopyLocalToRemote(CALcontext ctx)
{
	CALresult err;
	CALmem localMem, remoteMem;
	CALevent ev;

	_ASSERT(localRes);
	_ASSERT(remoteRes);

	err = calCtxGetMem(&remoteMem,ctx,remoteRes);
	if(err != CAL_RESULT_OK) 
		return err;

	err = calCtxGetMem(&localMem,ctx,localRes);
	if(err != CAL_RESULT_OK)
	{
		calCtxReleaseMem(ctx,remoteMem);
		return err;
	}

	err = calMemCopy(&ev,ctx,localMem,remoteMem,0);
	if(err != CAL_RESULT_OK) 
	{
		calCtxReleaseMem(ctx,localMem);
		calCtxReleaseMem(ctx,remoteMem);	
		return err;
	}

	while(calCtxIsEventDone(ctx,ev) == CAL_RESULT_PENDING);

	calCtxReleaseMem(ctx,localMem);
	calCtxReleaseMem(ctx,remoteMem);

	return err;
}


/*
	Kernel
*/

Kernel::Kernel(long iKernel, CALtarget target)
{	
	obj = NULL;
	img = NULL;	

	CALresult err;		

	const char* kernelStr = NULL;

	switch(iKernel)
	{
		case KernAdd1DR: kernelStr = kernelAdd1DR; break;
		case KernAdd2DR: kernelStr = kernelAdd2DR; break;
		case KernSub1DR: kernelStr = kernelSub1DR; break;
		case KernSub2DR: kernelStr = kernelSub2DR; break;
		case KernNaiveMatMulR: kernelStr = kernelNaiveMatMulR; break;
		case KernEwMul1DR: kernelStr = kernelEwMul1DR; break;
		case KernEwMul2DR: kernelStr = kernelEwMul2DR; break;
		case KernEwDiv1DR: kernelStr = kernelEwDiv1DR; break;
		case KernEwDiv2DR: kernelStr = kernelEwDiv2DR; break;
		case KernDotProd1DR: kernelStr = kernelDotProd1DR; break;
		case KernDotProd2DR: kernelStr = kernelDotProd2DR; break;

		default:
			return;
	}

	err = calclCompile(&obj,CAL_LANGUAGE_IL,kernelStr,target);
	if(err == CAL_RESULT_OK) 							
		err = calclLink(&img,&obj,1);
	
	if(err != CAL_RESULT_OK)
	{
		if(obj)
			calclFreeObject(obj);
		obj = NULL;
		img = NULL;
		return;
	}

	this->iKernel = iKernel;
}

Kernel::~Kernel(void)
{
	if(img)
		calclFreeImage(img);
	if(obj)
		calclFreeObject(obj);
}

/*
	KernelPool
*/

KernelPool::KernelPool(void)
{

}

KernelPool::~KernelPool(void)
{
	RemoveAll();
}

void KernelPool::Remove(long ind)
{
	Kernel* kern = (Kernel*)ObjectPool::Get(ind);
	if(kern)
		delete kern;
	
	ObjectPool::Remove(ind);
}

/*
	Module
*/


void GetNumInputsOutputs(long iKernel, long* nInputs, long* nOutputs, long* nConstants)
{
	switch(iKernel)
	{
		case KernAdd1DR: *nInputs = 2; *nOutputs = 1; *nConstants = 0; break;
		case KernAdd2DR: *nInputs = 2; *nOutputs = 1; *nConstants = 0; break;
		case KernSub1DR: *nInputs = 2; *nOutputs = 1; *nConstants = 0; break;
		case KernSub2DR: *nInputs = 2; *nOutputs = 1; *nConstants = 0; break;
		case KernNaiveMatMulR: *nInputs = 2; *nOutputs = 1; *nConstants = 0; break;
		case KernEwMul1DR: *nInputs = 2; *nOutputs = 1; *nConstants = 0; break;
		case KernEwMul2DR: *nInputs = 2; *nOutputs = 1; *nConstants = 0; break;
		case KernEwDiv1DR: *nInputs = 2; *nOutputs = 1; *nConstants = 0; break;
		case KernEwDiv2DR: *nInputs = 2; *nOutputs = 1; *nConstants = 0; break;
		case KernDotProd1DR: *nInputs = 2; *nOutputs = 1; *nConstants = 0; break;
		case KernDotProd2DR: *nInputs = 2; *nOutputs = 1; *nConstants = 0; break;
		default: *nInputs = 0; *nOutputs = 0; *nConstants = 0; break;
	}
}

Module::Module(CALcontext ctx, Kernel* kern)
{
	CALresult err;
	long i;
	module = 0;
	char str[8];
	
	this->ctx = ctx;
	this->kern = kern;	

	err = calModuleLoad(&module,ctx,kern->img);
	if(err != CAL_RESULT_OK){module = 0; return;}	

	err = calModuleGetEntry(&func,ctx,module,"main");
	if(err != CAL_RESULT_OK){calModuleUnload(ctx,module); module = 0; return;}		

	// get names for all kernel parameters

	GetNumInputsOutputs(kern->iKernel,&nInputs,&nOutputs,&nConstants);
	
	if(nInputs)
		inputNames = new CALname[nInputs];
	if(nOutputs)
		outputNames = new CALname[nOutputs];
	if(nConstants)
		constNames = new CALname[nConstants];

	for(i = 0; (i < nInputs) && (err == CAL_RESULT_OK); i++)
	{
		sprintf_s(str,"i%d",i);
		err = calModuleGetName(&inputNames[i],ctx,module,str);
	}
	if(err != CAL_RESULT_OK)
	{
		if(inputNames){delete inputNames; inputNames = NULL;}
		if(outputNames){delete outputNames; outputNames = NULL;}
		if(constNames){delete constNames; constNames = NULL;}
		calModuleUnload(ctx,module); 
		module = 0; 
		return;
	}
	
	for(i = 0; (i < nOutputs) && (err == CAL_RESULT_OK); i++)
	{
		sprintf_s(str,"o%d",i);
		err = calModuleGetName(&outputNames[i],ctx,module,str);
	}
	if(err != CAL_RESULT_OK)
	{
		if(inputNames){delete inputNames; inputNames = NULL;}
		if(outputNames){delete outputNames; outputNames = NULL;}
		if(constNames){delete constNames; constNames = NULL;}
		calModuleUnload(ctx,module); 
		module = 0; 
		return;
	}	

	for(i = 0; (i < nConstants) && (err == CAL_RESULT_OK); i++)
	{
		sprintf_s(str,"cb%d",i);
		err = calModuleGetName(&constNames[i],ctx,module,str);
	}
	if(err != CAL_RESULT_OK)
	{
		if(inputNames){delete inputNames; inputNames = NULL;}
		if(outputNames){delete outputNames; outputNames = NULL;}
		if(constNames){delete constNames; constNames = NULL;}
		calModuleUnload(ctx,module); 
		module = 0; 
		return;
	}	
}

Module::~Module(void)
{
	if(nInputs)
		delete inputNames;

	if(nOutputs)
		delete outputNames;

	if(nConstants)
		delete constNames;

	if(module)
		calModuleUnload(ctx,module);	
}

/*
	ModulePool
*/

ModulePool::ModulePool(void)
{

}

ModulePool::~ModulePool(void)
{
	RemoveAll();
}
	
Module* ModulePool::Get(long ind)
{
	return (Module*)ObjectPool::Get(ind);
}

void ModulePool::Remove(long ind)
{
	Module* module = (Module*)ObjectPool::Get(ind);
	if(module)
		delete module;
	
	ObjectPool::Remove(ind);
}

/*
	Context
*/

Context::Context(CALdevice hDev, KernelPool* kernels)
{	
	CALresult err;
	Module* module;
	long i;

	arg1 = NULL; 
	arg2 = NULL; 
	retArg = NULL;	

	err = calCtxCreate(&ctx,hDev);
	if(err != CAL_RESULT_OK)
	{
		ctx = 0; return;
	}

	modules = new ModulePool;

	for(i = 0; i < kernels->Length(); i++)
	{
		module = new Module(ctx,(Kernel*)kernels->Get(i));
		if(module->module)
			modules->Add(module);
		else
		{
			delete module; module = NULL;
			delete modules; modules = NULL;
			calCtxDestroy(ctx);
			ctx = 0;
			return;
		}
	}

	this->hDev = hDev;
}

Context::~Context(void)
{	
	if(modules)
		delete modules;
	calCtxDestroy(ctx);
}

Module* Context::GetSuitedModule(long op, CALdomain* domain)
{
	Module* module = NULL;

	if( (op == OpAdd) || (op == OpSub) || (op == OpEwMul) || (op == OpEwDiv) )
	{
		if(retArg->nLogicDims == 1)
		{			
			(*domain).x = 0;
			(*domain).y = 0;
			(*domain).width = retArg->physSize[0];
			(*domain).height = 1;
		}
		else if(retArg->nDims == 2)
		{				
			(*domain).x = 0;
			(*domain).y = 0;
			(*domain).width = retArg->physSize[1];
			(*domain).height = retArg->physSize[0];
		}
		
		if(retArg->nLogicDims == 1)
		{
			switch(op)
			{
				case OpAdd:
					switch(retArg->dFormat)
					{
						case CAL_FORMAT_FLOAT_1:
							return modules->Get(KernAdd1DR);
					}break;

				case OpSub: 
					switch(retArg->dFormat)
					{
						case CAL_FORMAT_FLOAT_1:
							return modules->Get(KernSub1DR);
					}break;

				case OpEwMul:
					switch(retArg->dFormat)
					{
						case CAL_FORMAT_FLOAT_1:
							return modules->Get(KernEwMul1DR);
					}break;

				case OpEwDiv: 
					switch(retArg->dFormat)
					{
						case CAL_FORMAT_FLOAT_1:
							return modules->Get(KernEwDiv1DR);
					}break;
			}
		}
		else if(retArg->nLogicDims == 2)
		{
			switch(op)
			{
				case OpAdd:
					switch(retArg->dFormat)
					{
						case CAL_FORMAT_FLOAT_1:
							return modules->Get(KernAdd2DR);
					}break;

				case OpSub: 
					switch(retArg->dFormat)
					{
						case CAL_FORMAT_FLOAT_1:
							return modules->Get(KernSub2DR);
					}break;

				case OpEwMul:
					switch(retArg->dFormat)
					{
						case CAL_FORMAT_FLOAT_1:
							return modules->Get(KernEwMul2DR);
					}break;

				case OpEwDiv: 
					switch(retArg->dFormat)
					{
						case CAL_FORMAT_FLOAT_1:
							return modules->Get(KernEwDiv2DR);
					}break;
			}
		}
	}

	return module;
}

// macroses used in Do functions
#define ReleaseArg1Mem \
if(arg1Mem)calCtxReleaseMem(ctx,arg1Mem); \

#define ReleaseArg2Mem \
if(arg2Mem)calCtxReleaseMem(ctx,arg2Mem); \

#define ReleaseRetArgMem \
if(retArgMem)calCtxReleaseMem(ctx,retArgMem); \

#define SetupArg1Mem \
err = calCtxGetMem(&arg1Mem,ctx,arg1->localRes); \
if(err != CAL_RESULT_OK){return err;} \
err = calCtxSetMem(ctx,module->inputNames[0],arg1Mem); \
if(err != CAL_RESULT_OK){ReleaseArg1Mem; return err;} \

#define SetupArg2Mem \
err = calCtxGetMem(&arg2Mem,ctx,arg2->localRes); \
if(err != CAL_RESULT_OK){ReleaseArg1Mem; return err;} \
err = calCtxSetMem(ctx,module->inputNames[1],arg2Mem); \
if(err != CAL_RESULT_OK){ReleaseArg1Mem; ReleaseArg2Mem; return err;} \

#define SetupRetArgMem \
err = calCtxGetMem(&retArgMem,ctx,retArg->localRes); \
if(err != CAL_RESULT_OK){ReleaseArg1Mem; ReleaseArg2Mem; return err;} \
err = calCtxSetMem(ctx,module->outputNames[0],retArgMem); \
if(err != CAL_RESULT_OK){ReleaseArg1Mem; ReleaseArg2Mem; ReleaseRetArgMem; return err;} \

// perform an elementwise operation
CALresult Context::DoElementwise(long op)
{
	CALresult err;
	CALmem arg1Mem = 0;
	CALmem arg2Mem = 0;
	CALmem retArgMem = 0;
	CALdomain domain;
	CALevent ev;
	Module* module = NULL;

	SetupArg1Mem;
	SetupArg2Mem;
	SetupRetArgMem;

	// get the most suited module for given operation and array arguments
	module = GetSuitedModule(op,&domain);

	if(module == NULL){ReleaseArg1Mem; ReleaseArg2Mem; ReleaseRetArgMem; return CAL_RESULT_ERROR;}

	// run the kernel
	err = calCtxRunProgram(&ev,ctx,module->func,&domain);
	if(err != CAL_RESULT_OK){ReleaseArg1Mem; ReleaseArg2Mem; ReleaseRetArgMem; return err;};

	while((err = calCtxIsEventDone(ctx,ev)) == CAL_RESULT_PENDING);
		
	// set flag that arguments are not currently in use
	arg1->useCounter--;
	arg2->useCounter--;
	retArg->useCounter--;		

	ReleaseArg1Mem;
	ReleaseArg2Mem;
	ReleaseRetArgMem;

	return err;	
}

CALresult Context::DoMul(void)
{
	return CAL_RESULT_NOT_SUPPORTED;	
}

CALresult Context::DoDotProd(void)
{
	return CAL_RESULT_NOT_SUPPORTED;	
}

// do an operation
CALresult Context::Do(long op)
{
	if( (op < OpAdd) || (op >= NOps) ) return CAL_RESULT_INVALID_PARAMETER;				
	
	switch(op)
	{
		case OpAdd:
			return DoElementwise(op);
		case OpSub:
			return DoElementwise(op);
		case OpMul:
			return DoMul();
		case OpEwMul:			
			return DoElementwise(op);
		case OpEwDiv:
			return DoElementwise(op);
		case OpDotProd:
			return DoDotProd();
		default:
			return CAL_RESULT_NOT_SUPPORTED;
	}
}

/*
	Exclude
*/

Exclude::Exclude(void)
{
	obj = NULL; 
	next = NULL;
};

Exclude::~Exclude(void)
{
	delete next;
};

void Exclude::Add(void* obj)
{
	if(next) 
		next->Add(obj);
	else if(this->obj)
	{
		next = new Exclude;
		next->obj = obj;
	}
	else	
		this->obj = obj;
};

BOOL Exclude::In(void* obj)
{
	if(this->obj) 
		return this->obj == obj;
	else if(next)	
		return next->In(obj);
	else 
		return FALSE;
}

/*
	ArgumentPool
*/

ArgumentPool::ArgumentPool(void)
{

}

ArgumentPool::~ArgumentPool(void)
{
	RemoveAll();
}


void ArgumentPool::Remove(long ind)
{
	Argument* arg = (Argument*)Get(ind);
	if(arg) 
		delete arg;

	ObjectPool::Remove(ind);
}

Argument* ArgumentPool::Get(long ind)
{
	return (Argument*)ObjectPool::Get(ind);
}

long ArgumentPool::Find(long argID)
{
	long i;

	for(i = 0; (i < Length()) && ( ((Argument*)Get(i))->argID != argID); i++);

	if(i < Length()) 
		return i; 
	else 
		return -1;
}

long ArgumentPool::FindModified(Exclude* excl)
{
	long i;
	Argument* arg = NULL;

	for(i = 0; i < Length(); i++)
	{
		arg = (Argument*)Get(i);
		if( (arg->isModified) && ((!excl) || (!excl->In(arg))) ) break;
	}

	if(i < Length()) 
		return i;
	else
		return -1;
}

void ArgumentPool::FreeAllModified(void)
{	
	long ind;

	while( (ind = FindModified(NULL)) >= 0 )
	{
		Remove(ind);
	}
}

Argument* ArgumentPool::FindMaxLocalNotInUse(Exclude* excl)
{
	long i;
	Argument* arg = NULL;
	Argument* arg1 = NULL;

	for(i = 0; i < Length(); i++)
	{
		arg1 = (Argument*)Get(i);

		if( (!arg1->useCounter) && (arg1->localRes) && ((!excl) || (!excl->In(arg1))) )
		{
			if(arg && (arg->dataSize < arg1->dataSize) ) arg = arg1; 
			else arg = arg1;
		}
	}

	return arg;
}

Argument* ArgumentPool::FindMinLocalNotInUse(Exclude* excl)
{
	long i;
	Argument* arg = NULL;
	Argument* arg1 = NULL;

	for(i = 0; i < Length(); i++)
	{
		arg1 = (Argument*)Get(i);

		if( (!arg1->useCounter) && (arg1->localRes) && ((!excl) || (!excl->In(arg1))) )
		{
			if(arg && (arg->dataSize > arg1->dataSize) ) 
				arg = arg1; 
			else 
				arg = arg1;
		}
	}

	return arg;
}

CALresult ArgumentPool::NewArgument(CALdevice hDev, CALdeviceinfo* devInfo, CALcontext ctx, long argID, long dType, long nDims, long* size, void* data)
{
	CALresult err;
	Argument* arg;
	Argument* arg1;
	Exclude excl;
	long format;	

	format = GetFormat(dType);
	if(format == -1) 
		return CAL_RESULT_INVALID_PARAMETER;
					
	arg = new Argument(hDev,devInfo,argID,(CALformat)format,nDims,size,data);	

	// allocate local GPU memory
	err = arg->AllocateLocal(0);
	if(err == CAL_RESULT_ERROR) // could not allocate
	{
		// try to free space in the local memory
		FreeAllModified();
		err = arg->AllocateLocal(0);
		if(err == CAL_RESULT_ERROR) // could not allocate again
		{
			// try to move local to remote if possible
			while( (arg1 = FindMinLocalNotInUse(&excl)) != NULL )
			{
				err = arg1->FreeLocalKeepInRemote(ctx);			
				if(err != CAL_RESULT_OK) // exclude argument from the search									
					excl.Add(arg1);			
				else if( (err = arg->AllocateLocal(0)) == CAL_RESULT_OK) 			
					break;		
			}		
		}
	}

	if(err == CAL_RESULT_OK) 
		Add(arg);
	else
		delete arg;

	return err;
}

/*
	ContextPool
*/

ContextPool::ContextPool(CALdevice hDev)
{	
	this->hDev = hDev;
}

ContextPool::~ContextPool(void)
{	
	RemoveAll();
}

Context* ContextPool::Get(long ind)
{
	return (Context*)ObjectPool::Get(ind);
}

void ContextPool::Remove(long ind)
{
	Context* context = (Context*)ObjectPool::Get(ind);
	if(context)
		delete context;
	
	ObjectPool::Remove(ind);
}

long ContextPool::Find(long ctx)
{	
	CALcontext ctx_;
	long i;

	ctx_ = (CALcontext)(ctx);

	for(i = 0; (i < Length()) && ( ((Context*)(Get(i)))->ctx != ctx_); i++);

	if(i < Length()) 
		return i; 
	else 
		return -1;
}

/*
	Device
*/

Device::Device(long devNum)
{
	CALresult err;
	Kernel* kern;
	long i;

	ctxs = NULL;
	kernels = NULL;
	hDev = 0;

	err = calDeviceOpen(&hDev,devNum);
	if(err != CAL_RESULT_OK)
	{
		hDev = 0;
		return;
	}

	// get device attributes
	attribs.struct_size = sizeof(CALdeviceattribs);
	err = calDeviceGetAttribs(&attribs,devNum);
	
	if(err != CAL_RESULT_OK)
	{
		calDeviceClose(hDev); 
		hDev = 0; 
		return;
	}
		
	err = calDeviceGetInfo(&info,devNum);
	if(err != CAL_RESULT_OK)
	{
		calDeviceClose(hDev); 
		hDev = 0; 
		return;
	}

	kernels = new KernelPool();

	for(i = 0; i < NKernels; i++)
	{
		kern = new Kernel(i,attribs.target);
		if(kern->obj)		
			kernels->Add(kern);		
		else
		{
			delete kern;
			delete kernels;
			kernels = NULL;
			calDeviceClose(hDev); 
			hDev = 0; 
			return;
		}
	}

	ctxs = new ContextPool(hDev);	
	args = new ArgumentPool;

	this->devNum = devNum;
}

Device::~Device(void)
{
	if(hDev)
		calDeviceClose(hDev);

	if(ctxs)
		delete ctxs;

	if(args)
		delete args;

	if(kernels)
		delete kernels;
}

CALresult Device::NewContext(long* ctx)
{
	Context* context;
	CALresult err = CAL_RESULT_OK;
		
	context = new Context(hDev,kernels);
	
	*ctx = 0;
	if(context->ctx)
	{
		ctxs->Add(context);
		*ctx = context->ctx;
	}
	else
		err = CAL_RESULT_ERROR;
	
	return err;
}

/*
	DevicePool
*/

DevicePool::DevicePool(void)
{
	
}

DevicePool::~DevicePool(void)
{
	RemoveAll();
}

Device* DevicePool::Get(long ind)
{
	return (Device*)(ObjectPool::Get(ind));
}

void DevicePool::Remove(long ind)
{
	Device* dev = (Device*)ObjectPool::Get(ind);

	if(dev)
		delete dev;

	ObjectPool::Remove(ind);
}


