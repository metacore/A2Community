#include "StdAfx.h"
#include "Contexts.h"
#include "Kernels.h"
#include "Constants.h"

Context::Context(CALdevice hDev, CALdeviceinfo* devInfo, CALdeviceattribs* devAttribs, Kernel** kernels)
{		
	long i;

	expr = NULL;
	result = NULL;
	modules = NULL;
	isInUse = FALSE;

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

	modules = new Module*[NKernels];
	for(i = 0; i < NKernels; i++)
		modules[i] = NULL;
	
	this->kernels = kernels;
	this->hDev = hDev;
	this->devAttribs = devAttribs;	
	this->devInfo = devInfo;
}

Context::~Context(void)
{
	long i;

	if(modules)
	{
		for(i = 0; i < NKernels; i++)
		{
			if(modules[i])
				delete modules[i];
		}
		delete modules;
	}

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
	BOOL isReservedForGet0;

	// increment use counters beforehand!	
	for(i = 0; (i < 3) && expr->args[i]; i++){expr->args[i]->useCounter++;}	
	result->useCounter++;
	isReservedForGet0 = result->isReservedForGet;
	result->isReservedForGet = TRUE;	

	switch(expr->op)
	{
		case OpIdentic:
			err = SetCommon(expr,result,arrs,TRUE,FALSE);
			break;

		case OpAdd:
			err = SetCommon(expr,result,arrs,(expr->args[0] != result)&&(expr->args[1] != result),FALSE);
			break;

		case OpSub:
			err = SetCommon(expr,result,arrs,(expr->args[0] != result)&&(expr->args[1] != result),FALSE);
			break;

		case OpEwMul:
			err = SetCommon(expr,result,arrs,(expr->args[0] != result)&&(expr->args[1] != result),FALSE);
			break;

		case OpEwDiv:
			err = SetCommon(expr,result,arrs,(expr->args[0] != result)&&(expr->args[1] != result),FALSE);
			break;		

		case OpMul:
			if( (expr->args[0]->nDims == 2) && (expr->args[1]->nDims == 1) )
			{
				_ASSERT((expr->args[1] != result));
				err = SetCommon(expr,result,arrs,TRUE,FALSE);
			}
			else if( (expr->args[0]->nDims == 2) && (expr->args[1]->nDims == 2) )	// matrix multiplication
				err = SetCommon(expr,result,arrs,TRUE,TRUE);
			else	
				err = CAL_RESULT_NOT_SUPPORTED;
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
		result->isReservedForGet = isReservedForGet0;			
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

long ContextPool::FindNotUsed(void)
{		
	long i;	

	for(i = 0; (i < Length()) && Get(i)->isInUse; i++);

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
				err = DoMatVecMul();
			else if( (expr->args[0]->nDims == 2) && (expr->args[1]->nDims == 2) )
				err = DoMatMul();

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
CALresult Context::DoIdentic(void)
{	
	Module* module = NULL;	
	Array* arg;	
	long i, lw, pw, h, iKernel;
	float lastElem;

	char* pattern;

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

		_ASSERT(arg->IsScalar());
		
		if(result->nLogicDims == 1) {lw = result->logicSize[0]; pw = result->physSize[0]; h = 1;}
		else {lw = result->logicSize[1]; pw = result->physSize[1]; h = result->logicSize[0];}

		// if data parts are multiple of result->physNumComponents or it is memory clearing use KernFill_PS kernel
		if( result->IsZeroScalar()
			|| (result->physDataSize == result->dataSize)
			|| ((lw % result->physNumComponents) == 0)
			) /* ((w - (w*h - result->numElements)) % result->physNumComponents) == 0) remainder for the case of virtualization */
		{
			iKernel = KernFill_PS;
			if(!modules[iKernel])
				modules[iKernel] = new Module(hDev,ctx,kernels[iKernel]);

			module = modules[iKernel];

			if(module->err == CAL_RESULT_OK)
			{
				// create constant for passing to the kernel
				module->constants[0] = new Constant(hDev,ctx,module->constNames[0],arg->dFormat,1);	
				if(module->constants[0]->err == CAL_RESULT_OK)
					// fill all constant components with one value
					err = module->constants[0]->Fill(arg->cpuData,arg->elemSize);
				else
					err = module->constants[0]->err;				
			}
			else
			{
				err = module->err;	
				delete module;
				modules[iKernel] = NULL;
			}
		}
		else
		{
			iKernel = KernFill1_PS;
			if(!modules[iKernel])
				modules[iKernel] = new Module(hDev,ctx,kernels[iKernel]);

			module = modules[iKernel];

			if(module->err == CAL_RESULT_OK)
			{
				// create constant for passing to the kernel
				module->constants[0] = new Constant(hDev,ctx,module->constNames[0],arg->dFormat,2);	
				if(module->constants[0]->err == CAL_RESULT_OK)
				{
					pattern = new char[module->constants[0]->dataSize];	
					ZeroMemory(pattern,module->constants[0]->dataSize);

					for(i = 0; i < 2*result->physNumComponents - (pw*result->physNumComponents-lw); i++)
						CopyMemory(pattern+i*arg->elemSize,arg->cpuData,arg->elemSize);					

					err = module->constants[0]->SetData(pattern);

					delete pattern;

					if(err == CAL_RESULT_OK)
					{
						lastElem = (float)(lw/result->physNumComponents);						
						err = module->constants[1]->Fill(&lastElem,sizeof(lastElem));
					}
				}
				else
					err = module->constants[0]->err;					
			}
			else
			{
				err = module->err;	
				delete module;
				modules[iKernel] = NULL;
			}
		}		

		if(err == CAL_RESULT_OK)
		{
			err = module->SetConstantsToContext();

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
				err = module->RunPixelShader(expr->args,&result,NULL,&domain);

				module->ReleaseConstantsFromContext();
			}
		}

		if(module->constants[0])
		{
			delete module->constants[0];
			module->constants[0] = NULL;
		}
	}	

	return err;
}


// performs an elementwise operation
CALresult Context::DoElementwise(void)
{	
	Module* module;
	CALdomain domain;	

	long iKernel;
	
	err = CAL_RESULT_OK;

	switch(expr->dType)
	{
		case TREAL:
		{
			switch(expr->op)
			{
				case OpAdd: iKernel = KernAddR_PS; break;
				case OpSub: iKernel = KernSubR_PS; break;
				case OpEwMul: iKernel = KernEwMulR_PS; break;
				case OpEwDiv: iKernel = KernEwDivR_PS; break;

				default:
					return CAL_RESULT_INVALID_PARAMETER;
			}			

		}break;

		case TLONGREAL:
		{
			switch(expr->op)
			{
				case OpAdd: iKernel = KernAddLR_PS; break;
				case OpSub: iKernel = KernSubLR_PS; break;
				case OpEwMul: iKernel = KernEwMulLR_PS; break;
				case OpEwDiv: iKernel = KernEwDivLR_PS; break;

				default:
					return CAL_RESULT_INVALID_PARAMETER;
			}			

		}break;
		
		default:
			return CAL_RESULT_INVALID_PARAMETER;
	}	
	
	// get suited module
	if(!modules[iKernel])
		modules[iKernel] = new Module(hDev,ctx,kernels[iKernel]);	

	module = modules[iKernel];
	
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
		err = module->RunPixelShader(expr->args,&result,NULL,&domain);

	}
	else
	{
		err = module->err;
		delete modules[iKernel];
		modules[iKernel] = NULL;
	}

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

// perform matrix vector multiply operation
CALresult Context::DoMatVecMul(void)
{
	Module* module;
	CALdomain domain;
	float constData[4];

	long iKernel;
	
	err = CAL_RESULT_OK;

	switch(expr->dType)
	{
		case TREAL:
		{
			iKernel = KernMatVecR_PS; break;			

		}break;
		
		default:
			return CAL_RESULT_INVALID_PARAMETER;
	}	
	
	// get suited module
	if(!modules[iKernel])
		modules[iKernel] = new Module(hDev,ctx,kernels[iKernel]);	

	module = modules[iKernel];
	
	if(module->err == CAL_RESULT_OK)
	{		
		constData[0] = (float)(expr->args[0]->physSize[1]);	// matrix width
		constData[1] = 0;
		constData[2] = 0;
		constData[3] = 0;

		err = module->constants[0]->SetData(&constData);		
		if(err == CAL_RESULT_OK)
		{
			err = module->SetConstantsToContext();
			if(err == CAL_RESULT_OK)
			{
				// set the domain of execution
				domain.x = 0;
				domain.y = 0;		
				domain.width = result->physSize[0];
				domain.height = 1;

				// run the program				
				err = module->RunPixelShader(expr->args,&result,NULL,&domain);

				module->ReleaseConstantsFromContext();
			}
		}		
	}
	else
	{
		err = module->err;
		delete module;
		modules[iKernel] = NULL;
	}

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
			if(err != CAL_RESULT_OK) // exclude array from the search									
				excl.Add(tmp);			
			else if( (err = arr->AllocateLocal(flags)) == CAL_RESULT_OK) 			
				break;
		}

		// if does not help - free currently unused arrays
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


// setup an elementwise computation
CALresult Context::SetCommon(ArrayExpression* expr, Array* result, ArrayPool* arrs, BOOL overwritenResult, BOOL resultIsGlobalBuf)
{
	long i;	
	CALuint flags = 0;	

	err = CAL_RESULT_OK;	

	if(resultIsGlobalBuf)
		flags = CAL_RESALLOC_GLOBAL_BUFFER;

	if(overwritenResult)
	{
		// just in case try to free some space in the memory (result will be anyway overwritten)
		result->FreeRemote();
		if( result->localRes && ((!resultIsGlobalBuf && (result->localIsGlobalBuf)) || (resultIsGlobalBuf && (~result->localIsGlobalBuf))) )
			result->FreeLocal();

		// allocate result array if necessary			
		if(!result->localRes)
			err = AllocateArrayLocal(result,arrs,flags);
	}
	else
	{
		if(!result->localRes)
		{
			_ASSERT(result->remoteRes);

			err = AllocateArrayLocal(result,arrs,flags);
			if(err == CAL_RESULT_OK)
			{
				err = result->CopyRemoteToLocal(ctx);
				if(err == CAL_RESULT_OK)
					result->FreeRemote();
				else
					result->FreeLocal();
			}
		}
		else if(resultIsGlobalBuf && !result->localIsGlobalBuf )// if result has to be a global buffer bit it is not - convert to global
		{
			_ASSERT(FALSE);
		}
	}

	for(i = 0; (err == CAL_RESULT_OK) && (i < 3) && expr->args[i]; i++)
	{	
		if(expr->args[i] != result)
		{
			if(!expr->args[i]->localRes)	// is array already residing in the local memory?
			{
				// if not try to allocate it	
				err = AllocateArrayLocal(expr->args[i],arrs,0);
						
				if(err == CAL_RESULT_OK)
				{
					if(expr->args[i]->remoteRes)	// array data was already set and resides in the remote memory
					{
						err = expr->args[i]->CopyRemoteToLocal(ctx);
						if(err == CAL_RESULT_OK)
							expr->args[i]->FreeRemote();
						else
							expr->args[i]->FreeLocal();	
					}
					else
						err = expr->args[i]->SetDataToLocal(ctx,expr->args[i]->cpuData);					
				}
			}
			else
			{
				// FIXME: convert if possible to not a global buffer
				if(expr->args[i]->localIsGlobalBuf)
				{
					
				}
			}
		}
	}		

	return err;
}

// perform matrix matrix multiply operation
CALresult Context::DoMatMul(void)
{
/*
	if( (expr->args[0]->physSize[0] >= 8) && !(expr->args[1]->physSize[0] % 16) )
	{
		if( !(expr->args[0]->physSize[0] % 8) )
			err = DoMatMult4x8x4by4x4x4();
		else
			err = CAL_RESULT_NOT_SUPPORTED;
	}
	else if( (expr->args[0]->physSize[0] >= 8) && !(expr->args[1]->physSize[0] % 4) )
	{
		if( !(expr->args[0]->physSize[0] % 8) )
			err = DoMatMult8x4by4x4();
		else
			err = CAL_RESULT_NOT_SUPPORTED;
	}
	else if( (expr->args[0]->physSize[0] >= 4) && !(expr->args[1]->physSize[0] % 4) )
	{
		if( !(expr->args[0]->physSize[0] % 4) )
			err = DoMatMult4x4by4x4();
		else
			err = CAL_RESULT_NOT_SUPPORTED;
	}
	else
		err = CAL_RESULT_NOT_SUPPORTED;	
*/

	//err = DoMatMult4x8x4by4x4x4();
	//err = DoMatMult8x4by4x4();
	//err = DoMatMult4x4by4x4();

	//err = DoMatMultByParts4x4x4by4x4x4();
	err = DoMatMultByParts4x8x4by4x4x4();
	//err = DoMatMultByParts2x8x4by2x4x4();

	return err;
}

// divide a matrix to 4 parts
CALresult Context::DivideMatrixTo4Parts(Array* arr, Array*** parts)
{
	Module* module;
	CALdomain domain;
	CALcontext ctx1;
	long i, iKernel;
	long size[2];	
	
	err = CAL_RESULT_OK;	
	
	// array size for each part
	size[0] = arr->size[0]/4;
	size[1] = arr->size[1];

	// first create sub arrays
	(*parts) = new Array*[4];	
	for(i = 0; i < 4; i++)	
		(*parts)[i] = new Array(hDev,devInfo,devAttribs,arr->arrID,arr->dType,2,&size[0]);	
	
	// allocate arrays
	for(i = 0; (i < 4) && (err == CAL_RESULT_OK); i++)	
		err = (*parts)[i]->AllocateLocal(0);

	if(err != CAL_RESULT_OK)
	{
		for(i = 0; i < 4; i++)
			delete (*parts)[i];
		
		delete (*parts);
		(*parts) = NULL;

		return err;
	}
		
	iKernel = KernDivideMatrixTo4Parts_PS;
	
	err = calCtxCreate(&ctx1,hDev);
	module = new Module(hDev,ctx1,kernels[iKernel]);

	if(module->err == CAL_RESULT_OK)
	{							
		// set the domain of execution
		domain.x = 0;
		domain.y = 0;		
		domain.width = arr->physSize[1];
		domain.height = size[0];

		// run the program				
		err = module->RunPixelShader(&arr,*parts,NULL,&domain);

		if(err != CAL_RESULT_OK)			
		{
			for(i = 0; i < 4; i++)
				delete (*parts)[i];

			delete (*parts);
			(*parts) = NULL;
		}

	}
	else
		err = module->err;

	calCtxDestroy(ctx1);
	delete module;	
	
	return err;
}

// divide a matrix to 8 parts
CALresult Context::DivideMatrixTo8Parts(Array* arr, Array*** parts)
{
	Module* module;
	CALcontext ctx1;
	CALdomain domain;	
	long i, iKernel;
	long size[2];	
	
	err = CAL_RESULT_OK;
		
	// array size for each part
	size[0] = arr->size[0]/8;
	size[1] = arr->size[1];

	// first create sub arrays
	(*parts) = new Array*[8];	
	for(i = 0; i < 8; i++)	
		(*parts)[i] = new Array(hDev,devInfo,devAttribs,arr->arrID,arr->dType,2,&size[0]);	
	
	// allocate arrays
	for(i = 0; (i < 8) && (err == CAL_RESULT_OK); i++)	
		err = (*parts)[i]->AllocateLocal(0);

	if(err != CAL_RESULT_OK)
	{
		for(i = 0; i < 8; i++)
			delete (*parts)[i];
		
		delete (*parts);
		(*parts) = NULL;

		return err;
	}
	
	iKernel = KernDivideMatrixTo8Parts_PS;

	err = calCtxCreate(&ctx1,hDev);
	module = new Module(hDev,ctx1,kernels[iKernel]);

	if(module->err == CAL_RESULT_OK)
	{							
		// set the domain of execution
		domain.x = 0;
		domain.y = 0;		
		domain.width = arr->physSize[1];
		domain.height = size[0];

		// run the program				
		err = module->RunPixelShader(&arr,(*parts),NULL,&domain);

		if(err != CAL_RESULT_OK)			
		{
			for(i = 0; i < 8; i++)
				delete (*parts)[i];

			delete (*parts);
			(*parts) = NULL;
		}
			
	}
	else	
		err = module->err;	

	calCtxDestroy(ctx1);
	delete module;
	
	return err;
}


CALresult Context::DoMatMult4x8x4by4x4x4(void)
{
	Module* module;
	CALprogramGrid pg;
	float constData[8] = {0,0,0,0,0,0,0,0};

	long iKernel;
	
	err = CAL_RESULT_OK;

	switch(expr->dType)
	{
		case TREAL:
		{			
			iKernel = KernMatMul4x8x4by4x4x4R_CS; 		
			break;			

		}break;
		
		default:
			return CAL_RESULT_NOT_SUPPORTED;
	}	
	
	// get suited module
	if(!modules[iKernel])
		modules[iKernel] = new Module(hDev,ctx,kernels[iKernel]);	


	module = modules[iKernel];
	
	if(module->err == CAL_RESULT_OK)
	{	
		constData[0] = (float)(result->physSize[1]);				// result width
		constData[1] = (float)(result->pitch);						// alignment pitch for the result
		constData[2] = 1.0f/constData[0];							// 1/result.width
		constData[3] = (float)(result->physSize[0]/8)*constData[0];	// total number of 8x4 elements in the result
		constData[4] = (float)(expr->args[0]->physSize[1]);			// lhs width in quadruples

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
				pg.gridSize.width   = ((result->physNumElements/8 + pg.gridBlock.width - 1) / pg.gridBlock.width);
				pg.gridSize.height  = 1;
				pg.gridSize.depth   = 1;

				// run the program				
				err = module->RunComputeShader(expr->args,result,&pg);

				module->ReleaseConstantsFromContext();
			}
		}	
	}
	else
	{
		err = module->err;
		delete module;
		modules[iKernel] = NULL;
	}

	return err;
}

