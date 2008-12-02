#include "StdAfx.h"
#include "Contexts.h"
#include "Kernels.h"
#include "Constants.h"

Context::Context(CALdevice hDev, CALdeviceattribs* devAttribs, KernelPool* kernels)
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
	this->devAttribs = devAttribs;
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
	long i;

	// increment use counters beforehand!	
	for(i = 0; (i < 3) && expr->args[i]; i++){expr->args[i]->useCounter++;}	
	result->useCounter++;
	result->isReservedForGet = TRUE;

	switch(expr->op)
	{
		case OpIdentic:
			err = SetElementwise(expr,result,arrs);
			break;

		case OpAdd:
			err = SetElementwise(expr,result,arrs);
			break;

		case OpSub:
			err = SetElementwise(expr,result,arrs);
			break;

		case OpEwMul:
			err = SetElementwise(expr,result,arrs);
			break;

		case OpEwDiv:
			err = SetElementwise(expr,result,arrs);
			break;

		case OpDotProd:
			err = SetElementwise(expr,result,arrs);
			break;
	}
	
	if(err == CAL_RESULT_OK)		
	{
		this->expr = expr;
		this->result = result;
	}
	else	// in case of an error set use counters to their previous values		
	{			
		for(i = 0; (i < 3) && expr->args[i]; i++){expr->args[i]->useCounter--;}	
		result->useCounter--;
		result->isReservedForGet = FALSE;			
	}

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
			err = DoIdenticCS();
			break;

		case OpAdd:
			err = DoElementwiseCS();
			break;

		case OpSub:
			err = DoElementwiseCS();
			break;

		case OpEwMul:
			err = DoElementwiseCS();
			break;

		case OpEwDiv:
			err = DoElementwiseCS();
			break;

		case OpMul:
			if( (expr->args[0]->nDims == 2) && (expr->args[1]->nDims == 1) )
				err = DoMatVecPS();
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

// perform assignment of array identity (using pixel shader)
CALresult Context::DoIdenticPS(void)
{	
	Module* module = NULL;
	Constant* constant = NULL;
	Array* arg;	
	long w, h;

	CALdomain domain;

	arg = expr->args[0];	

	if(result->dataSize == arg->dataSize)	// just copy data from one array to another
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
		
		if(result->physDataSize/result->physElemSize >= MinFillPhysNumElements_PS)	// if the result is sufficiently big use kernel method
		{
			if(result->nLogicDims == 1) {w = result->logicSize[0]; h = 1;}
			else {w = result->logicSize[1]; h = result->logicSize[0];}

			// if data parts are multiple of result->physNumComponents use KernFillByNComp_PS kernel
			if( result->IsZeroScalar()
				|| (result->physDataSize == result->dataSize)
				|| ( ((w % result->physNumComponents) == 0) && ( ((w - (w*h - result->numElements)) % result->physNumComponents) == 0) ) )
			{
				module = new Module(hDev,ctx,(Kernel*)kernels->Get(KernFillByNComp_PS));

				if(module->err == CAL_RESULT_OK)
				{
					// create constant for passing to the kernel
					constant = new Constant(hDev,ctx,module->constNames[0],arg->dFormat,1);	

					if(constant->err == CAL_RESULT_OK)				
						// fill all constant components with one value
						err = constant->Fill(arg->cpuData,arg->elemSize);
					else
						err = constant->err;				
				}
				else
					err = module->err;						
			}	
			else
				// FIXME: implement other cases
				err = CAL_RESULT_NOT_SUPPORTED;	

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
				err = RunPixelShader(module,expr->args,&result,NULL,&domain);
			}

			if(constant)
				delete constant;
			if(module)
				delete module;
		}
		else
			//if the result size is small it can be done just by using calResMap!
			err = CAL_RESULT_NOT_SUPPORTED;

	}	

	return err;
}

