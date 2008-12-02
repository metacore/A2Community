#pragma once
#include "ObjectPool.h"
#include "Modules.h"
#include "Arrays.h"
#include "Common.h"

// operation codes
#define OpIdentic	0
#define OpAdd		1
#define OpSub		2
#define OpMul		3
#define OpDiv		4
#define OpDotProd	5
#define OpMulInc	6
#define	OpMulDec	7	
#define OpEwMul		8
#define OpEwDiv		9
#define OpEwMulInc	10
#define OpEwMulDec	11
	
#define OpReshape	21
#define OpTranspose	22

class Context
{
public:
	Context(CALdevice hDev, CALdeviceattribs* devAttribs, KernelPool* kernels);
	~Context(void);

	CALresult SetComputation(ArrayExpression* expr, Array* result, long priority, long flags, ArrayPool* arrs);

	CALresult err;	// error code for last operation

	CALcontext ctx;	// context handle
	CALdevice hDev;	// device handle		

	KernelPool* kernels;
	
	ArrayExpression* expr;	// array expression describing current computation
	Array* result;			// result array for current computation

	CALdeviceattribs* devAttribs;

	CALcounter idleCounter;	// GPU Idle counter
	CALcounter cacheHitCounter;	// GPU cache hit counter
	
	// perform the computation which was preliminary set by SetComputation
	CALresult DoComputation(void);
	// perform assignment of array identity (using pixel shader)
	CALresult DoIdenticPS(void);
	// perform assignment of array identity (using compute shader)
	CALresult DoIdenticCS(void);
	// Run a pixel shader program
	CALresult RunPixelShader(Module* module, Array** inputs, Array** outputs, Array* globalBuffer, CALdomain* domain);
	// performs an elementwise operation using pixel shader
	CALresult DoElementwisePS(void);
	// start Idle counter
	CALresult StartIdleCounter(void);
	// start cache hit counter
	CALresult StartCacheHitCounter(void);
	// stop idle counter
	CALresult StopIdleCounter(void);
	// stop cache hit counter
	CALresult StopCacheHitCounter(void);
	// get idle counter value
	CALresult GetIdleCounter(float* counterVal);
	// get cache hit counter value
	CALresult GetCacheHitCounter(float* counterVal);
	
	BOOL InitCounterExtension(void);

	PFNCALCTXCREATECOUNTER  calCtxCreateCounterExt;
	PFNCALCTXDESTROYCOUNTER calCtxDestroyCounterExt;
	PFNCALCTXBEGINCOUNTER   calCtxBeginCounterExt;
	PFNCALCTXENDCOUNTER     calCtxEndCounterExt;
	PFNCALCTXGETCOUNTER     calCtxGetCounterExt;	

	BOOL counterExtSupported;
	// perform matrix vector operation using pixel shader
	CALresult DoMatVecPS(void);
	// perform matrix vector operation using compute shader
	CALresult DoMatVecCS(void);
	// allocate local memory of an array with freeing space if necessary
	CALresult AllocateArrayLocal(Array* arr, ArrayPool* arrs, CALuint flags);
	// Run a compute shader program
	CALresult RunComputeShader(Module* module, Array** inputs, Array* globalBuffer, CALprogramGrid* programGrid);
	// setup an elementwise computation
	CALresult SetElementwise(ArrayExpression* expr, Array* result, ArrayPool* arrs);
	// perform an elementwise operation using compute shader
	CALresult DoElementwiseCS(void);
};

class ContextPool :
	public ObjectPool
{
public:
	ContextPool(void);
	~ContextPool(void);

	Context* Get(long ind);	
	void Remove(long ind);
	long Find(long ctx);

	CALresult err;	// error code for last operation
};
