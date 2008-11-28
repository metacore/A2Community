#include "StdAfx.h"
#include "Contexts.h"
#include "Kernels.h"
#include "Constant.h"

Context::Context(CALdevice hDev, KernelPool* kernels)
{		
	expr = NULL;
	result = NULL;

	err = calCtxCreate(&ctx,hDev);
	if(err != CAL_RESULT_OK)
	{
		ctx = 0; return;
	}

	idleCounter = 0;
	cacheHitCounter = 0;

	counterExtSupported = InitCounterExtension();

	if(counterExtSupported)
	{
		err = calCtxCreateCounterExt(&idleCounter,ctx,CAL_COUNTER_IDLE);
		if(err != CAL_RESULT_OK)
			idleCounter = 0;

		err = calCtxCreateCounterExt(&cacheHitCounter,ctx,CAL_COUNTER_INPUT_CACHE_HIT_RATE);
		if(err != CAL_RESULT_OK)
			cacheHitCounter = 0;
	}

	this->kernels = kernels;

	this->hDev = hDev;
}

Context::~Context(void)
{
	if(idleCounter)
		calCtxDestroyCounterExt(ctx,idleCounter);

	if(cacheHitCounter)
		calCtxDestroyCounterExt(ctx,cacheHitCounter);

	if(expr)
		delete expr;

	calCtxDestroy(ctx);
}

BOOL Context::InitCounterExtension(void)
{		
    if (calExtSupported((CALextid)CAL_EXT_COUNTERS) != CAL_RESULT_OK)    
        return FALSE;    
        
    if (calExtGetProc((CALextproc*)&calCtxCreateCounterExt, (CALextid)CAL_EXT_COUNTERS, "calCtxCreateCounter"))    
        return FALSE;    

    if (calExtGetProc((CALextproc*)&calCtxDestroyCounterExt, (CALextid)CAL_EXT_COUNTERS, "calCtxDestroyCounter"))
		return FALSE;
    
    if (calExtGetProc((CALextproc*)&calCtxBeginCounterExt, (CALextid)CAL_EXT_COUNTERS, "calCtxBeginCounter"))
		return FALSE;
    
    if (calExtGetProc((CALextproc*)&calCtxEndCounterExt, (CALextid)CAL_EXT_COUNTERS, "calCtxEndCounter"))
		return FALSE;

    if (calExtGetProc((CALextproc*)&calCtxGetCounterExt, (CALextid)CAL_EXT_COUNTERS, "calCtxGetCounter"))
		return FALSE;

	return TRUE;	
}


CALresult Context::SetComputation(ArrayExpression* expr, Array* result, long priority, long flags, ArrayPool* arrs)
{
	long i, ind;
	long op = expr->op;	
	Array* arr;	
	Exclude excl;
	
	err = CAL_RESULT_OK;	
	
	// increment counters beforehand!	
	for(i = 0; (i < 3) && expr->args[i]; i++){expr->args[i]->useCounter++;}	
	result->useCounter++;
	result->isReservedForGet = TRUE;
			
	if( (op == OpIdentic) || (op == OpAdd) || (op == OpSub) || (op == OpDotProd) || (op == OpEwMul) || (op == OpEwDiv) || (op == OpMul) )
	{									
		for(i = 0; (err == CAL_RESULT_OK) && (i < 3) && expr->args[i]; i++)
		{	
			if(!expr->args[i]->localRes)	// is array already residing in the local memory?
			{
				err = expr->args[i]->AllocateLocal(0);

				// if does not work try to free some space in the local memory			
				if(err == CAL_RESULT_ERROR)
				{
					while( (arr = arrs->FindMinLocalNotInUse(&excl)) != NULL )
					{
						err = arr->FreeLocalKeepInRemote(ctx);
						if(err != CAL_RESULT_OK) // exclude argument from the search									
							excl.Add(arr);			
						else if( (err = expr->args[i]->AllocateLocal(0)) == CAL_RESULT_OK) 			
							break;
					}
					
					// if does not help - free currently unused arguments
					if(err != CAL_RESULT_OK)
					{
						while( (ind = arrs->FindMinLocalNotInUse1(NULL)) != -1 )
						{
							arrs->Remove(ind);
							if( (err = expr->args[i]->AllocateLocal(0)) == CAL_RESULT_OK) 			
								break;
						}
					}
				}
				
				// successfully allocated local memory
				if(err == CAL_RESULT_OK)
				{
					if(expr->args[i]->remoteRes)	// array data was already set and resides in the remote memory
					{
						err = expr->args[i]->CopyRemoteToLocal(ctx);
						expr->args[i]->FreeRemote();
					}
					else
						err = expr->args[i]->SetDataToLocal(ctx,expr->args[i]->cpuData);					
				}
			}
		}		
		
		if(err != CAL_RESULT_OK)		
		{
			// set use counters to their previous values
			i = 0;
			while(expr->args[i]){expr->args[i]->useCounter--; i++;}	
			result->useCounter--;
			result->isReservedForGet = FALSE;

			return err;
		}
		
		// allocate result array if necessary
		if(!result->localRes)
		{
			err = result->AllocateLocal(0);
			if(err != CAL_RESULT_OK) return err;
		}

		this->expr = expr;
		this->result = result;
	}
	else
		err = CAL_RESULT_NOT_SUPPORTED;

	return err;
}