CALresult Context::DoMatMult8x4by4x4(void)
{
	Module* module;
	CALprogramGrid pg;
	float constData[8] = {0,0,0,0,0,0,0,0};

	long iKernel;
	
	err = CAL_RESULT_OK;

	switch(expr->dType)
	{
		case TREAL:
		{			
			iKernel = KernMatMul8x4by4x4R_CS; 		
			break;			

		}break;
		
		default:
			return CAL_RESULT_NOT_SUPPORTED;
	}	
	
	// get suited module
	if(!modules[iKernel])
		modules[iKernel] = new Module(hDev,ctx,kernels[iKernel]);	


	module = modules[iKernel];
	
	if(module->err == CAL_RESULT_OK)
	{	
		constData[0] = (float)(result->physSize[1]);				// result width
		constData[1] = (float)(result->pitch);						// alignment pitch for the result
		constData[2] = 1.0f/constData[0];							// 1/result.width
		constData[3] = (float)(result->physSize[0]/8)*constData[0];	// total number of 8x4 elements in the result
		constData[4] = (float)(expr->args[0]->physSize[1]);			// lhs width in quadruples

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
				pg.gridSize.width   = ((result->physNumElements/8 + pg.gridBlock.width - 1) / pg.gridBlock.width);
				pg.gridSize.height  = 1;
				pg.gridSize.depth   = 1;

				// run the program				
				err = module->RunComputeShader(expr->args,result,&pg);

				module->ReleaseConstantsFromContext();
			}
		}	
	}
	else
	{
		err = module->err;
		delete module;
		modules[iKernel] = NULL;
	}

	return err;
}

