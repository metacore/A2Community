#pragma once

#include "Kernels.h"
#include "Constants.h"
#include "Arrays.h"

class Module
{
public:
	Module(CALdevice hDev, CALcontext ctx, Kernel* kern, CALresult* err);
	~Module(void);

	// set module constants to the context
	CALresult SetConstantsToContext(void);
	// release constants from the context
	void ReleaseConstantsFromContext(void);

	// Run a pixel shader program
	CALresult RunPixelShader(Array** inputs, Array** outputs, Array* globalBuffer, CALdomain* domain);
	// Run a compute shader program
	CALresult RunComputeShader(Array** inputs, Array* globalBuffer, CALprogramGrid* programGrid);

	CALdevice hDev;			// device handle
	CALcontext ctx;			// module context	
	CALmodule module;		// handle to the physical module	
	Kernel* kern;			// module kernel

	CALfunc func;			// execution function
	
	long nInputs;			// number of inputs
	CALname* inputNames;	// CAL names of input parameters	
	long nOutputs;			// number of outputs
	CALname* outputNames;	// CAL names of output parameters
	long nConstants;		// number of constants	
	CALname* constNames;	// CAL names of constant parameters	

	BOOL usesGlobalBuffer;	// TRUE when module uses a global buffer
	CALname gbufName;		// CAL name of the global buffer (if exists)

	Constant** constants;	// constants used by the module
};
