#pragma once
#include "ObjectPool.h"
#include "Arrays.h"
#include "Kernels.h"
#include "Modules.h"
#include "cal_ext.h"
#include "cal_ext_counter.h"

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
	Context(CALdevice hDev, CALdeviceinfo* devInfo, CALdeviceattribs* devAttribs, ArrayPool* arrs, Kernel** kernels, CALresult* err);
	~Context(void);

	// set computation
	CALresult SetComputation(ArrayExpression* expr, Array* result, long priority, long flags);

	// set an elementwise computation
	CALresult SetElementwise(ArrayExpression* expr, Array* result);
	// split a matrix into given number of parts, convenient for matrix multiplication
	CALresult SplitMatrix(Array* arr, long numParts, Array** parts);
	// perform a computation already set by SetComputation
	CALresult DoComputation(void);
	// perform an elementwise operation
	CALresult DoElementwise(void);
	// set a matrix vector multiply computation
	CALresult SetMatVecMul(ArrayExpression* expr, Array* result);


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

	BOOL InitCounterExtension(void);	// initialize CAL counters extension
	PFNCALCTXCREATECOUNTER  calCtxCreateCounterExt;
	PFNCALCTXDESTROYCOUNTER calCtxDestroyCounterExt;
	PFNCALCTXBEGINCOUNTER   calCtxBeginCounterExt;
	PFNCALCTXENDCOUNTER     calCtxEndCounterExt;
	PFNCALCTXGETCOUNTER     calCtxGetCounterExt;	

	BOOL isUsed;					// TRUE when the context is currently in use

	CALdevice hDev;					// device handle
	CALcontext ctx;					// context handle

	Kernel** kernels;				// used kernels
	Module** modules;				// context modules
	ArrayPool* arrs;				// pool of arrays created on the device

	ArrayExpression* expr;			// array expression describing current computation
	Array* result;					// result array for current computation
	Array* resultTemp;				// a temporary result array

	CALdeviceinfo* devInfo;			// device info
	CALdeviceattribs* devAttribs;	// device attributes 	

	BOOL counterExtSupported;		// TRUE when counter extension is supported	
	CALcounter idleCounter;			// GPU Idle counter
	CALcounter cacheHitCounter;		// GPU cache hit counter	
	// perform a matrix vector multiplication
	CALresult DoMatVecMul(void);
	// perform matrix vector multiplication for the case when matrix is splitted into parts
	CALresult DoMatVecMulSplitted(void);
	// set a matrix multiplication computation
	CALresult SetMatMul(ArrayExpression* expr, Array* result);
	// perform a matrix multiplication computation
	CALresult DoMatMul(void);
	// set a reshape computation
	CALresult SetReshape(ArrayExpression* expr, Array* result);
	// perform a reshape computation
	CALresult DoReshape(void);
	// zero array memory
	CALresult ZeroArrayMemory(Array* arr, CALdomain* domain);
};

class ContextPool :
	public ObjectPool
{
public:
	ContextPool(void);
	~ContextPool(void);

	Context* Get(long ind);	
	void Remove(long ind);	
	long FindUnused(void);			// find a context which is currently unused, returns -1 if there is no such
};