CALresult Context::DoMatMult4x4by4x4(void)
{
	Module* module;	
	CALprogramGrid pg;
	float constData[8] = {0,0,0,0,0,0,0,0};

	long iKernel;
	
	err = CAL_RESULT_OK;

	switch(expr->dType)
	{
		case TREAL:
		{			
			iKernel = KernMatMul4x4by4x4R_CS;
			break;			

		}break;
		
		default:
			return CAL_RESULT_NOT_SUPPORTED;
	}	
	
	// get suited module
	if(!modules[iKernel])
		modules[iKernel] = new Module(hDev,ctx,kernels[iKernel]);	

	module = modules[iKernel];
	
	if(module->err == CAL_RESULT_OK)
	{	
		constData[0] = (float)(result->physSize[1]);				// result width
		constData[1] = (float)(result->pitch);						// alignment pitch for the result
		constData[2] = 1.0f/constData[0];							// 1/result.width
		constData[3] = (float)(result->physSize[0]/4)*constData[0];	// total number of 8x4 elements in the result
		constData[4] = (float)(expr->args[0]->physSize[1]);			// lhs width in quadruples

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
				pg.gridSize.width   = ((result->physNumElements/4 + pg.gridBlock.width - 1) / pg.gridBlock.width);
				pg.gridSize.height  = 1;
				pg.gridSize.depth   = 1;
	
				// run the program				
				err = module->RunComputeShader(expr->args,result,&pg);				

				module->ReleaseConstantsFromContext();
			}
		}	
	}
	else
	{
		err = module->err;
		delete module;
		modules[iKernel] = NULL;
	}

	return err;
}

