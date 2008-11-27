#pragma once
#include "ObjectPool.h"
#include "Modules.h"
#include "Arrays.h"

// operation codes
#define OpIdent		0
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
	Context(CALdevice hDev, KernelPool* kernels);
	~Context(void);

	CALresult SetComputation(ArrayExpression* expr, Array* result, long priority, long flags, ArrayPool* arrs);

	CALresult err;	// error code for last operation

	CALcontext ctx;	// context handle
	CALdevice hDev;	// device handle		
	
	ArrayExpression* expr;	// array expression describing current computation
	Array* result;			// result array for current computation

	ModulePool* modules;
	// perform the computation which was preliminary set by SetComputation
	CALresult DoComputation(void);
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
