#include <stdafx.h>
#include "Objects.h"



const char kernelAdd[] =
"il_ps_2_0\n"
//"dcl_cb cb0[1]\n"
"dcl_resource_id(0)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_input_generic_interp(linear) v0.xy__\n"
"dcl_resource_id(1)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_input_generic_interp(linear) v1.xy__\n"
"sample_resource(0)_sampler(0) r0.x, v0.xy00\n"
"sample_resource(1)_sampler(1) r1.x, v1.xy00\n"
"mov r2.x, r0.xxxx\n"
"mov r3.x, r1.xxxx\n"
"call 0\n"
"mov r4.x, r5.xxxx\n"
"dcl_output_generic o0\n"
"mov o0, r4.xxxx\n"
"ret\n"
"func 0\n"
"add r6.x, r2.xxxx, r3.xxxx\n"
"mov r7.x, r6.xxxx\n"
"mov r5.x, r7.xxxx\n"
"ret\n"
"end;\n";

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

Argument::Argument(CALdevice hDev, long argID, CALformat dFormat, long nDims, long* size, void* data)
{
	long i;

	this->hDev = hDev;	
	this->argID = argID;		
	this->dFormat = dFormat;
	this->nDims = nDims;

	this->size = new long[nDims]; 
	dSize = GetElementSize(dFormat);
	for(i = 0; i < nDims; i++)
	{
		this->size[i] = size[i];
		dSize *= size[i];
	}

	cpuData = data;
	remoteRes = 0;
	localRes = 0;

	isInUse = FALSE;
}

Argument::~Argument(void)
{
	if(size != NULL) 
		delete size;

	FreeLocal();
	FreeRemote();	
}

CALresult Argument::AllocateLocal(CALuint flags)
{
	CALresult err;	

	FreeLocal();
	
	if(nDims == 2)
	{						
		err = calResAllocLocal2D(&localRes,hDev,size[1],size[0],dFormat,flags);
	}
	else // unsupported dimensionality
	{
		err = CAL_RESULT_NOT_SUPPORTED;
	}
	
	return err;
}

CALresult Argument::AllocateRemote(CALuint flags)
{
	CALresult err;

	err = CAL_RESULT_OK;

	FreeRemote();
	
	if(nDims == 2)
	{
		err = calResAllocRemote2D(&remoteRes,&hDev,1,size[1],size[0],dFormat,flags);
		if(err != CAL_RESULT_OK) remoteRes = 0;
	}
	else
	{
		err = CAL_RESULT_NOT_SUPPORTED;
	}

	return err;
}

/*
	assumes that remoteRes is not allocated!
*/
void Argument::FreeLocal()
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
	if(nDims == 2)
	{
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
	}
	else
	{
		err = CAL_RESULT_NOT_SUPPORTED;
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
	{
		err = CopyCPUToLocal(ctx);
		return err;
	}

	err = SetDataToRemote(ctx);
	if(err == CAL_RESULT_OK) 
		err = CopyRemoteToLocal(ctx);

	FreeRemote();

	if(err != CAL_RESULT_OK) 
		err = CopyCPUToLocal(ctx);

	return err;	
}