/*
CALresult Context::DoMatMult8x4by4x4(void)
{
	Module* module;
	CALprogramGrid pg;
	float constData[8] = {0,0,0,0,0,0,0,0};
	long i, iKernel;
	Array* arrs[12];

	Array** parts4 = NULL;
	Array** parts8 = NULL;

	err = CAL_RESULT_OK;

	// divide arrays to parts for efficiently cached computation
	err = DivideMatrixTo4Parts(expr->args[1],&parts4);
	if(err != CAL_RESULT_OK)
		return err;

	err = DivideMatrixTo8Parts(expr->args[0],&parts8);
	if(err != CAL_RESULT_OK)
		return err;		

	for(i = 0; i < 8; i++)
		arrs[i] = parts8[i];

	for(i = 0; i < 4; i++)
		arrs[i+8] = parts4[i];

		
	switch(expr->dType)
	{
		case TREAL:
		{
			iKernel = KernMatMulByParts4x8x4by4x4x4R_CS; break;			

		}break;
		
		default:	
		{
			for(i = 0; i < 12; i++)
				delete arrs[i];

			return CAL_RESULT_NOT_SUPPORTED;		
		}
	}	
	
	// get suited module
	if(!modules[iKernel])
		modules[iKernel] = new Module(hDev,ctx,kernels[iKernel]);	


	module = modules[iKernel];
	
	if(module->err == CAL_RESULT_OK)
	{	
		// set kernel constants		
		constData[0] = (float)(result->physSize[1]);				// result width
		constData[1] = (float)(result->pitch);						// alignment pitch for the result
		constData[2] = 1.0f/constData[0];							// 1/result.width
		constData[3] = (float)(result->physSize[0]/4)*constData[0];	// total number of 4x4 elements in the result
		constData[4] = (float)(expr->args[0]->physSize[1]);			// lhs width in quadruples
		
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
				pg.gridSize.width   = ((result->physNumElements/8  + pg.gridBlock.width - 1) / pg.gridBlock.width);
				pg.gridSize.height  = 1;
				pg.gridSize.depth   = 1;

				// run the program
				err = module->RunComputeShader(arrs,result,&pg);

				module->ReleaseConstantsFromContext();
			}
		}	
	}
	else
	{
		err = module->err;
		delete module;
		modules[iKernel] = NULL;
	}

	for(i = 0; i < 12; i++)
		delete arrs[i];

	return err;
}
*/


