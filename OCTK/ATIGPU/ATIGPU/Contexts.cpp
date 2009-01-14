#include "StdAfx.h"
#include "Contexts.h"
#include "Common.h"

Context::Context(CALdevice hDev, CALdeviceinfo* devInfo, CALdeviceattribs* devAttribs, ArrayPool* arrs, Kernel** kernels, CALresult* err)
{		
	long i;	

	isUsed = FALSE;
	modules = NULL;	
	expr = NULL;
	result = NULL;
	resultTemp = NULL;	

	idleCounter = 0;
	cacheHitCounter = 0;

	*err = calCtxCreate(&ctx,hDev);
	if(*err != CAL_RESULT_OK)
	{
		ctx = 0; 
		return;
	}	

	counterExtSupported = InitCounterExtension();

	if(counterExtSupported)
	{
		*err = calCtxCreateCounterExt(&idleCounter,ctx,CAL_COUNTER_IDLE);
		if(*err != CAL_RESULT_OK)
			idleCounter = 0;

		*err = calCtxCreateCounterExt(&cacheHitCounter,ctx,CAL_COUNTER_INPUT_CACHE_HIT_RATE);
		if(*err != CAL_RESULT_OK)		
			cacheHitCounter = 0;	
	}	

	modules = new Module*[NKernels];
	for(i = 0; i < NKernels; i++)
		modules[i] = NULL;
	
	this->hDev = hDev;
	this->kernels = kernels;	
	this->arrs = arrs;
	this->devInfo = devInfo;
	this->devAttribs = devAttribs;		
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

	if(expr)
		delete expr;

	if(idleCounter)
		calCtxDestroyCounterExt(ctx,idleCounter);

	if(cacheHitCounter)
		calCtxDestroyCounterExt(ctx,cacheHitCounter);	

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

// set computation
CALresult Context::SetComputation(ArrayExpression* expr, Array* result, long priority, long flags)
{	
	CALresult err;	
	BOOL isReservedForGet0;
	Array* arr, *arr1;
	long i;

	if(resultTemp)	
	{
		delete resultTemp;
		resultTemp = NULL;			
	}

	// increment use counters beforehand!	
	for(i = 0; (i < 2) && expr->args[i]; i++){expr->args[i]->useCounter++;}	
	result->useCounter++;
	isReservedForGet0 = result->isReservedForGet;
	result->isReservedForGet = TRUE;

	// check for the case when arguments are located on another device
	err = CAL_RESULT_OK;

	if(expr->op != OpIdentic)
	{
		for(i = 0; (err == CAL_RESULT_OK) && (i < 2) && (expr->args[i]); i++)
		{
			if(expr->args[i]->hDev != hDev)
			{
				arr1 = expr->args[i];

				// create array copy on the local device
				arr = arrs->NewArray(arr1->arrID,arr1->dType,arr1->nDims,arr1->size,arr1->cpuData);						

				if(!arr1->parts)			
					err = arrs->AllocateArray(arr,0);			
				else
					err = arrs->AllocateSplittedMatrix(arr,arr1->numParts,0);

				if(err == CAL_RESULT_OK)
				{
					if( (err = arr1->Copy(ctx,arr)) == CAL_RESULT_OK )
					{					
						arr1->useCounter--;					
						arr->useCounter++;
						expr->args[i] = arr;					

						// add to the local pool as a copy
						arr->isCopy = TRUE;
						arrs->Add(arr);					
					}
					else
						delete arr;
				}
				else
					delete arr;
			}
		}		

		if( (err == CAL_RESULT_OK) && (result->hDev != hDev) ) // if result array resides on another device
		{		
			arr = arrs->NewArray(result->arrID,result->dType,result->nDims,result->size,result->cpuData);
						
			((ArrayPool*)result->pool)->Remove(result);
			result = arr;
			result->useCounter++;
			result->isReservedForGet = TRUE;
			arrs->Add(result);			
		}
	}

	if(err != CAL_RESULT_OK) // in case of an error set use counters to their previous values				
	{			
		for(i = 0; (i < 2) && expr->args[i]; i++){expr->args[i]->useCounter--;}	
		result->useCounter--;
		result->isReservedForGet = isReservedForGet0;	

		delete expr;
		expr = NULL;

		return err;
	}

	// set computation accoring to the operation code
	switch(expr->op)
	{
		case OpIdentic:
			err = SetIdentic(expr,result);
			break;

		case OpAdd:
			err = SetElementwise(expr,result);
			break;

		case OpSub:
			err = SetElementwise(expr,result);
			break;

		case OpEwMul:
			err = SetElementwise(expr,result);
			break;

		case OpEwDiv:
			err = SetElementwise(expr,result);
			break;	

		case OpDotProd:
			err = SetDotProd(expr,result);
			break;

		case OpDiv:
			if( (expr->args[0]->IsScalar() && expr->args[1]->IsScalar()) || (expr->args[1]->IsScalar()) )
			{
				expr->op = OpEwDiv;
				err = SetElementwise(expr,result);
			}
			break;

		case OpMul:
			if( (expr->args[0]->nDims == 2) && (expr->args[1]->nDims == 1) )			
				err = SetMatVecMul(expr,result);
			else if( (expr->args[0]->nDims == 2) && (expr->args[1]->nDims == 2) )	// matrix multiplication
			{
				if(!expr->args[0]->firKernel && !expr->args[1]->firKernel)
					err = SetMatMul(expr,result);
				else
					err = SetConvolve(expr,result);
			}
			else if( expr->args[0]->IsScalar() || expr->args[1]->IsScalar() )
				err = SetScale(expr,result);
			else	
				err = CAL_RESULT_NOT_SUPPORTED;
			break;

		case OpReshape:
			err = SetReshape(expr,result);
			break;

		case OpTranspose:
			err = SetTranspose(expr,result);
			break;

		default:
			err = CAL_RESULT_INVALID_PARAMETER;
	}

	if(err == CAL_RESULT_OK)		
	{
		if(this->expr)
			delete this->expr;

		this->expr = expr;
		this->result = result;
	}
	else	// in case of an error set use counters to their previous values		
	{			
		for(i = 0; (i < 2) && expr->args[i]; i++){expr->args[i]->useCounter--;}	
		result->useCounter--;
		result->isReservedForGet = isReservedForGet0;	

		delete expr;
		expr = NULL;
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

ContextPool::ContextPool(void)
{
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

long ContextPool::FindUnused(void)
{		
	long i;	
	for(i = 0; (i < nObjs) && Get(i)->isUsed; i++);

	if(i < nObjs) 
		return i; 
	else 
		return -1;
}

// set an elementwise computation
CALresult Context::SetElementwise(ArrayExpression* expr, Array* result)
{
	CALresult err;	
	long i, j, numParts;

	err = CAL_RESULT_OK;	

	numParts = max(expr->args[0]->numParts,expr->args[1]->numParts);

	for(i = 0; (err == CAL_RESULT_OK) && (i < 2) && expr->args[i]; i++)
	{				
		if(!numParts) // no splitted matrices within the arguments
		{
			if(!expr->args[i]->res)	// array does not reside in the memory
			{
				// allocate array and set data
				if( (err = arrs->AllocateArray(expr->args[i],0)) == CAL_RESULT_OK )
					err = expr->args[i]->SetData(ctx,expr->args[i]->cpuData);
			}			
		}
		else
		{
			if(!expr->args[i]->res && !expr->args[i]->parts)	// array does not reside in the memory
			{
				// allocate splitted matrix and set data
				if( (err = arrs->AllocateSplittedMatrix(expr->args[i],numParts,0)) == CAL_RESULT_OK )
					err = expr->args[i]->SetData(ctx,expr->args[i]->cpuData);
			}
			else if(expr->args[i]->res)	// if array resides in the memory as a solid 2D piece
			{
				if( (err = arrs->AllocateSplittedMatrix(expr->args[i],numParts,0)) == CAL_RESULT_OK )
				{
					if( (err = SplitMatrix(expr->args[i],numParts,expr->args[i]->parts)) == CAL_RESULT_OK )
					{
						calResFree(expr->args[i]->res);
						expr->args[i]->res = 0;
					}
					else	// do cleanup
					{
						for(j = 0; j < numParts; j++)
							delete expr->args[i]->parts[j];
						
						expr->args[i]->parts = NULL;
						expr->args[i]->numParts = 0;
					}	
				}
			}
		}
	}

	if(err != CAL_RESULT_OK)
		return err;
	
	if(!numParts) // no splitted matrices within the arguments
	{			
		if(!result->res)	
		{
			result->Free();
			err = arrs->AllocateArray(result,0);			
		}
	}
	else if(!result->parts)	// if array resides in the memory as a solid 2D memory piece
	{
		result->Free();
		err = arrs->AllocateSplittedMatrix(result,numParts,0);
	}

	if(err != CAL_RESULT_OK)
		return err;	
	
	return err;
}

// split a matrix into given number of parts, convenient for matrix multiplication
CALresult Context::SplitMatrix(Array* arr, long numParts, Array** parts)
{	
	CALresult err;
	CALdomain domain;	
	KernelCode iKernel;		

	switch(numParts)
	{
		case 4: iKernel = KernSplitMatrixTo4Parts_PS;
			break;

		case 8: iKernel = KernSplitMatrixTo8Parts_PS;
			break;
		
		default:
			return CAL_RESULT_INVALID_PARAMETER;
	}	

	err = CAL_RESULT_OK;
	
	// get suited module
	if(!modules[iKernel])
	{
		modules[iKernel] = new Module(hDev,ctx,kernels[iKernel],&err);	
		if(err != CAL_RESULT_OK)
		{
			delete modules[iKernel];
			modules[iKernel] = NULL;
		}
	}
	
	if(err == CAL_RESULT_OK)
	{
		// set the domain of execution
		domain.x = 0;
		domain.y = 0;		
		domain.width = parts[0]->physSize[1];
		domain.height = parts[0]->physSize[0];		

		// run the program				
		err = modules[iKernel]->RunPixelShader(&arr,parts,NULL,&domain);
	}

	return err;
}

// perform a computation already set by SetComputation
CALresult Context::DoComputation(void)
{
	CALresult err;
	long i;

	if(!expr)	
		return CAL_RESULT_ERROR;	
	
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

	case OpDotProd:
		err = DoDotProd();
		break;

	case OpMul:
		if( (expr->args[0]->nDims == 2) && (expr->args[1]->nDims == 1) )
		{
			if(expr->args[0]->res)
				err = DoMatVecMul();
			else
				err = DoMatVecMulSplitted();
		}			
		else if( (expr->args[0]->nDims == 2) && (expr->args[1]->nDims == 2) )
			err = DoMatMul();
		else if( expr->args[0]->IsScalar() || expr->args[1]->IsScalar() )
				err = DoScale();

		break;

	case OpReshape:
		err = DoReshape();
		break;

	case OpTranspose:
		err = DoTranspose();
		break;

	default:
		err = CAL_RESULT_INVALID_PARAMETER;
	}		
	
	// decrement use counters	
	for(i = 0; (i < 2) && (expr->args[i]); i++){expr->args[i]->useCounter--;}	
	result->useCounter--;

	return err;
}

// perform an elementwise operation
CALresult Context::DoElementwise(void)
{	
	CALresult err;
	Module* module;
	CALdomain domain;	
	Array* inputs[2];	

	long i;
	KernelCode iKernel;
	
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
	{
		modules[iKernel] = new Module(hDev,ctx,kernels[iKernel],&err);		
		if(err != CAL_RESULT_OK)
		{
			delete modules[iKernel];
			modules[iKernel] = NULL;
		}
	}
	
	if(err == CAL_RESULT_OK)
	{				
		module = modules[iKernel];

		// set the domain of execution
		domain.x = 0;
		domain.y = 0;		

		if(!result->parts)
		{
			domain.width = result->physSize[1];
			domain.height = result->physSize[0];

			// run the program			
			err = module->RunPixelShader(expr->args,&result,NULL,&domain);		
		}
		else
		{
			domain.width = result->parts[0]->physSize[1];
			domain.height = result->parts[0]->physSize[0];			
			
			// run the program for each part separately
			for(i = 0; i < result->numParts; i++)
			{
				inputs[0] = expr->args[0]->parts[i];
				if(expr->args[1])
					inputs[1] = expr->args[1]->parts[i];

				err = module->RunPixelShader(inputs,&result->parts[i],NULL,&domain);
			}			
		}
	}	
	
	return err;
}

// set a matrix vector multiply computation
CALresult Context::SetMatVecMul(ArrayExpression* expr, Array* result)
{
	CALresult err;	

	if(expr->args[0]->isVirtualized || expr->args[1]->isVirtualized)
		return CAL_RESULT_NOT_SUPPORTED;

	err = CAL_RESULT_OK;	

	if(!expr->args[0]->res && !expr->args[0]->parts)
	{
		// allocate array and set data
		if( (err = arrs->AllocateArray(expr->args[0],0)) == CAL_RESULT_OK )
			err = expr->args[0]->SetData(ctx,expr->args[0]->cpuData);
	}

	if(err != CAL_RESULT_OK)
		return err;

	if(!expr->args[1]->res)
	{
		// allocate array and set data
		if( (err = arrs->AllocateArray(expr->args[1],0)) == CAL_RESULT_OK )
			err = expr->args[1]->SetData(ctx,expr->args[1]->cpuData);
	}

	if(err != CAL_RESULT_OK)
		return err;
	
	if(result == expr->args[1])
	{
		// result is within input arguments -> create temporary result array
		resultTemp = arrs->NewArray(result->arrID,result->dType,result->nDims,result->size,result->cpuData);
		err = arrs->AllocateArray(resultTemp,0);
		if(err != CAL_RESULT_OK)
		{
			delete resultTemp;
			resultTemp = NULL;
		}
		
	}	
	else if(!result->res)
	{
		result->Free();
		err = arrs->AllocateArray(result,0);
	}

	return err;
}

// perform a matrix vector multiplication
CALresult Context::DoMatVecMul(void)
{
	CALresult err;
	Module* module;
	CALdomain domain;
	KernelCode iKernel;	
	Array* arr;
	float constData[4];	
	
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
	{
		modules[iKernel] = new Module(hDev,ctx,kernels[iKernel],&err);		
		if(err != CAL_RESULT_OK)
		{
			delete modules[iKernel];
			modules[iKernel] = NULL;
		}
	}
	
	if(err == CAL_RESULT_OK)
	{		
		module = modules[iKernel];

		constData[0] = (float)(expr->args[0]->physSize[1]);	// matrix width		

		err = module->constants[0]->SetData(&constData);		
		if(err == CAL_RESULT_OK)
		{
			err = module->SetConstantsToContext();
			if(err == CAL_RESULT_OK)
			{
				if(!resultTemp)
					arr = result;
				else
					arr = resultTemp;

				// set the domain of execution
				domain.x = 0;
				domain.y = 0;		
				domain.width = arr->physSize[1];
				domain.height = 1;				
				
				err = module->RunPixelShader(expr->args,&arr,NULL,&domain);

				if( (err == CAL_RESULT_OK) && resultTemp )
				{												
					arrs->Set(arrs->Find(result->arrID),resultTemp);
					delete result;
					result = resultTemp;
					resultTemp = NULL;

					// do not forget about the flags!
					result->useCounter++;
					result->isReservedForGet = TRUE;
				}

				module->ReleaseConstantsFromContext();
			}
		}		
	}	

	return err;
}

// perform matrix vector multiplication for the case when matrix is splitted into parts
CALresult Context::DoMatVecMulSplitted(void)
{
	return CAL_RESULT_NOT_SUPPORTED;

	CALresult err;
	Module* module;
	CALdomain domain;
	KernelCode iKernel;	
	Array* inputs[9];
	Array* arr;
	float constData[4];	
	long i;
	
	err = CAL_RESULT_OK;

	switch(expr->args[0]->numParts)
	{
		case 4:

			switch(expr->dType)
			{
				case TREAL:
				{
					iKernel = KernMatVec4PartsR_PS; break;
				}break;
				
				default:					
					return CAL_RESULT_INVALID_PARAMETER;
			}
			break;

		case 8:

			switch(expr->dType)
			{
				case TREAL:
				{
					iKernel = KernMatVec8PartsR_PS; break;
				}break;
				
				default:					
					return CAL_RESULT_INVALID_PARAMETER;
			}
			break;
	}
	
	// get suited module
	if(!modules[iKernel])
	{
		modules[iKernel] = new Module(hDev,ctx,kernels[iKernel],&err);		
		if(err != CAL_RESULT_OK)
		{
			delete modules[iKernel];
			modules[iKernel] = NULL;
		}
	}
	
	if(err == CAL_RESULT_OK)
	{		
		module = modules[iKernel];

		constData[0] = (float)(expr->args[0]->physSize[1]);	// matrix width		

		err = module->constants[0]->SetData(&constData);		
		if(err == CAL_RESULT_OK)
		{
			err = module->SetConstantsToContext();
			if(err == CAL_RESULT_OK)
			{
				if(!resultTemp)
					arr = result;
				else
					arr = resultTemp;

				// set the domain of execution
				domain.x = 0;
				domain.y = 0;		
				domain.width = arr->physSize[1];
				domain.height = 1;	

				for(i = 0; i < expr->args[0]->numParts; i++)
					inputs[i] = expr->args[0]->parts[i];
				inputs[i] = expr->args[1];				

				err = module->RunPixelShader(inputs,&arr,NULL,&domain);
				
				if( (err == CAL_RESULT_OK) && resultTemp )
				{												
					arrs->Set(arrs->Find(result->arrID),resultTemp);
					delete result;
					result = resultTemp;
					resultTemp = NULL;

					// do not forget about the flags!
					result->useCounter++;
					result->isReservedForGet = TRUE;				
				}

				module->ReleaseConstantsFromContext();
			}
		}		
	}	
	
	return err;
}

// set a matrix multiplication computation
CALresult Context::SetMatMul(ArrayExpression* expr, Array* result)
{
	CALresult err;	
	long i, j;

	err = CAL_RESULT_OK;	

	if(result->isVirtualized || expr->args[0]->isVirtualized || expr->args[1]->isVirtualized)
		return CAL_RESULT_NOT_SUPPORTED;	

	// set array data if necessary
	for(i = 0; (i < 2) && (err == CAL_RESULT_OK); i++)
	{
		if(!expr->args[i]->res && !expr->args[i]->parts)
		{
			// allocate array and set data
			if(expr->args[i]->size[0] >= 8)		
				err = arrs->AllocateSplittedMatrix(expr->args[i],8,0);						
			else
				err = arrs->AllocateSplittedMatrix(expr->args[i],4,0);
	
			if(err == CAL_RESULT_OK)
				err = expr->args[i]->SetData(ctx,expr->args[i]->cpuData);	
		}
		else if(expr->args[i]->res)	// requires splitting
		{
			if(expr->args[i]->size[0] >= 8)		
				err = arrs->AllocateSplittedMatrix(expr->args[i],8,0);						
			else
				err = arrs->AllocateSplittedMatrix(expr->args[i],4,0);
	
			if(err == CAL_RESULT_OK)
			{
				err = SplitMatrix(expr->args[i],8,expr->args[i]->parts);
				if(err == CAL_RESULT_OK)
				{
					calResFree(expr->args[i]->res);
					expr->args[i]->res = 0;
				}
				else // do cleanup
				{
					for(j = 0; j < expr->args[i]->numParts; j++)
						delete expr->args[i]->parts[j];

					expr->args[i]->parts = NULL;
					expr->args[i]->numParts = 0;
				}
			}
		}
	}

	if(err != CAL_RESULT_OK)
		return err;

	if( (result == expr->args[0]) || (result == expr->args[1]) )
	{
		// result is within input arguments -> create temporary result array
		resultTemp = arrs->NewArray(result->arrID,result->dType,result->nDims,result->size,result->cpuData);
		err = arrs->AllocateSplittedMatrix(resultTemp,expr->args[0]->numParts,0);

		if(err != CAL_RESULT_OK)
		{
			delete resultTemp;
			resultTemp = NULL;
		}
	}
	else if(!result->parts)
	{
		result->Free();
		err = arrs->AllocateSplittedMatrix(result,expr->args[0]->numParts,0);
	}	

	return err;
}

// perform a matrix multiplication computation
CALresult Context::DoMatMul(void)
{
	CALresult err;
	Module* module;
	CALdomain domain;
	KernelCode iKernel;	
	Array* inputs[16];
	Array* arr;
	float constData[4];	
	long i;
	
	err = CAL_RESULT_OK;

	if(!expr->args[0]->isVirtualized && !expr->args[1]->isVirtualized)
	{
		if( (expr->args[0]->numParts == 8) && (expr->args[1]->numParts == 8) )
		{
			switch(expr->args[0]->dType)
			{
			case TREAL: iKernel = KernMatMul88Parts2x8x4by2x4x4R_PS; break;

			default:				
				return CAL_RESULT_NOT_SUPPORTED;
			}
		}
		else		
			return CAL_RESULT_NOT_SUPPORTED;

		// get suited module
		if(!modules[iKernel])
		{
			modules[iKernel] = new Module(hDev,ctx,kernels[iKernel],&err);		
			if(err != CAL_RESULT_OK)
			{
				delete modules[iKernel];
				modules[iKernel] = NULL;
			}
		}

		if(err == CAL_RESULT_OK)
		{		
			module = modules[iKernel];

			constData[0] = (float)(expr->args[0]->physSize[1]);	// matrix width		

			err = module->constants[0]->SetData(&constData);		
			if(err == CAL_RESULT_OK)
			{
				err = module->SetConstantsToContext();
				if(err == CAL_RESULT_OK)
				{
					if(!resultTemp)
						arr = result;
					else
						arr = resultTemp;

					// set the domain of execution
					domain.x = 0;
					domain.y = 0;		
					domain.width = arr->parts[0]->physSize[1];
					domain.height = arr->parts[0]->physSize[0];	

					for(i = 0; i < expr->args[0]->numParts; i++)				
						inputs[i] = expr->args[0]->parts[i];
					for(i = 0; i < expr->args[1]->numParts; i++)
						inputs[i+expr->args[0]->numParts] = expr->args[1]->parts[i];

					err = module->RunPixelShader(inputs,arr->parts,NULL,&domain);				
					if( (err == CAL_RESULT_OK) && resultTemp )
					{																	
						arrs->Set(arrs->Find(result->arrID),resultTemp);
						delete result;
						result = resultTemp;
						resultTemp = NULL;

						// do not forget about the flags!
						result->useCounter++;
						result->isReservedForGet = TRUE;					
					}

					module->ReleaseConstantsFromContext();
				}
			}		
		}	
	}
	else
	{
		err = CAL_RESULT_NOT_SUPPORTED;
	}

	return err;
}

// set a reshape computation
CALresult Context::SetReshape(ArrayExpression* expr, Array* result)
{	
	CALresult err;

	err = CAL_RESULT_OK;

	if(result == expr->args[0])	// input and output conicide -> do nothing
		return err;	
	
	if(!expr->args[0]->res && !expr->args[0]->parts)
	{
		if( (err = arrs->AllocateArray(expr->args[0],0)) == CAL_RESULT_OK )
			err = expr->args[0]->SetData(ctx,expr->args[0]->cpuData);
	}	

	if(err != CAL_RESULT_OK)
		return err;	
	
	if( (expr->args[0]->arrID != -3)  && (!result->res || result->parts) )	// prefer not to have result being splitted...
	{
		result->Free();
		err = arrs->AllocateArray(result,0);
	}

	return err;
}

// perform a reshape computation
CALresult Context::DoReshape(void)
{
	CALresult err;	
	KernelCode iKernel;
	Module* module;
	CALdomain domain;		
	long constData[4];
	Array** inputs;

	err = CAL_RESULT_OK;

	if(result == expr->args[0])	// do nothing
		return err;

	inputs = expr->args;
	
	if(expr->args[0]->isVirtualized && result->isVirtualized)
	{
		// no explicit reshape is required!	

		if(expr->args[0]->arrID == -3)	// overwiritten result array
		{
			result->res = expr->args[0]->res;
			expr->args[0]->res = 0;
		}
		else
			return expr->args[0]->Copy(ctx,result);		
	}
	else if(!expr->args[0]->isVirtualized && !result->isVirtualized)
	{
		if( !(expr->args[0]->size[1] % expr->args[0]->physNumComponents) && !(result->size[result->nDims-1] % result->physNumComponents) )
		{			
			iKernel = KernReshapeMatToMatNoBounds_PS;
			constData[0] = expr->args[0]->physSize[1];	// A.physWidth
			constData[1] = result->physSize[1];			// C.physWidth						
		}
		else
			return CAL_RESULT_NOT_SUPPORTED;
	}
	else if(expr->args[0]->isVirtualized && !result->isVirtualized)
	{
		if(expr->args[0]->elemSize == 4)
		{
			iKernel = KernReshapeArr1DWToMat4DW_PS;
			constData[0] = expr->args[0]->physSize[1];	// A.physWidth					
			constData[1] = result->physSize[1];			// C.physWidth
			constData[2] = result->size[1];				// C.width			
		}
		else
			return CAL_RESULT_NOT_SUPPORTED;
	}
	else if(!expr->args[0]->isVirtualized && result->isVirtualized)
	{		
		if(result->elemSize == 4)
		{			
			if(expr->args[0]->numParts == 0)		
				iKernel = KernReshapeMat4DWToArr1DW_PS;			
			else if(expr->args[0]->numParts == 4)
			{				
				iKernel = KernReshapeMat4Parts4DWToArr1DW_PS;
				inputs = expr->args[0]->parts;
			}
			else if(expr->args[0]->numParts == 8)
			{
				iKernel = KernReshapeMat8Parts4DWToArr1DW_PS;
				inputs = expr->args[0]->parts;
			}
			else
				return CAL_RESULT_ERROR;

			constData[0] = result->physSize[1];		// C.physWidth
			constData[1] = expr->args[0]->size[1];	// A.Width
		}
		else
			return CAL_RESULT_NOT_SUPPORTED;		
	}
	else
		return CAL_RESULT_NOT_SUPPORTED;

	// get suited module
	if(!modules[iKernel])
	{
		modules[iKernel] = new Module(hDev,ctx,kernels[iKernel],&err);		
		if(err != CAL_RESULT_OK)
		{
			delete modules[iKernel];
			modules[iKernel] = NULL;
		}
	}
	
	if(err == CAL_RESULT_OK)
	{		
		module = modules[iKernel];		

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
				domain.height = result->physSize[0];

				err = module->RunPixelShader(inputs,&result,NULL,&domain);				
				
				module->ReleaseConstantsFromContext();
			}
		}		
	}

	return err;
}


// zero array memory
CALresult Context::ZeroArrayMemory(Array* arr, CALdomain* domain)
{
	CALresult err;	
	
	err = CAL_RESULT_OK;	
	
	// get suited module
	if(!modules[KernZeroMemory_PS])
	{
		modules[KernZeroMemory_PS] = new Module(hDev,ctx,kernels[KernZeroMemory_PS],&err);		
		if(err != CAL_RESULT_OK)
		{
			delete modules[KernZeroMemory_PS];
			modules[KernZeroMemory_PS] = NULL;
		}
	}
	
	if(err == CAL_RESULT_OK)
	{
		// run the program			
		err = modules[KernZeroMemory_PS]->RunPixelShader(NULL,&arr,NULL,domain);				
	}	

	return err;
}

// set a transpose computation
CALresult Context::SetTranspose(ArrayExpression* expr, Array* result)
{
	CALresult err;	
	long i;

	err = CAL_RESULT_OK;	

	if(result == expr->args[0])
	{
		for(i = 0; (i < result->nDims) && (expr->transpDims[i] == i); i++);

		if(i == result->nDims)	// identity transposition - do nothing
			return err;
	}	

	if(!expr->args[0]->res && !expr->args[0]->parts)
	{
		expr->args[0]->Free();	// if splitted free; FIXME: implement kernels which can handle splitted matrices directly!
		if( (err = arrs->AllocateArray(expr->args[0],0)) == CAL_RESULT_OK )
			err = expr->args[0]->SetData(ctx,expr->args[0]->cpuData);
	}

	if(err != CAL_RESULT_OK)
		return err;

	if(result == expr->args[0])
	{
		// result is within input arguments -> create temporary result array
		resultTemp = arrs->NewArray(result->arrID,result->dType,result->nDims,result->size,result->cpuData);
		err = arrs->AllocateArray(resultTemp,0);
		if(err != CAL_RESULT_OK)
		{
			delete resultTemp;
			resultTemp = NULL;
		}		
	}	
	else if(!result->res)	// prefer result being not splitted...
	{
		result->Free();
		err = arrs->AllocateArray(result,0);
	}

	return err;
}
// perform a transpose computation
CALresult Context::DoTranspose(void)
{
	CALresult err;
	KernelCode iKernel;
	Module* module;
	CALdomain domain;		
	long i, constData[12];
	Array* arr;

	err = CAL_RESULT_OK;

	if(result != expr->args[0])
		arr = result;
	else
		arr = resultTemp;

	if(arr == expr->args[0]) // identity transposition -> do nothing
		return err;

	if(expr->args[0]->isVirtualized && arr->isVirtualized)
	{		
		if(result->nDims == 3)
		{
			iKernel = KernTranspose3D_PS;

			constData[0] = arr->physSize[1];								// physWidth
			constData[1] = arr->size[1]*arr->size[2];						// C.Ny*C.Nx
			constData[2] = arr->size[2];									// C.Nx
			constData[3] = 1;

			constData[4] = expr->transpDims[0];
			constData[5] = expr->transpDims[1];
			constData[6] = expr->transpDims[2];
			constData[7] = 0;

			constData[8] = expr->args[0]->size[1]*expr->args[0]->size[2];	// A.Ny*A.Nx
			constData[9] = expr->args[0]->size[2];							// A.Nx			
			constData[10] = 1;												// 1
		}
		else if(result->nDims == 4)
		{
			iKernel = KernTranspose4D_PS;

			constData[0] = arr->physSize[1];								// physWidth
			constData[1] = arr->size[1]*arr->size[2]*arr->size[3];			// C.Nz*C.Ny*C.Nx
			constData[2] = arr->size[2]*arr->size[3];						// C.Ny*C.Nx
			constData[3] = arr->size[3];									// C.Nx			

			constData[4] = expr->transpDims[0];
			constData[5] = expr->transpDims[1];
			constData[6] = expr->transpDims[2];
			constData[7] = expr->transpDims[3];;
			
			constData[8] = expr->args[0]->size[1]*expr->args[0]->size[2]*expr->args[0]->size[3];	// A.Nz*A.Ny*A.Nx
			constData[9] = expr->args[0]->size[2]*expr->args[0]->size[3];							// A.Ny*A.Nx
			constData[10] = expr->args[0]->size[3];													// A.Nx			
			constData[11] = 1;																		// 1
		}
		else				
			return CAL_RESULT_NOT_SUPPORTED;	
	}
	else if(!expr->args[0]->isVirtualized && !arr->isVirtualized)
	{	
		if( (expr->transpDims[0] == 1) && (expr->transpDims[1] == 0) )
		{
			if(!expr->args[0]->parts && !arr->parts)
				iKernel = KernTransposeMat4DW_PS;
			else			
				return CAL_RESULT_NOT_SUPPORTED;		
		}
		else	// just copy the data
		{
			if(!expr->args[0]->parts && !arr->parts)
				err = expr->args[0]->Copy(ctx,arr);
			else if(expr->args[0]->parts && arr->parts)
			{				
				for(i = 0; (i < arr->numParts) && (err == CAL_RESULT_OK); i++)
					err = expr->args[0]->parts[i]->Copy(ctx,arr->parts[i]);
			}
			else			
				return CAL_RESULT_NOT_SUPPORTED;		

			return err;
		}
	}	
	else	
		return CAL_RESULT_INVALID_PARAMETER;

	// get suited module
	if(!modules[iKernel])
	{
		modules[iKernel] = new Module(hDev,ctx,kernels[iKernel],&err);		
		if(err != CAL_RESULT_OK)
		{
			delete modules[iKernel];
			modules[iKernel] = NULL;
		}
	}
	
	if(err == CAL_RESULT_OK)
	{		
		module = modules[iKernel];		
		
		if(module->nConstants)
			err = module->constants[0]->SetData(&constData);

		if(err == CAL_RESULT_OK)
		{
			if(module->nConstants)
				err = module->SetConstantsToContext();

			if(err == CAL_RESULT_OK)
			{	
				// set the domain of execution
				domain.x = 0;
				domain.y = 0;		
				domain.width = arr->physSize[1];
				domain.height = arr->physSize[0];

				err = module->RunPixelShader(expr->args,&arr,NULL,&domain);

				if( (err == CAL_RESULT_OK) && resultTemp )
				{					
					arrs->Set(arrs->Find(result->arrID),resultTemp);
					delete result;
					result = resultTemp;
					resultTemp = NULL;

					// do not forget about the flags!
					result->useCounter++;
					result->isReservedForGet = TRUE;
				}
				
				module->ReleaseConstantsFromContext();
			}
		}		
	}	
	
	return err;

/*
	CALresult err;
	KernelCode iKernel;
	Module* module;
	CALdomain domain;		
	long i, constData[12];
	Array* arr;	

	err = CAL_RESULT_OK;

	if(result != expr->args[0])
		arr = result;
	else
		arr = resultTemp;

	if(expr->args[0]->isVirtualized && arr->isVirtualized)
	{		
		if(result->nDims == 3)
		{
			iKernel = KernTranspose3D_PS;

			constData[0] = result->physSize[1];				// physWidth
			constData[1] = result->size[1]*result->size[2];	// C.Ny*C.Nx
			constData[2] = result->size[2];					// C.Nx
			constData[3] = 1;

			constData[4] = expr->transpDims[0];
			constData[5] = expr->transpDims[1];
			constData[6] = expr->transpDims[2];
			constData[7] = 0;

			constData[8] = expr->args[0]->size[1]*expr->args[0]->size[2];	// A.Ny*A.Nx
			constData[9] = expr->args[0]->size[2];							// A.Nx			
			constData[10] = 1;												// 1
		}
		else if(result->nDims == 4)
		{
			iKernel = KernTranspose4D_PS;

			constData[0] = result->physSize[1];								// physWidth
			constData[1] = result->size[1]*result->size[2]*result->size[3];	// C.Nz*C.Ny*C.Nx
			constData[2] = result->size[2]*result->size[3];					// C.Ny*C.Nx
			constData[3] = result->size[3];									// C.Nx			

			constData[4] = expr->transpDims[0];
			constData[5] = expr->transpDims[1];
			constData[6] = expr->transpDims[2];
			constData[7] = expr->transpDims[3];;
			
			constData[8] = expr->args[0]->size[1]*expr->args[0]->size[2]*expr->args[0]->size[3];	// A.Nz*A.Ny*A.Nx
			constData[9] = expr->args[0]->size[2]*expr->args[0]->size[3];							// A.Ny*A.Nx
			constData[10] = expr->args[0]->size[3];													// A.Nx			
			constData[11] = 1;																		// 1
		}
		else
			return CAL_RESULT_NOT_SUPPORTED;		
	}
	else if(!expr->args[0]->isVirtualized && !arr->isVirtualized)
	{	
		if( (expr->transpDims[0] == 1) && (expr->transpDims[1] == 0) )
		{
			if(!expr->args[0]->parts && !arr->parts)
				iKernel = KernTransposeMat4DW_PS;
			else
				return CAL_RESULT_NOT_SUPPORTED;
		}
		else	// just copy the data
		{
			if(!expr->args[0]->parts && !arr->parts)
				err = ResCopy(ctx,arr->res,expr->args[0]->res);
			else if(expr->args[0]->parts && arr->parts)
			{				
				for(i = 0; (i < arr->numParts) && (err == CAL_RESULT_OK); i++)
					err = ResCopy(ctx,arr->parts[i]->res,expr->args[0]->parts[i]->res);
			}
			else
				return CAL_RESULT_NOT_SUPPORTED;

			return err;
		}
	}	
	else
		return CAL_RESULT_INVALID_PARAMETER;

	// get suited module
	if(!modules[iKernel])
	{
		modules[iKernel] = new Module(hDev,ctx,kernels[iKernel],&err);		
		if(err != CAL_RESULT_OK)
		{
			delete modules[iKernel];
			modules[iKernel] = NULL;
		}
	}
	
	if(err == CAL_RESULT_OK)
	{		
		module = modules[iKernel];		
		
		if(module->nConstants)
			err = module->constants[0]->SetData(&constData);		
		if(err == CAL_RESULT_OK)
		{
			if(module->nConstants)
				err = module->SetConstantsToContext();
			if(err == CAL_RESULT_OK)
			{	
				// set the domain of execution
				domain.x = 0;
				domain.y = 0;		
				domain.width = arr->physSize[1];
				domain.height = arr->physSize[0];

				err = module->RunPixelShader(expr->args,&arr,NULL,&domain);

				if( (err == CAL_RESULT_OK) && resultTemp )
				{					
					resultTemp->res = result->res;
					result->res = 0;
					delete result;

					arrs->Set(arrs->Find(resultTemp->arrID),resultTemp);					
					result = resultTemp;
					resultTemp = NULL;
				}
				
				module->ReleaseConstantsFromContext();
			}
		}		
	}	
		

	return err;
*/
}


// set an identic operation
CALresult Context::SetIdentic(ArrayExpression* expr, Array* result)
{
	CALresult err;

	err = CAL_RESULT_OK;		

	if(!expr->args[0]->IsScalar() || result->IsScalar())
	{
		if(expr->args[0] != result)
		{
			if(!expr->args[0]->res && !expr->args[0]->parts)
			{
				if(!result->res && !result->parts)
				{
					if( (err = ((ArrayPool*)result->pool)->AllocateArray(result,0)) == CAL_RESULT_OK )
						err = result->SetData(ctx,expr->args[0]->cpuData);
				}

			}
			else if(!expr->args[0]->parts) // src is not a splitted matrix
			{
				if(!result->res)
				{
					result->Free();
					err = ((ArrayPool*)result->pool)->AllocateArray(result,0);						
				}
			}
			else // src is a splitted matrix
			{
				if(!result->parts)
				{
					result->Free();
					err = ((ArrayPool*)result->pool)->AllocateSplittedMatrix(result,expr->args[0]->numParts,0);
				}
			}
		}
	}
	else
		return CAL_RESULT_NOT_SUPPORTED;	

	return err;
}

// do an identic operation
CALresult Context::DoIdentic(void)
{
	CALresult err;	

	err = CAL_RESULT_OK;
	
	if(expr->args[0] != result)
	{
		if(!expr->args[0]->IsScalar() || result->IsScalar())
		{						
			if(expr->args[0]->res || expr->args[0]->parts)
				err = expr->args[0]->Copy(ctx,result);
			else if(expr->args[0]->cpuData)
				return err;
			else
				err = CAL_RESULT_ERROR;			
		}
		else
		{
			return CAL_RESULT_NOT_SUPPORTED;
		}			
	}

	return err;
}

// set a dot product computation
CALresult Context::SetDotProd(ArrayExpression* expr, Array* result)
{
	CALresult err;		
	long i, j, numParts;
	long size;

	err = CAL_RESULT_OK;
	
	numParts = max(expr->args[0]->numParts,expr->args[1]->numParts);

	for(i = 0; (err == CAL_RESULT_OK) && (i < 2) && expr->args[i]; i++)
	{				
		if(!numParts) // no splitted matrices within the arguments
		{
			if(!expr->args[i]->res)	// array does not reside in the memory
			{
				// allocate array and set data
				if( (err = arrs->AllocateArray(expr->args[i],0)) == CAL_RESULT_OK )
					err = expr->args[i]->SetData(ctx,expr->args[i]->cpuData);
			}			
		}
		else
		{
			if(!expr->args[i]->res && !expr->args[i]->parts)	// array does not reside in the memory
			{
				// allocate splitted matrix and set data
				if( (err = arrs->AllocateSplittedMatrix(expr->args[i],numParts,0)) == CAL_RESULT_OK )
					err = expr->args[i]->SetData(ctx,expr->args[i]->cpuData);
			}
			else if(expr->args[i]->res)	// if array resides in the memory as a solid 2D piece
			{
				if( (err = arrs->AllocateSplittedMatrix(expr->args[i],numParts,0)) == CAL_RESULT_OK )
				{
					if( (err = SplitMatrix(expr->args[i],numParts,expr->args[i]->parts)) == CAL_RESULT_OK )
					{
						calResFree(expr->args[i]->res);
						expr->args[i]->res = 0;
					}
					else	// do cleanup
					{
						for(j = 0; j < numParts; j++)
							delete expr->args[i]->parts[j];
						
						expr->args[i]->parts = NULL;
						expr->args[i]->numParts = 0;
					}	
				}
			}
		}
	}

	if(err != CAL_RESULT_OK)
		return err;
	
	if(!result->res)		
		err = arrs->AllocateArray(result,0);	

	if(expr->args[0]->physSize[0] > 1)
	{	
		if(!expr->args[0]->parts)
			size = max(expr->args[0]->physSize[0],expr->args[0]->physSize[1]);
		else
			size = max(expr->args[0]->parts[0]->physSize[0],expr->args[0]->parts[0]->physSize[1]);		
		
		resultTemp = arrs->NewArray(-1,result->dType,1,&size,NULL,1);
		if( (err = arrs->AllocateArray(resultTemp,0)) != CAL_RESULT_OK )
		{
			delete resultTemp;
			resultTemp = NULL;
		}
	}	
	
	return err;
}

// perform a dot ptoduct operation
CALresult Context::DoDotProd(void)
{
	CALresult err;
	Module* module;
	CALdomain domain;	
	Array** inputs;
	float constData[4];
	long i, n;
	
	KernelCode iKernel, iKernel1;
	
	err = CAL_RESULT_OK;	

	switch(expr->dType)
	{
		case TREAL:
		{
			if(expr->args[0]->physSize[0] > 1)
				iKernel = KernSum1CompRow_PS;			
			else
				iKernel = KernDotProd1DR_PS;

		}break;		
		
		default:			
			return CAL_RESULT_INVALID_PARAMETER;
	}	
	
	// get suited module
	if(!modules[iKernel])
	{
		modules[iKernel] = new Module(hDev,ctx,kernels[iKernel],&err);		
		if(err != CAL_RESULT_OK)
		{
			delete modules[iKernel];
			modules[iKernel] = NULL;
		}
	}	

	if(err != CAL_RESULT_OK)
		return err;
				
	if(expr->args[0]->physSize[0] > 1)	// contraction is required
	{					
		if(!expr->args[0]->parts)	// not splitted arrays
		{
			if(expr->args[0]->physSize[1] > expr->args[0]->physSize[0])	// which dimension to contract?
			{	
				// contract along Y dimension

				if(!expr->args[0]->isVirtualized)
				{
					switch(expr->dType)
					{
						case TREAL: iKernel1 = KernEwMulContractAlongY4R_PS; break;		
						default: return CAL_RESULT_INVALID_PARAMETER;
					}						
				}
				else
				{
					switch(expr->dType)
					{
						case TREAL: iKernel1 = KernEwMulContractAlongY1R_PS; break;		
						default: return CAL_RESULT_INVALID_PARAMETER;
					}						
				}
				constData[0] = (float)expr->args[0]->physSize[0];						
			}
			else
			{
				// contract along X dimension

				if(!expr->args[0]->isVirtualized)
				{
					switch(expr->dType)
					{
						case TREAL: iKernel1 = KernEwMulContractAlongX4R_PS; break;		
						default: return CAL_RESULT_INVALID_PARAMETER;
					}						
				}
				else	
				{
					switch(expr->dType)
					{
						case TREAL: iKernel1 = KernEwMulContractAlongX1R_PS; break;		
						default: return CAL_RESULT_INVALID_PARAMETER;
					}						
				}
				constData[0] = (float)expr->args[0]->physSize[1];
			}			
		}
		else	// case of splitted matrices
		{
			if(expr->args[0]->parts[0]->physSize[1] > expr->args[0]->parts[0]->physSize[0])
			{	
				switch(expr->dType)
				{
					case TREAL: 
						if(expr->args[0]->numParts == 8)
							iKernel1 = KernEwMulContract8PartsAlongY4R_PS; 
						else
							iKernel1 = KernEwMulContract4PartsAlongY4R_PS;
						break;		
					default: return CAL_RESULT_INVALID_PARAMETER;
				}												
				constData[0] = (float)expr->args[0]->parts[0]->physSize[0];						
			}
			else
			{	
				switch(expr->dType)
				{
					case TREAL: 
						if(expr->args[0]->numParts == 8)
							iKernel1 = KernEwMulContract8PartsAlongX4R_PS;
						else
							iKernel1 = KernEwMulContract4PartsAlongX4R_PS;
						break;		
					default: return CAL_RESULT_INVALID_PARAMETER;
				}									
				constData[0] = (float)expr->args[0]->parts[0]->physSize[1];
			}						
		}				

		// get suited module
		if(!modules[iKernel1])
		{
			modules[iKernel1] = new Module(hDev,ctx,kernels[iKernel1],&err);		
			if(err != CAL_RESULT_OK)
			{
				delete modules[iKernel1];
				modules[iKernel1] = NULL;
			}
		}

		if(err == CAL_RESULT_OK)
		{
			module = modules[iKernel1];					

			err = module->constants[0]->SetData(&constData);		
			if(err == CAL_RESULT_OK)
			{
				err = module->SetConstantsToContext();
				if(err == CAL_RESULT_OK)
				{	
					// set the domain of execution
					domain.x = 0;
					domain.y = 0;		
					domain.width = resultTemp->physSize[1];
					domain.height = 1;
					
					if(!expr->args[0]->numParts)											
						err = module->RunPixelShader(expr->args,&resultTemp,NULL,&domain);				
					else
					{	
						n = expr->args[0]->numParts;
						inputs = new Array*[n*2];						
						for(i = 0; i < n; i++)
						{
							inputs[i] = expr->args[0]->parts[i];
							inputs[i+n] = expr->args[1]->parts[i];
						}

						err = module->RunPixelShader(inputs,&resultTemp,NULL,&domain);
						delete inputs;
					}					

					module->ReleaseConstantsFromContext();
				}
			}
		}

		inputs = &resultTemp;
	}
	else
		inputs = expr->args;


	if(err == CAL_RESULT_OK)
	{
		module = modules[iKernel];	

		constData[0] = (float)inputs[0]->physSize[1];

		err = module->constants[0]->SetData(&constData);		
		if(err == CAL_RESULT_OK)
		{
			err = module->SetConstantsToContext();
			if(err == CAL_RESULT_OK)
			{	
				// set the domain of execution
				domain.x = 0;
				domain.y = 0;		
				domain.width = 1;
				domain.height = 1;

				err = module->RunPixelShader(inputs,&result,NULL,&domain);

				module->ReleaseConstantsFromContext();
			}
		}
	}		

	return err;
}

// Setup a convolve computation
CALresult Context::SetConvolve(ArrayExpression* expr, Array* result)
{
/*
	CALresult err;	
	BOOL isReservedForGet0;	
	Array* arr0;

	if(resultTemp)	
	{
		delete resultTemp;
		resultTemp = NULL;

		// avoid possible problems, when expression is set and uses resultTemp...
		if(expr)
			delete expr;
		expr = NULL;		
	}

	// increment use counters beforehand!	
	arr->useCounter++;
	result->useCounter++;
	isReservedForGet0 = result->isReservedForGet;
	result->isReservedForGet = TRUE;
	
	err = CAL_RESULT_OK;

	if(arr->hDev != hDev)
	{		
		arr0 = arr;

		// create array copy on the local device
		arr = arrs->NewArray(arr0->arrID,arr0->dType,arr0->nDims,arr0->size,arr0->cpuData);						

		if(!arr0->parts)			
			err = arrs->AllocateArray(arr,0);			
		else
			err = arrs->AllocateSplittedMatrix(arr,arr0->numParts,0);

		if(err == CAL_RESULT_OK)
		{
			if( (err = arr0->Copy(ctx,arr)) == CAL_RESULT_OK )
			{					
				arr0->useCounter--;					
				arr->useCounter++;				

				// add to the local pool as a copy
				arr->isCopy = TRUE;
				arrs->Add(arr);
			}
			else
				delete arr;
		}
		else
			delete arr;
	}	

	if(err == CAL_RESULT_OK) 
	{
		if(result->hDev != hDev) // if result array resides on another device
		{		
			arr = arrs->NewArray(result->arrID,result->dType,result->nDims,result->size,result->cpuData);

			((ArrayPool*)result->pool)->Remove(result);
			result = arr;
			result->useCounter++;
			result->isReservedForGet = TRUE;
			arrs->Add(result);			
		}
	}
	else // in case of an error set use counters to their previous values		
	{			
		arr->useCounter--;
		result->useCounter--;
		result->isReservedForGet = isReservedForGet0;

		return err;
	}		

	if(!arr->res && !arr->parts)
	{		
		if( (err = arrs->AllocateArray(arr,0)) == CAL_RESULT_OK )
			err = arr->SetData(ctx,arr->cpuData);
	}

	if(err != CAL_RESULT_OK)
		return err;

	if(result == arr)
	{
		// inplace -> create temporary result array
		resultTemp = arrs->NewArray(result->arrID,result->dType,result->nDims,result->size,result->cpuData);
		if(!arr->parts)
			err = arrs->AllocateArray(resultTemp,0);
		else
			err = arrs->AllocateSplittedMatrix(resultTemp,arr->numParts,0);

		if(err != CAL_RESULT_OK)
		{
			delete resultTemp;
			resultTemp = NULL;
		}
	}
	else if( (!result->res && !result->parts) || (arr->parts && !result->parts) || (!arr->parts && result->parts) )
	{
		result->Free();
		if(!arr->parts)
			err = arrs->AllocateArray(result,0);
		else
			err = arrs->AllocateSplittedMatrix(result,arr->numParts,0);
	}
	
	if(err != CAL_RESULT_OK)
		return err;	
	
	if(err == CAL_RESULT_OK) // in case of an error set use counters to their previous values		
	{
		convArr = arr;
		convKernel = kernel;
		convKernelLength = kernelLength;
		convHotSpot = hotSpot;
		this->result = result;
	}
	else
	{	
		convArr = NULL;
		arr->useCounter--;
		result->useCounter--;
		result->isReservedForGet = isReservedForGet0;
	}

	return err;
*/

	return CAL_RESULT_NOT_SUPPORTED;
}

// perform a convolve computation
CALresult Context::DoConvolveRows(void)
{
/*
	CALresult err;
	Module* module;
	Array* arr;
	CALdomain domain;
	KernelCode iKernel;	

	float* f;
	float constData0[8] = {0,0,0,0, 0,0,0,0};
	float constData1[8] = {0,0,0,0, 0,0,0,0};
	float constData2[8] = {0,0,0,0, 0,0,0,0};
	float constData3[8] = {0,0,0,0, 0,0,0,0};	

	if(convArr->isVirtualized)
		return CAL_RESULT_NOT_SUPPORTED;

	switch(convKernelLength)
	{
		case 2:
		{
			switch(convArr->dType)
			{
				case TREAL: iKernel = KernConvolveRows2R_PS;
				default: return CAL_RESULT_NOT_SUPPORTED;
			}

			f = (float*)convKernel;

			if(convHotSpot == 0)
			{
				constData0[0] = f[0]; constData0[1] = f[1];
				constData1[1] = f[0]; constData1[2] = f[1];
				constData2[2] = f[0]; constData2[3] = f[1];
				constData3[3] = f[0]; constData3[4] = f[1];
			}
			else
			{
				constData0[3] = f[0]; constData0[4] = f[1];
				constData1[4] = f[0]; constData1[5] = f[1];
				constData2[5] = f[0]; constData2[6] = f[1];
				constData3[6] = f[0]; constData3[7] = f[1];
			}
			
		}
		break;

		default:
			return CAL_RESULT_NOT_SUPPORTED;
	}

	
	// get suited module
	if(!modules[iKernel])
	{
		modules[iKernel] = new Module(hDev,ctx,kernels[iKernel],&err);		
		if(err != CAL_RESULT_OK)
		{
			delete modules[iKernel];
			modules[iKernel] = NULL;
		}
	}		

	if(err == CAL_RESULT_OK)
	{		
		module = modules[iKernel];		

		err = module->constants[0]->SetData(&constData0);
		if(err == CAL_RESULT_OK)
		{
			err = module->constants[1]->SetData(&constData1);
			if(err == CAL_RESULT_OK)
			{
				err = module->constants[2]->SetData(&constData2);
				if(err == CAL_RESULT_OK)
					err = module->constants[3]->SetData(&constData3);
			}
		}				

		if(err == CAL_RESULT_OK)
		{
			err = module->SetConstantsToContext();
			if(err == CAL_RESULT_OK)
			{
				if(!resultTemp)
					arr = result;
				else
					arr = resultTemp;

				// set the domain of execution
				domain.x = 0;
				domain.y = 0;		
				domain.width = arr->physSize[1];
				domain.height = arr->physSize[0];				
				
				err = module->RunPixelShader(&convArr,&arr,NULL,&domain);

				if( (err == CAL_RESULT_OK) && resultTemp )
				{												
					arrs->Set(arrs->Find(result->arrID),resultTemp);
					delete result;
					result = resultTemp;
					resultTemp = NULL;

					// do not forget about the flags!
					result->useCounter++;
					result->isReservedForGet = TRUE;					
				}
			}
		}
	}


	// decrement use counters	
	convArr->useCounter--;
	result->useCounter--;		

	return err;
*/

	return CAL_RESULT_NOT_SUPPORTED;
}

// setup a scale computation
CALresult Context::SetScale(ArrayExpression* expr, Array* result)
{
	CALresult err;

	err = CAL_RESULT_OK;

	if(!expr->args[0]->IsScalar())	
	{
		if( expr->args[1]->res && (err = expr->args[1]->GetData(ctx,expr->args[1]->cpuData)) != CAL_RESULT_OK )
			return err;

		if(!expr->args[0]->res && !expr->args[0]->parts)
		{
			// allocate array and set data
			if( (err = arrs->AllocateArray(expr->args[0],0)) == CAL_RESULT_OK )
				err = expr->args[0]->SetData(ctx,expr->args[0]->cpuData);
		}

		if(err != CAL_RESULT_OK)
			return err;

		if(!result->res || !result->parts || (result->res && !expr->args[0]->res) || (result->parts && !expr->args[0]->parts) )
		{
			result->Free();
			if(expr->args[0]->res)
				err = arrs->AllocateArray(result,0);
			else
				err = arrs->AllocateSplittedMatrix(result,expr->args[0]->numParts,0);
		}

	}
	else
	{
		if( expr->args[0]->res && (err = expr->args[0]->GetData(ctx,expr->args[0]->cpuData)) != CAL_RESULT_OK )
			return err;

		if(!expr->args[1]->res && !expr->args[1]->parts)
		{		
			// allocate array and set data
			if( (err = arrs->AllocateArray(expr->args[1],0)) == CAL_RESULT_OK )
				err = expr->args[1]->SetData(ctx,expr->args[1]->cpuData);						
		}

		if(err != CAL_RESULT_OK)
			return err;	

		if(!result->res && !result->parts || (result->res && !expr->args[1]->res) || (result->parts && !expr->args[1]->parts) )
		{
			result->Free();
			if(expr->args[1]->res)
				err = arrs->AllocateArray(result,0);
			else
				err = arrs->AllocateSplittedMatrix(result,expr->args[1]->numParts,0);
		}
	}

	return err;
}

// perform a scale computation
CALresult Context::DoScale(void)
{
	CALresult err;
	Module* module;
	CALdomain domain;	
	float constDataF[4];
	double constDataD[2];
	void* constData;
	Array* input;	

	long i;
	KernelCode iKernel;
	
	err = CAL_RESULT_OK;

	switch(expr->dType)
	{
		case TREAL: iKernel = KernMulBySR_PS; break;
		case TLONGREAL: iKernel = KernMulBySLR_PS; break;		
		
		default:
			return CAL_RESULT_INVALID_PARAMETER;
	}	
	
	// get suited module
	if(!modules[iKernel])
	{
		modules[iKernel] = new Module(hDev,ctx,kernels[iKernel],&err);		
		if(err != CAL_RESULT_OK)
		{
			delete modules[iKernel];
			modules[iKernel] = NULL;
		}
	}
	
	if(err == CAL_RESULT_OK)
	{				
		module = modules[iKernel];

		if(!expr->args[0]->IsScalar())
		{
			input = expr->args[0];

			switch(expr->dType)
			{
				case TREAL:
					constDataF[0] = ((float*)(expr->args[1]->cpuData))[0];
					constDataF[1] = constDataF[0];
					constDataF[2] = constDataF[0];
					constDataF[3] = constDataF[0];
					constData = constDataF;
					break;

				case TLONGREAL:
					constDataD[0] = ((double*)(expr->args[1]->cpuData))[0];
					constDataD[1] = constDataD[0];					
					constData = constDataD;
					break;
			}
		}
		else
		{
			input = expr->args[1];

			switch(expr->dType)
			{
				case TREAL:
					constDataF[0] = ((float*)(expr->args[0]->cpuData))[0];
					constDataF[1] = constDataF[0];
					constDataF[2] = constDataF[0];
					constDataF[3] = constDataF[0];
					constData = constDataF;
					break;

				case TLONGREAL:
					constDataD[0] = ((double*)(expr->args[0]->cpuData))[0];
					constDataD[1] = constDataD[0];					
					constData = constDataD;
					break;
			}
		}

		err = module->constants[0]->SetData(constData);		
		if(err == CAL_RESULT_OK)
		{
			err = module->SetConstantsToContext();
			if(err == CAL_RESULT_OK)
			{
				// set the domain of execution
				domain.x = 0;
				domain.y = 0;		

				if(!result->parts)
				{
					domain.width = result->physSize[1];
					domain.height = result->physSize[0];

					// run the program			
					err = module->RunPixelShader(&input,&result,NULL,&domain);		
				}
				else
				{
					domain.width = result->parts[0]->physSize[1];
					domain.height = result->parts[0]->physSize[0];			

					// run the program for each part separately
					for(i = 0; i < result->numParts; i++)							
						err = module->RunPixelShader(&(input->parts[i]),&result->parts[i],NULL,&domain);			
				}
			}
		}		
	}	
	
	return err;
}
