#include "StdAfx.h"
#include "Devices.h"

Device::Device(long devNum, CALresult* err)
{		
	Kernel* kern;
	long i;

	hDev = 0;
	kernels = NULL;
	ctxs = NULL;
	arrs = NULL;		

	*err = calDeviceOpen(&hDev,devNum);
	if(*err != CAL_RESULT_OK)
	{
		hDev = 0;
		return;
	}

	this->devNum = devNum;

	// get device attributes
	attribs.struct_size = sizeof(CALdeviceattribs);
	*err = calDeviceGetAttribs(&attribs,devNum);	
	if(*err != CAL_RESULT_OK)
	{
		calDeviceClose(hDev); 
		hDev = 0; 
		return;
	}
		
	*err = calDeviceGetInfo(&info,devNum);
	if(*err != CAL_RESULT_OK)
	{
		calDeviceClose(hDev); 
		hDev = 0; 
		return;
	}
	
	kernels = new Kernel*[NKernels];

	for(i = 0; i < NKernels; i++)
	{
		kern = new Kernel(KernelCode(i),attribs.target,err);
		if(*err == CAL_RESULT_OK)		
			kernels[i] = kern;		
		else
		{			
			delete kern;
			for(i = i-1; i >= 0; i--)
				delete kernels[i];
			delete kernels;
			kernels = NULL;

			calDeviceClose(hDev);
			hDev = 0; 
			return;
		}
	}

	ctxs = new ContextPool;	
	arrs = new ArrayPool;	
}

Device::~Device(void)
{
	long i;

	if(ctxs)
		delete ctxs;

	if(arrs)
		delete arrs;

	if(kernels)
	{
		for(i = 0; i < NKernels; i++)
			delete kernels[i];
		delete kernels;
	}

	if(hDev)
		calDeviceClose(hDev);
}

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
	Device* dev = Get(ind);		

	if(dev)
		delete dev;

	ObjectPool::Remove(ind);
}

// create a new context and put it to the context pool
CALresult Device::NewContext(void)
{
	CALresult err;
	Context* context;
		
	context = new Context(hDev,&info,&attribs,arrs,kernels,&err);
		
	if(err == CAL_RESULT_OK)
		ctxs->Add(context);
	
	return err;
}