CALresult Context::DoMatMultByParts4x4x4by4x4x4(void)
{	
	Array** partsA = NULL;
	Array** partsB = NULL;
	Array** partsC = NULL;
	Array* inputs[8];
	long i, size[2];

	Module* module;
	CALdomain domain;
	float constData[4] = {0,0,0,0};

	long iKernel;

	err = CAL_RESULT_OK;
			
	switch(expr->dType)
	{
		case TREAL:
		{
			iKernel = KernMatMulByParts4x4x4by4x4x4R_PS; break;			

		}break;
		
		default:
			return CAL_RESULT_INVALID_PARAMETER;
	}	

	// divide arrays to parts for efficiently cached computation
	err = DivideMatrixTo4Parts(expr->args[0],&partsA);
	if(err != CAL_RESULT_OK)
		return err;

	err = DivideMatrixTo4Parts(expr->args[1],&partsB);
	if(err != CAL_RESULT_OK)
		return err;

	// allocate result parts

	// array size for each part
	size[0] = result->size[0]/4;
	size[1] = result->size[1];

	partsC = new Array*[4];	
	for(i = 0; i < 4; i++)	
		partsC[i] = new Array(hDev,devInfo,devAttribs,result->arrID,result->dType,2,&size[0]);
	
	// allocate parts
	for(i = 0; (i < 4) && (err == CAL_RESULT_OK); i++)	
		err = partsC[i]->AllocateLocal(0);

	if(err != CAL_RESULT_OK)
	{
		for(i = 0; i < 4; i++)
		{
			delete partsA[i];
			delete partsB[i];
			delete partsC[i];
		}

		return err;
	}

	for(i = 0; i < 4; i++)
	{
		inputs[i] = partsA[i];
		inputs[i+4] = partsB[i];
	}
	
	// get suited module
	if(!modules[iKernel])
		modules[iKernel] = new Module(hDev,ctx,kernels[iKernel]);	

	module = modules[iKernel];
	
	if(module->err == CAL_RESULT_OK)
	{		
		constData[0] = (float)(expr->args[0]->physSize[1]);	// matrix width		

		err = module->constants[0]->SetData(&constData);		
		if(err == CAL_RESULT_OK)
		{
			err = module->SetConstantsToContext();
			if(err == CAL_RESULT_OK)
			{
				// set the domain of execution
				domain.x = 0;
				domain.y = 0;		
				domain.width = result->physSize[1];
				domain.height = result->physSize[0]/4;

				// run the program				
				err = module->RunPixelShader(&inputs[0],partsC,NULL,&domain);

				module->ReleaseConstantsFromContext();
			}
		}		
	}
	else
	{
		err = module->err;
		delete module;
		modules[iKernel] = NULL;
	}

	for(i = 0; i < 4; i++)
	{
		delete partsA[i];
		delete partsB[i];
		delete partsC[i];
	}

	return err;
}

