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
	Context(CALdevice hDev, CALdeviceinfo* devInfo, CALdeviceattribs* devAttribs, Kernel** kernels);
	~Context(void);

	CALresult SetComputation(ArrayExpression* expr, Array* result, long priority, long flags, ArrayPool* arrs);

	CALresult err;	// error code for last operation
	
	CALcontext ctx;	// context handle
	CALdevice hDev;	// device handle		

	Kernel** kernels;

	Module** modules;	// context modules
	
	ArrayExpression* expr;	// array expression describing current computation
	Array* result;			// result array for current computation

	CALdeviceattribs* devAttribs;
	CALdeviceinfo* devInfo;

	BOOL isInUse;	// TRUE when the context is currently in use

	CALcounter idleCounter;	// GPU Idle counter
	CALcounter cacheHitCounter;	// GPU cache hit counter
	
	// perform the computation which was preliminary set by SetComputation
	CALresult DoComputation(void);
	// perform assignment of array identity
	CALresult DoIdentic(void);	
	// performs an elementwise operation
	CALresult DoElementwise(void);
	// perform matrix vector multiply operation
	CALresult DoMatVecMul(void);	

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

	BOOL counterExtSupported;	// TRUE when counter extension is supported	
	// allocate local memory of an array with freeing space if necessary
	CALresult AllocateArrayLocal(Array* arr, ArrayPool* arrs, CALuint flags);	
	// setup a computation in a common way
	CALresult SetCommon(ArrayExpression* expr, Array* result, ArrayPool* arrs, BOOL overwritenResult, BOOL resultIsGlobalBuf);	
	// perform matrix matrix multiply operation
	CALresult DoMatMul(void);

	// divide a matrix to 4 parts
	CALresult DivideMatrixTo4Parts(Array* arr, Array*** parts);
	// divide a matrix to 8 parts
	CALresult DivideMatrixTo8Parts(Array* arr, Array*** parts);	

	CALresult DoMatMult4x8x4by4x4x4(void);
	CALresult DoMatMult8x4by4x4(void);
	CALresult DoMatMult4x4by4x4(void);
	CALresult DoMatMultByParts4x4x4by4x4x4(void);
	CALresult DoMatMultByParts4x8x4by4x4x4(void);
	CALresult DoMatMultByParts2x8x4by2x4x4(void);
};

class ContextPool :
	public ObjectPool
{
public:
	ContextPool(void);
	~ContextPool(void);

	Context* Get(long ind);	
	void Remove(long ind);	
	long FindNotUsed(void);

	CALresult err;	// error code for last operation
};