// perform assignment of array identity (using compute shader)
CALresult Context::DoIdenticCS(void)
{
	Module* module = NULL;
	Constant* constant = NULL;
	Array* arg;	
	CALprogramGrid pg;
	unsigned long w, w1, h, numBurstElems, nThreads;

	arg = expr->args[0];	

	if(result->dataSize == arg->dataSize)	// just copy data from one array to another
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
		
		// right hand side must be a scalar
		_ASSERT( (arg->nDims == 1) && (arg->size[0] == 1) );
		
		//
		// FIXME: make setting of the wavefrontsize in a dynamic way
		// this requires dynamic adding of "dcl_num_thread_per_group devAttribs->wavefrontSize\n" to all CS kernels strings
		//
		
		numBurstElems = GBufBurstSize/result->physElemSize;	// number of physical burst multicomponent elements
		nThreads = result->physNumElements/numBurstElems;	// total number of threads

		// if the result is sufficiently big use kernel method
		if(nThreads >= devAttribs->wavefrontSize)
		{
			// choose the right module
			if(result->nLogicDims == 1) {w = result->logicSize[0]*result->elemSize; h = 1; w1 = 0;}
			else {w1 = result->logicSize[1]; w = w1*result->elemSize; h = result->logicSize[0];}

			// if data parts are multiple of GBufBurstSize and number of threads fits to integer number of
			// NumThreadPerGroup use simplest kernels AND if tailed data do not have gaps (width is multipple of GPU alignment_pitch)
			if( ((w1 % devAttribs->pitch_alignment) == 0) && ((nThreads % devAttribs->wavefrontSize) == 0) && ( ((w % GBufBurstSize) == 0) && ( ((w - (w*h - result->dataSize)) % GBufBurstSize) == 0) ) )
			{				
				switch(numBurstElems)
				{
				case 2:
					module = new Module(hDev,ctx,(Kernel*)kernels->Get(KernFillBy2xNComp_CS));
					break;
				case 4:
					module = new Module(hDev,ctx,(Kernel*)kernels->Get(KernFillBy4xNComp_CS));
					break;
				case 8:
					module = new Module(hDev,ctx,(Kernel*)kernels->Get(KernFillBy8xNComp_CS));
					break;	
				case 16:
					module = new Module(hDev,ctx,(Kernel*)kernels->Get(KernFillBy16xNComp_CS));
					break;
				default:
					return CAL_RESULT_NOT_SUPPORTED;
				}

				if(module->err == CAL_RESULT_OK)
				{
					// create constant for passing to the kernel
					constant = new Constant(hDev,ctx,module->constNames[0],arg->dFormat,1);	

					if(constant->err == CAL_RESULT_OK)			
						// fill all constant components with one value
						err = constant->Fill(arg->cpuData,arg->elemSize);								
					else
						err = constant->err;				
				}
				else
					err = module->err;

				if(err == CAL_RESULT_OK)
				{					
					pg.flags = 0;
					pg.func = module->func;
					pg.gridBlock.width = devAttribs->wavefrontSize;
					pg.gridBlock.height = 1;
					pg.gridBlock.depth  = 1;
					pg.gridSize.width   = nThreads/devAttribs->wavefrontSize;
					pg.gridSize.height  = 1;
					pg.gridSize.depth   = 1;

					err = RunComputeShader(module,expr->args,result,&pg);
				}

				if(constant)
					delete constant;
				if(module)
					delete module;
			}
			else				
				err = DoIdenticPS();		
		}
		else			
			err = DoIdenticPS();
	}	

	return err;
}

CALresult Context::RunPixelShader(Module* module, Array** inputs, Array** outputs, Array* globalBuffer, CALdomain* domain)
{
	long i;
	CALmem* inpMem;
	CALmem* outMem;	
	CALmem gbufMem;
	CALevent ev;

	err = CAL_RESULT_OK;

	inpMem = new CALmem[module->nInputs];
	outMem = new CALmem[module->nOutputs];
	FillMemory(&inpMem,0,module->nInputs*sizeof(CALmem));
	FillMemory(&outMem,0,module->nOutputs*sizeof(CALmem));
	gbufMem = 0;

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

		for(i = 0; i < module->nInputs; i++)
			calCtxReleaseMem(ctx,inpMem[i]);

		delete inpMem;
		delete outMem;
		return err;
	}

	/*
		Set global buffer
	*/	
	if(globalBuffer)
	{
		err = globalBuffer->GetNamedLocalMem(ctx,module->gbufName,&gbufMem);

		if(err != CAL_RESULT_OK)
		{		
			// release allocated resources
			for(i = 0; i < module->nInputs; i++)
				calCtxReleaseMem(ctx,inpMem[i]);
	
			for(i = 0; i < module->nOutputs; i++)
				calCtxReleaseMem(ctx,outMem[i]);
	
			delete inpMem;
			delete outMem;
			return err;
		}
	}

	// run the kernel
	err = calCtxRunProgram(&ev,ctx,module->func,domain);
	if(err == CAL_RESULT_OK)
		while((err = calCtxIsEventDone(ctx,ev)) == CAL_RESULT_PENDING);

	// release allocated resources
	if(globalBuffer)
		calCtxReleaseMem(ctx,gbufMem);

	for( i = 0; i < module->nInputs; i++)
		calCtxReleaseMem(ctx,inpMem[i]);

	for( i = 0; i < module->nOutputs; i++)
		calCtxReleaseMem(ctx,outMem[i]);

	delete inpMem;
	delete outMem;

	return err;
}