CALresult Context::DoMatMultByParts4x8x4by4x4x4(void)
{	
	Array** partsA = NULL;
	Array** partsB = NULL;
	Array** partsC = NULL;
	Array* inputs[16];
	long i, size[2];

	Module* module;
	CALdomain domain;
	float constData[4] = {0,0,0,0};

	long iKernel;

	err = CAL_RESULT_OK;
			
	switch(expr->dType)
	{
		case TREAL:
		{
			iKernel = KernMatMulByParts4x8x4by4x4x4R_PS; break;			

		}break;
		
		default:
			return CAL_RESULT_INVALID_PARAMETER;
	}	

	// divide arrays to parts for efficiently cached computation
	err = DivideMatrixTo8Parts(expr->args[0],&partsA);
	if(err != CAL_RESULT_OK)
		return err;

	err = DivideMatrixTo8Parts(expr->args[1],&partsB);
	if(err != CAL_RESULT_OK)
		return err;

	// allocate result parts

	// array size for each part
	size[0] = result->size[0]/8;
	size[1] = result->size[1];

	partsC = new Array*[8];	
	for(i = 0; i < 8; i++)	
		partsC[i] = new Array(hDev,devInfo,devAttribs,result->arrID,result->dType,2,&size[0]);
	
	// allocate parts
	for(i = 0; (i < 8) && (err == CAL_RESULT_OK); i++)	
		err = partsC[i]->AllocateLocal(0);

	if(err != CAL_RESULT_OK)
	{
		for(i = 0; i < 8; i++)
		{
			delete partsA[i];
			delete partsB[i];
			delete partsC[i];
		}

		return err;
	}

	for(i = 0; i < 8; i++)
	{
		inputs[i] = partsA[i];
		inputs[i+8] = partsB[i];
	}

	// get suited module
	if(!modules[iKernel])
		modules[iKernel] = new Module(hDev,ctx,kernels[iKernel]);	

	module = modules[iKernel];
	
	if(module->err == CAL_RESULT_OK)
	{		
		constData[0] = (float)(expr->args[0]->physSize[1]);	// matrix width		

		err = module->constants[0]->SetData(&constData);		
		if(err == CAL_RESULT_OK)
		{
			err = module->SetConstantsToContext();
			if(err == CAL_RESULT_OK)
			{
				// set the domain of execution
				domain.x = 0;
				domain.y = 0;		
				domain.width = result->physSize[1];
				domain.height = result->physSize[0]/8;

				// run the program				
				err = module->RunPixelShader(&inputs[0],partsC,NULL,&domain);

				module->ReleaseConstantsFromContext();
			}
		}		
	}
	else
	{
		err = module->err;
		delete module;
		modules[iKernel] = NULL;
	}

	for(i = 0; i < 8; i++)
	{
		delete partsA[i];
		delete partsB[i];
		delete partsC[i];
	}

	return err;
}