ContextPool::ContextPool(void)
{
	err = CAL_RESULT_OK;
}


ContextPool::~ContextPool(void)
{	
	RemoveAll();
}

Context* ContextPool::Get(long ind)
{
	return (Context*)ObjectPool::Get(ind);
}

void ContextPool::Remove(long ind)
{
	Context* context = Get(ind);
	if(context)
		delete context;
	
	ObjectPool::Remove(ind);
}

long ContextPool::Find(long ctx)
{	
	CALcontext ctx_;
	long i;

	ctx_ = (CALcontext)(ctx);

	for(i = 0; (i < Length()) && ( (Get(i))->ctx != ctx_); i++);

	if(i < Length()) 
		return i; 
	else 
		return -1;
}

// perform the computation which was preliminary set by SetComputation
CALresult Context::DoComputation(void)
{	
	long i;

	if(!expr)	
		return CAL_RESULT_INVALID_PARAMETER;

	switch(expr->op)
	{
		case OpIdentic:
			err = DoIdentic();
			break;

		case OpAdd:
			err = DoElementwise();
			break;

		case OpSub:
			err = DoElementwise();
			break;

		case OpEwMul:
			err = DoElementwise();
			break;

		case OpEwDiv:
			err = DoElementwise();
			break;

		case OpMul:
			if( (expr->args[0]->nDims == 2) && (expr->args[1]->nDims == 1) )
				err = DoMatVec();
			else	
				err = CAL_RESULT_NOT_SUPPORTED;

			break;

		default:
			err = CAL_RESULT_NOT_SUPPORTED;
	}
	
	// decrement use counters
	if(err == CAL_RESULT_OK)
	{
		i = 0;
		while( (i < 3) && (expr->args[i]) ){expr->args[i]->useCounter--; i++;}	
		result->useCounter--;	
	}

	return err;
}

