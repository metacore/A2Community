#include "StdAfx.h"
#include "Devices.h"

Device::Device(long devNum)
{	
	Kernel* kern;
	long i;

	ctxs = NULL;
	arrs = NULL;
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
	
	kernels = new Kernel*[NKernels];

	for(i = 0; i < NKernels; i++)
	{
		kern = new Kernel(i,attribs.target);
		if(kern->err == CAL_RESULT_OK)		
			kernels[i] = kern;		
		else
		{			
			delete kern;
			for(i = i-1; i >= 0; i--)
				delete kernels[i];
			delete kernels;

			calDeviceClose(hDev);
			hDev = 0; 
			return;
		}
	}

	ctxs = new ContextPool;	
	arrs = new ArrayPool;

	this->devNum = devNum;
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

CALresult Device::NewContext()
{
	Context* context;

	err = CAL_RESULT_OK;
		
	context = new Context(hDev,&info,&attribs,kernels);
		
	if(context->err == CAL_RESULT_OK)
		ctxs->Add(context);
	else
		err = CAL_RESULT_ERROR;
	
	return err;
}

DevicePool::DevicePool(void)
{
	err = CAL_RESULT_OK;
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
