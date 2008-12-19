#pragma once

#include "ObjectPool.h"
#include "Kernels.h"
#include "Arrays.h"
#include "Contexts.h"

class Device
{
public:
	Device(long devNum, CALresult* err);
	~Device(void);	

	CALdevice hDev;				// CAL device handle
	CALuint devNum;				// device number
	CALdeviceattribs attribs;	// device attributes
	CALdeviceinfo info;			// device info

	Kernel** kernels;			// device kernels
	ContextPool* ctxs;			// pool of contexts active on the device			
	ArrayPool* arrs;			// arrays created on the device	
	// create a new context and put it to the context pool
	CALresult NewContext(void);
};

class DevicePool :
	public ObjectPool
{
public:
	DevicePool(void);
	~DevicePool(void);

	Device* Get(long ind);	
	void Remove(long ind);
};