// perform assignment of array identity
CALresult Context::DoIdentic(void)
{
	Module* module;
	Constant* constant;
	Array* arg;	

	CALdomain domain;

	arg = expr->args[0];	

	if(result->nDims == arg->nDims)	// just copy data from one array to another
	{
		if(result->remoteRes)
		{
			if(arg->remoteRes)
				err = result->Copy(ctx,result->remoteRes,arg->remoteRes);
			else
				err = result->Copy(ctx,result->remoteRes,arg->localRes);
		}
		else
		{
			if(expr->args[0]->localRes)
				err = result->Copy(ctx,result->localRes,arg->localRes);
			else
				err = result->Copy(ctx,result->localRes,arg->remoteRes);					
		}
	}
	else
	{	
		// right hand side is a scalar
		_ASSERT( (arg->nDims == 1) && (arg->size[0] == 1) );

		// here we use a kernel which sets all data to the same value
		module = new Module(hDev,ctx,(Kernel*)kernels->Get(KernAssign));
		if(module->err == CAL_RESULT_OK)
		{
			// create constant for passing to the kernel
			constant = new Constant(module,0,arg->dType,1,arg->physNumComponents);	

			if(constant->err == CAL_RESULT_OK)
			{	
				// fill all constant components with one value
				err = constant->Fill(arg->cpuData,arg->elemSize);

				if(err == CAL_RESULT_OK)
				{
					// set the domain of execution
					domain.x = 0;
					domain.y = 0;
					if(result->nLogicDims == 1)
					{
						domain.width = result->physSize[0];
						domain.height = 1;
					}
					else
					{
						domain.width = result->physSize[1];
						domain.height = result->physSize[0];
					}

					// run the program
					err = RunGeneric(module,expr->args,&result,domain);
				}
			}
			else
				err = constant->err;
			
			delete constant;
		}
		else
			err = module->err;

		delete module;
	}	

	return err;
}

CALresult Context::RunGeneric(Module* module, Array** inputs, Array** outputs, CALdomain domain)
{
	long i;
	CALmem* inpMem;
	CALmem* outMem;	
	CALevent ev;

	err = CAL_RESULT_OK;

	inpMem = new CALmem[module->nInputs];
	outMem = new CALmem[module->nOutputs];
	FillMemory(&inpMem,0,module->nInputs*sizeof(CALmem));
	FillMemory(&outMem,0,module->nOutputs*sizeof(CALmem));		


	/*
		Set inputs
	*/
	for(i = 0; (err == CAL_RESULT_OK) && (i < module->nInputs); i++)
		err = inputs[i]->GetNamedLocalMem(ctx,module->inputNames[i],&inpMem[i]);

	if(err != CAL_RESULT_OK)
	{
		// release allocated resources
		for(i = i-1; i >= 0; i--)		
			calCtxReleaseMem(ctx,inpMem[i]);

		delete inpMem;
		delete outMem;
		return err;
	}

	/*
		Set outputs
	*/
	for(i = 0; (err == CAL_RESULT_OK) && (i < module->nOutputs); i++)
		err = outputs[i]->GetNamedLocalMem(ctx,module->outputNames[i],&outMem[i]);
	
	if(err != CAL_RESULT_OK)
	{
		// release allocated resources
		for(i = i-1; i >= 0; i--)		
			calCtxReleaseMem(ctx,outMem[i]);

		for( i = 0; i < module->nInputs; i++)
			calCtxReleaseMem(ctx,inpMem[i]);

		delete inpMem;
		delete outMem;
		return err;
	}

	// run the kernel
	err = calCtxRunProgram(&ev,ctx,module->func,&domain);
	if(err == CAL_RESULT_OK)
	{
		while((err = calCtxIsEventDone(ctx,ev)) == CAL_RESULT_PENDING);
	}

	for( i = 0; i < module->nInputs; i++)
		calCtxReleaseMem(ctx,inpMem[i]);

	for( i = 0; i < module->nOutputs; i++)
		calCtxReleaseMem(ctx,outMem[i]);

	delete inpMem;
	delete outMem;	

	return err;
}