// performs an elementwise operation using pixel shader
CALresult Context::DoElementwisePS(void)
{	
	Module* module;
	CALdomain domain;

	err = CAL_RESULT_OK;

	// run a pixel shader
	switch(expr->dType)
	{
		case TREAL:
		{
			switch(expr->op)
			{
				case OpAdd:			
					module = new Module(hDev,ctx,(Kernel*)kernels->Get(KernAddR_PS));			
					break;
				
				case OpSub:
					module = new Module(hDev,ctx,(Kernel*)kernels->Get(KernSubR_PS));			
					break;

				case OpEwMul:
					module = new Module(hDev,ctx,(Kernel*)kernels->Get(KernEwMulR_PS));			
					break;
				
				case OpEwDiv:
					module = new Module(hDev,ctx,(Kernel*)kernels->Get(KernEwDivR_PS));			
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
					module = new Module(hDev,ctx,(Kernel*)kernels->Get(KernAddLR_PS));			
					break;
				
				case OpSub:
					module = new Module(hDev,ctx,(Kernel*)kernels->Get(KernSubLR_PS));			
					break;

				case OpEwMul:
					module = new Module(hDev,ctx,(Kernel*)kernels->Get(KernEwMulLR_PS));			
					break;
				
				case OpEwDiv:
					module = new Module(hDev,ctx,(Kernel*)kernels->Get(KernEwDivLR_PS));			
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
		err = RunPixelShader(module,expr->args,&result,NULL,&domain);
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

// perform matrix vector operation using compute shader
CALresult Context::DoMatVecCS(void)
{
	return err;
}

// perform matrix vector operation using pixel shader
CALresult Context::DoMatVecPS(void)
{
/*
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
			domain.width = result->physSize[0];
			domain.height = 1;
						
			err = constant->Set(&(expr->args[0]->physSize[1]));
				
			// run the program
			if(err == CAL_RESULT_OK)			
				err = RunPixelShader(module,expr->args,&result,NULL,&domain);
		}
		else
			err = constant->err;

		delete constant;
	}
	else
		err = module->err;

	delete module;

*/
	return err;
}

// allocate an array with freeing space if necessary
CALresult Context::AllocateArrayLocal(Array* arr, ArrayPool* arrs, CALuint flags)
{
	long ind;
	Exclude excl;
	Array* tmp;

	err = arr->AllocateLocal(flags);

	// if does not work try to free some space in the local memory			
	if(err == CAL_RESULT_ERROR)
	{
		while( (tmp = arrs->FindMinLocalNotInUse(&excl)) != NULL )
		{
			err = tmp->FreeLocalKeepInRemote(ctx);
			if(err != CAL_RESULT_OK) // exclude argument from the search									
				excl.Add(tmp);			
			else if( (err = arr->AllocateLocal(flags)) == CAL_RESULT_OK) 			
				break;
		}

		// if does not help - free currently unused arguments
		if(err != CAL_RESULT_OK)
		{
			while( (ind = arrs->FindMinLocalNotInUse1(NULL)) != -1 )
			{
				arrs->Remove(ind);
				if( (err = arr->AllocateLocal(flags)) == CAL_RESULT_OK) 			
					break;
			}
		}
	}

	return err;
}

CALresult Context::RunComputeShader(Module* module, Array** inputs, Array* globalBuffer, CALprogramGrid* programGrid)
{	
	long i;
	CALmem* inpMem;	
	CALmem gbufMem;
	CALevent ev;

	err = CAL_RESULT_OK;

	inpMem = new CALmem[module->nInputs];	
	FillMemory(&inpMem,0,module->nInputs*sizeof(CALmem));	
	gbufMem = 0;

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
		return err;
	}	

	/*
		Set global buffer
	*/	
	if(globalBuffer)
	{
		err = globalBuffer->GetNamedLocalMem(ctx,module->gbufName,&gbufMem);

		if(err != CAL_RESULT_OK)
		{		
			// release allocated resources
			for(i = 0; i < module->nInputs; i++)
				calCtxReleaseMem(ctx,inpMem[i]);
				
			delete inpMem;	
			return err;
		}
	}

	// run the program
	err = calCtxRunProgramGrid(&ev,ctx,programGrid);
	if(err == CAL_RESULT_OK)
		while((err = calCtxIsEventDone(ctx,ev)) == CAL_RESULT_PENDING);	

	// release allocated resources
	if(globalBuffer)
		calCtxReleaseMem(ctx,gbufMem);

	for( i = 0; i < module->nInputs; i++)
		calCtxReleaseMem(ctx,inpMem[i]);	

	delete inpMem;	

	return err;	
}

// setup an elementwise computation
CALresult Context::SetElementwise(ArrayExpression* expr, Array* result, ArrayPool* arrs)
{
	long i;	
	CALuint flags;

	err = CAL_RESULT_OK;	

	flags = CAL_RESALLOC_GLOBAL_BUFFER;	// allocate arrays with posibility of using them as global buffers
	
	// just in case try to free some space in the remote memory (result will be anyway overwritten)
	result->FreeRemote();

	for(i = 0; (err == CAL_RESULT_OK) && (i < 3) && expr->args[i]; i++)
	{	
		if(!expr->args[i]->localRes)	// is array already residing in the local memory?
		{
			// if not try to allocate it	
			err = AllocateArrayLocal(expr->args[i],arrs,flags);
					
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
	
	// allocate result array if necessary
	if(err == CAL_RESULT_OK)
	{
		if(!result->localRes)		
			err = AllocateArrayLocal(result,arrs,flags);	
	}

	return err;
}

// perform an elementwise operation using compute shader
CALresult Context::DoElementwiseCS(void)
{
	Module* module;	
	CALprogramGrid pg;
	float constData[4];

	long iKernel;	
	
	err = CAL_RESULT_OK;

	switch(expr->dType)
	{
		case TREAL:
		{
			switch(expr->op)
			{
				case OpAdd: iKernel = KernAddR_CS; break;
				case OpSub: iKernel = KernSubR_CS; break;
				case OpEwMul: iKernel = KernEwMulR_CS; break;
				case OpEwDiv: iKernel = KernEwDivR_CS; break;

				default:
					return CAL_RESULT_INVALID_PARAMETER;
			}			

		}break;
		
		default:
			return CAL_RESULT_INVALID_PARAMETER;
	}	
	
	// get suited module
	module = new Module(hDev,ctx,(Kernel*)kernels->Get(iKernel));	
	
	if(module->err == CAL_RESULT_OK)
	{
		if(result->nLogicDims == 2)
		{
			constData[0] = (float)(result->physSize[1]);		// width
			constData[1] = 1.0f/(float)(result->physSize[1]);	// 1/width
			constData[2] = (float)(result->pitch);				// pitch in number of multicomponent elements
			constData[3] = (float)(result->physNumElements);	// total number of elements	
		}
		else
		{
			constData[0] = (float)(result->physSize[0]);		// width
			constData[1] = 1.0f/(float)(result->physSize[0]);	// 1/width
			constData[2] = 0;
			constData[3] = (float)(result->physNumElements);	// total number of elements
		}

		err = module->constants[0]->SetData(&constData);		
		if(err == CAL_RESULT_OK)
		{
			err = module->SetConstantsToContext();
			if(err == CAL_RESULT_OK)
			{
				pg.flags = 0;
				pg.func = module->func;
				pg.gridBlock.width = devAttribs->wavefrontSize;
				pg.gridBlock.height = 1;
				pg.gridBlock.depth  = 1;
				pg.gridSize.width   = ((result->physNumElements + pg.gridBlock.width - 1) / pg.gridBlock.width);
				pg.gridSize.height  = 1;
				pg.gridSize.depth   = 1;

				err = RunComputeShader(module,expr->args,result,&pg);

				module->ReleaseConstantsFromContext();
			}
		}		
	}
	else
		err = module->err;

	delete module;

	return err;
}