CALresult Context::DoMatMultByParts2x8x4by2x4x4(void)
{	
	Array** partsA = NULL;
	Array** partsB = NULL;
	Array** partsC = NULL;
	Array* inputs[16];
	long i, size[2];

	Module* module;
	CALdomain domain;
	float constData[4] = {0,0,0,0};

	long iKernel;

	err = CAL_RESULT_OK;
			
	switch(expr->dType)
	{
		case TREAL:
		{
			iKernel = KernMatMulByParts2x8x4by2x4x4R_PS; break;			

		}break;
		
		default:
			return CAL_RESULT_INVALID_PARAMETER;
	}	

	// divide arrays to parts for efficiently cached computation
	err = DivideMatrixTo8Parts(expr->args[0],&partsA);
	if(err != CAL_RESULT_OK)
		return err;

	err = DivideMatrixTo8Parts(expr->args[1],&partsB);
	if(err != CAL_RESULT_OK)
		return err;

	// allocate result parts

	// array size for each part
	size[0] = result->size[0]/8;
	size[1] = result->size[1];

	partsC = new Array*[8];	
	for(i = 0; i < 8; i++)	
		partsC[i] = new Array(hDev,devInfo,devAttribs,result->arrID,result->dType,2,&size[0]);
	
	// allocate parts
	for(i = 0; (i < 8) && (err == CAL_RESULT_OK); i++)	
		err = partsC[i]->AllocateLocal(0);

	if(err != CAL_RESULT_OK)
	{
		for(i = 0; i < 8; i++)
		{
			delete partsA[i];
			delete partsB[i];
			delete partsC[i];
		}

		return err;
	}

	for(i = 0; i < 8; i++)
	{
		inputs[i] = partsA[i];
		inputs[i+8] = partsB[i];
	}

	// get suited module
	if(!modules[iKernel])
		modules[iKernel] = new Module(hDev,ctx,kernels[iKernel]);	

	module = modules[iKernel];
	
	if(module->err == CAL_RESULT_OK)
	{		
		constData[0] = (float)(expr->args[0]->physSize[1]);	// matrix width		

		err = module->constants[0]->SetData(&constData);		
		if(err == CAL_RESULT_OK)
		{
			err = module->SetConstantsToContext();
			if(err == CAL_RESULT_OK)
			{
				// set the domain of execution
				domain.x = 0;
				domain.y = 0;		
				domain.width = result->physSize[1];
				domain.height = result->physSize[0]/8;

				// run the program
				//err = calCtxFlush(ctx);
								
				err = module->RunPixelShader(&inputs[0],partsC,NULL,&domain);				

				module->ReleaseConstantsFromContext();
			}
		}		
	}
	else
	{
		err = module->err;
		delete module;
		modules[iKernel] = NULL;
	}

	for(i = 0; i < 8; i++)
	{
		delete partsA[i];
		delete partsB[i];
		delete partsC[i];
	}

	return err;
}