// performs an elementwise operation
CALresult Context::DoElementwise(void)
{
	Module* module;
	CALdomain domain;

	err = CAL_RESULT_OK;

	switch(expr->dType)
	{
		case TREAL:
		{
			switch(expr->op)
			{
				case OpAdd:			
					module = new Module(hDev,ctx,(Kernel*)kernels->Get(KernAddR));			
					break;
				
				case OpSub:
					module = new Module(hDev,ctx,(Kernel*)kernels->Get(KernSubR));			
					break;

				case OpEwMul:
					module = new Module(hDev,ctx,(Kernel*)kernels->Get(KernEwMulR));			
					break;
				
				case OpEwDiv:
					module = new Module(hDev,ctx,(Kernel*)kernels->Get(KernEwDivR));			
					break;

				default:
					return CAL_RESULT_INVALID_PARAMETER;
			}			

		}break;

		case TLONGREAL:
		{
			switch(expr->op)
			{
				case OpAdd:			
					module = new Module(hDev,ctx,(Kernel*)kernels->Get(KernAddLR));			
					break;
				
				case OpSub:
					module = new Module(hDev,ctx,(Kernel*)kernels->Get(KernSubLR));			
					break;

				case OpEwMul:
					module = new Module(hDev,ctx,(Kernel*)kernels->Get(KernEwMulLR));			
					break;
				
				case OpEwDiv:
					module = new Module(hDev,ctx,(Kernel*)kernels->Get(KernEwDivLR));			
					break;

				default:
					return CAL_RESULT_INVALID_PARAMETER;
			}			

		}break;

		default:
			return CAL_RESULT_INVALID_PARAMETER;
	}

	if(module->err == CAL_RESULT_OK)
	{
		// set the domain of execution
		domain.x = 0;
		domain.y = 0;
		if(result->nLogicDims == 1)
		{
			domain.width = result->physSize[0];
			domain.height = 1;
		}
		else
		{
			domain.width = result->physSize[1];
			domain.height = result->physSize[0];
		}

		// run the program
		err = RunGeneric(module,expr->args,&result,domain);
	}
	else
		err = module->err;

	delete module;

	return err;
}

// start Idle counter
CALresult Context::StartIdleCounter(void)
{
	if(idleCounter)
		return calCtxBeginCounterExt(ctx,idleCounter);
	else
		return CAL_RESULT_NOT_SUPPORTED;
	
}

// start cache hit counter
CALresult Context::StartCacheHitCounter(void)
{
	if(cacheHitCounter)
		return calCtxBeginCounterExt(ctx,cacheHitCounter);
	else
		return CAL_RESULT_NOT_SUPPORTED;
}

// stop idle counter
CALresult Context::StopIdleCounter(void)
{
	if(idleCounter)
		return calCtxEndCounterExt(ctx,idleCounter);
	else
		return CAL_RESULT_NOT_SUPPORTED;
}

// stop cache hit counter
CALresult Context::StopCacheHitCounter(void)
{
	if(cacheHitCounter)
		return calCtxEndCounterExt(ctx,cacheHitCounter);
	else
		return CAL_RESULT_NOT_SUPPORTED;
}

// get idle counter value
CALresult Context::GetIdleCounter(float* counterVal)
{
	if(idleCounter)
		return calCtxGetCounterExt(counterVal,ctx,idleCounter);
	else
		return CAL_RESULT_NOT_SUPPORTED;
}

// get cache hit counter value
CALresult Context::GetCacheHitCounter(float* counterVal)
{
	if(cacheHitCounter)
		return calCtxGetCounterExt(counterVal,ctx,cacheHitCounter);
	else
		return CAL_RESULT_NOT_SUPPORTED;
}

// perform matrix vector operation
CALresult Context::DoMatVec(void)
{
	Module* module;
	CALdomain domain;
	Constant* constant;	

	err = CAL_RESULT_OK;
	
	module = new Module(hDev,ctx,(Kernel*)kernels->Get(KernMatVecR));

	if(module->err == CAL_RESULT_OK)
	{
		// create constant for passing to the kernel
		constant = new Constant(module,0,TLONGINT,1,1);	
		if(constant->err == CAL_RESULT_OK)
		{
		
			// set the domain of execution
			domain.x = 0;
			domain.y = 0;		
			domain.width = 1;
			domain.height = result->physSize[0];
						
			err = constant->Set(&(expr->args[0]->physSize[1]));
				
			// run the program
			if(err == CAL_RESULT_OK)			
				err = RunGeneric(module,expr->args,&result,domain);
		}
		else
			err = constant->err;
	}
	else
		err = module->err;

	delete module;

	return err;
}