CALresult Argument::SetDataToRemote(CALcontext ctx)
{
	CALresult err;
	CALuint pitch;
	long i, n;
	char* gpuPtr;
	char* cpuPtr;

	err = CAL_RESULT_OK;
	
	if(remoteRes == 0) 
		err = AllocateRemote(0);

	if(err != CAL_RESULT_OK) 
		return err;
	
	cpuPtr = (char*)cpuData;

	if(nDims == 2)
	{
		err = calResMap((void**)&gpuPtr,&pitch,remoteRes,0);
		if(err != CAL_RESULT_OK) 
			return err;

		n = GetElementSize(dFormat);
		pitch *= n; // pitch in number of bytes

		n = n*size[1];	// matrix width in bytes

		if(n == pitch) 
			CopyMemory(gpuPtr,cpuPtr,dSize);
		else
		{
			for(i = 0; i < size[0]; i++)
			{
				CopyMemory(gpuPtr,cpuPtr,n);
				gpuPtr += pitch;
				cpuPtr += n;
			}
		}

		err = calResUnmap(remoteRes);		
	}
	else
	{
		err = CAL_RESULT_NOT_SUPPORTED;
	}

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
	{
		err = CopyLocalToCPU(ctx);
		return err;
	}
	
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
	long i, n;
	char* gpuPtr;
	char* cpuPtr;
	
	_ASSERT(remoteRes != 0);

	err = CAL_RESULT_OK;
	
	cpuPtr = (char*)cpuData;

	if(nDims == 2)
	{
		err = calResMap((void**)&gpuPtr,&pitch,remoteRes,0);
		if(err != CAL_RESULT_OK) 
			return err;

		n = GetElementSize(dFormat);
		pitch *= n; // pitch in number of bytes

		n = n*size[1];	// matrix width in bytes		

		if(n == pitch) 
			CopyMemory(cpuPtr,gpuPtr,dSize);
		else
		{
			for(i = 0; i < size[0]; i++)
			{
				CopyMemory(cpuPtr,gpuPtr,n);
				gpuPtr += pitch;
				cpuPtr += n;
			}
		}

		err = calResUnmap(remoteRes);		
	}
	else
	{
		err = CAL_RESULT_NOT_SUPPORTED;
	}

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

CALresult Argument::CopyCPUToLocal(CALcontext ctx)
{
	CALresult err;
	CALuint pitch;
	long i, n;
	char* gpuPtr;
	char* cpuPtr;

	err = CAL_RESULT_OK;
	
	if(localRes == 0)
		err = AllocateLocal(0);

	if(err != CAL_RESULT_OK) 
		return err;
	
	cpuPtr = (char*)cpuData;

	if(nDims == 2)
	{
		err = calResMap((void**)&gpuPtr,&pitch,localRes,0);
		if(err != CAL_RESULT_OK) 
			return err;

		n = GetElementSize(dFormat);
		pitch *= n; // pitch in number of bytes

		n = n*size[1];	// matrix width in bytes

		if(n == pitch) 
			CopyMemory(gpuPtr,cpuPtr,dSize);
		else
		{
			for(i = 0; i < size[0]; i++)
			{
				CopyMemory(gpuPtr,cpuPtr,n);
				gpuPtr += pitch;
				cpuPtr += n;
			}
		}

		err = calResUnmap(localRes);		
	}
	else
	{
		err = CAL_RESULT_NOT_SUPPORTED;
	}

	return err;
}

CALresult Argument::CopyLocalToCPU(CALcontext ctx)
{
	CALresult err;
	CALuint pitch;
	long i, n;
	char* gpuPtr;
	char* cpuPtr;

	err = CAL_RESULT_OK;
	
	if(localRes == 0)
		err = AllocateLocal(0);

	if(err != CAL_RESULT_OK) 
		return err;
	
	cpuPtr = (char*)cpuData;

	if(nDims == 2)
	{
		err = calResMap((void**)&gpuPtr,&pitch,localRes,0);
		if(err != CAL_RESULT_OK) 
			return err;

		n = GetElementSize(dFormat);
		pitch *= n; // pitch in number of bytes

		n = n*size[1];	// matrix width in bytes

		if(n == pitch) 
			CopyMemory(cpuPtr,gpuPtr,dSize);
		else
		{
			for(i = 0; i < size[0]; i++)
			{
				CopyMemory(cpuPtr,gpuPtr,n);
				gpuPtr += pitch;
				cpuPtr += n;
			}
		}

		err = calResUnmap(localRes);		
	}
	else
	{
		err = CAL_RESULT_NOT_SUPPORTED;
	}

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

Kernel::Kernel(long op, CALtarget target)
{	
	obj = NULL;
	img = NULL;	

	CALresult err;		

	switch(op)
	{
		case OP_ADD:
		{
			funcName = "main";
			arg1Name = "i0";
			arg2Name = "i1";
			retArgName = "o0";

			err = calclCompile(&obj,CAL_LANGUAGE_IL,kernelAdd,target);
			if(err == CAL_RESULT_OK) 							
				err = calclLink(&img,&obj,1);						

		}break;
	}
	
	if(err != CAL_RESULT_OK)
	{
		if(obj)
			calclFreeObject(obj);
		obj = NULL;
		img = NULL;
	}

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

#define ExitModuleInit calModuleUnload(ctx,module); module = 0; return;

Module::Module(CALcontext ctx, Kernel* kern)
{
	CALresult err;
	module = 0;
	
	this->ctx = ctx;
	this->kern = kern;

	err = calModuleLoad(&module,ctx,kern->img);
	if(err != CAL_RESULT_OK){ExitModuleInit;}	

	err = calModuleGetEntry(&func,ctx,module,kern->funcName);
	if(err != CAL_RESULT_OK){ExitModuleInit;}		

	err = calModuleGetName(&arg1Name,ctx,module,kern->arg1Name);
	if(err != CAL_RESULT_OK){ExitModuleInit;}		

	err = calModuleGetName(&arg2Name,ctx,module,kern->arg2Name);
	if(err != CAL_RESULT_OK){ExitModuleInit;}		

	err = calModuleGetName(&retArgName,ctx,module,kern->retArgName);
	if(err != CAL_RESULT_OK){ExitModuleInit;}		
}

Module::~Module(void)
{
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

#define ExitDo if(arg1Mem)calCtxReleaseMem(ctx,arg1Mem); \
if(arg2Mem)calCtxReleaseMem(ctx,arg2Mem); \
if(retArgMem)calCtxReleaseMem(ctx,retArgMem); \
return err;\

CALresult Context::Do(long op)
{
	CALmem arg1Mem = 0;
	CALmem arg2Mem = 0;
	CALmem retArgMem = 0;
	CALdomain domain;
	CALevent ev;

	CALresult err;

	if( (op < OP_ADD) || (op >= NOPS) ) return CAL_RESULT_INVALID_PARAMETER;

	if( !arg1 || !arg2 || !retArg )  return CAL_RESULT_INVALID_PARAMETER;
	
	// get memory handles
	err = calCtxGetMem(&arg1Mem,ctx,arg1->localRes);
	if(err != CAL_RESULT_OK)	
		return err;
	
	err = calCtxGetMem(&arg2Mem,ctx,arg2->localRes);
	if(err != CAL_RESULT_OK){ExitDo;}

	err = calCtxGetMem(&retArgMem,ctx,retArg->localRes);
	if(err != CAL_RESULT_OK){ExitDo;}	

	// setting input and output buffers
	err = calCtxSetMem(ctx,modules->Get(op)->arg1Name,arg1Mem);
	if(err != CAL_RESULT_OK){ExitDo}	

	err = calCtxSetMem(ctx,modules->Get(op)->arg2Name,arg2Mem);
	if(err != CAL_RESULT_OK){ExitDo;}	

	err = calCtxSetMem(ctx,modules->Get(op)->retArgName,retArgMem);
	if(err != CAL_RESULT_OK){ExitDo;}	

	// Setting domain
	domain.x = 0;
	domain.y = 0;
	domain.width = arg1->size[1];
	domain.height = arg1->size[0];

	err = calCtxRunProgram(&ev,ctx,modules->Get(op)->func,&domain);
	if(err != CAL_RESULT_OK){ExitDo;};

	while((err = calCtxIsEventDone(ctx,ev)) == CAL_RESULT_PENDING);
	
	arg1->isInUse = FALSE;
	arg2->isInUse = FALSE;
	retArg->isInUse = FALSE;

	ExitDo;	
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

Argument* ArgumentPool::FindMaxLocalNotInUse(Exclude* excl)
{
	long i;
	Argument* arg = NULL;
	Argument* arg1 = NULL;

	for(i = 0; i < Length(); i++)
	{
		arg1 = (Argument*)Get(i);

		if( (!arg1->isInUse) && (arg1->localRes) && (!excl->In(arg1)) )
		{
			if(arg && (arg->dSize < arg1->dSize) ) arg = arg1; 
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

		if( (!arg1->isInUse) && (arg1->localRes) && (!excl->In(arg1)) )
		{
			if(arg && (arg->dSize > arg1->dSize) ) 
				arg = arg1; 
			else 
				arg = arg1;
		}
	}

	return arg;
}

CALresult ArgumentPool::NewArgument(CALdevice hDev, CALcontext ctx, long argID, long dType, long nDims, long* size, void* data)
{
	CALresult err;
	Argument* arg;
	Argument* arg1;
	Exclude excl;
	long format;	

	format = GetFormat(dType);
	if(format == -1) 
		return CAL_RESULT_INVALID_PARAMETER;
					
	arg = new Argument(hDev,argID,(CALformat)format,nDims,size,data);	

	// allocate local GPU memory
	err = arg->AllocateLocal(0);
	if(err == CAL_RESULT_ERROR) // could not allocate
	{
		// try to free space in the local memory
		while( (arg1 = FindMinLocalNotInUse(&excl)) != NULL )
		{
			err = arg1->FreeLocalKeepInRemote(ctx);			
			if(err != CAL_RESULT_OK) // exclude argument from the search									
				excl.Add(arg1);			
			else if( (err = arg->AllocateLocal(0)) == CAL_RESULT_OK) 			
				break;		
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

	kernels = new KernelPool();

	for(i = 0; i < NOPS; i++)
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


