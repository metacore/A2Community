#pragma once
#include "ObjectPool.h"
#include "Kernels.h"
#include "Arrays.h"
#include "Constants.h"

class Module
{
public:
	Module(CALdevice hDev, CALcontext ctx, Kernel* kern);
	~Module(void);

	// set module constants to the context
	CALresult SetConstantsToContext(void);
	// release constants from the context
	void ReleaseConstantsFromContext(void);
	
	// Run a pixel shader program
	CALresult RunPixelShader(Array** inputs, Array** outputs, Array* globalBuffer, CALdomain* domain);
	// Run a compute shader program
	CALresult RunComputeShader(Array** inputs, Array* globalBuffer, CALprogramGrid* programGrid);

	CALresult err;	// error code for last operation

	CALdevice hDev;	// device handle
	CALcontext ctx;	// module context	
	CALmodule module;	// handle to the physical module	
	Kernel* kern;	// module kernel

	CALfunc func;	// execution function

	CALname* inputNames;	// CAL names of input parameters
	long nInputs;			// number of inputs
	CALname* outputNames;	// CAL names of output parameters
	long nOutputs;			// number of outputs
	CALname* constNames;	// CAL names of constant parameters
	long nConstants;		// number of constants	
	BOOL usesGlobalBuffer;	// TRUE when module uses a global buffer
	CALname gbufName;		// CAL name of the global buffer (if exists)

	Constant** constants;	// constants used by the module
};

class ModulePool :
	public ObjectPool
{
public:
	ModulePool(void);
	~ModulePool(void);

	Module* Get(long ind);	
	void Remove(long ind);

	CALresult err;	// error code for last operation	
};

