#pragma once
#include "ObjectPool.h"
#include "Contexts.h"
#include "Kernels.h"
#include "Arrays.h"

/*
	GPU device
*/
class Device
{
public:
	Device(long devNum);
	~Device(void);	
	CALresult NewContext(long* ctx);	// create a new context	

	CALresult err;	// error code for last operation

	CALdevice hDev;	// CAL device handle
	ContextPool* ctxs;	// pool of contexts active on the device
	CALdeviceattribs attribs;	// device attributes
	CALdeviceinfo info;			// device info
	
	CALuint devNum;			// device index
	KernelPool* kernels;	// device kernels
	ArrayPool* arrs;		// arrays created on the device
};

/*
	Pool of GPU devices
*/
class DevicePool :
	public ObjectPool
{
public:
	DevicePool(void);
	~DevicePool(void);
	Device* Get(long ind);	
	void Remove(long ind);

	CALresult err;	// error code for last operation
};
