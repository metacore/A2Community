#include "StdAfx.h"
#include "Contexts.h"
#include "Kernels.h"

Context::Context(CALdevice hDev, KernelPool* kernels)
{
	Module* module;
	long i;	

	expr = NULL;
	result = NULL;

	err = calCtxCreate(&ctx,hDev);
	if(err != CAL_RESULT_OK)
	{
		ctx = 0; return;
	}

	modules = new ModulePool;

	for(i = 0; i < kernels->Length(); i++)
	{
		module = new Module(ctx,(Kernel*)kernels->Get(i));
		if(module->err == CAL_RESULT_OK)
			modules->Add(module);
		else
		{
			delete module; module = NULL;
			delete modules; modules = NULL;
			calCtxDestroy(ctx);
			ctx = 0;
			return;
		}
	}

	this->hDev = hDev;
}

Context::~Context(void)
{
	if(modules)
		delete modules;

	if(expr)
		delete expr;

	calCtxDestroy(ctx);
}


CALresult Context::SetComputation(ArrayExpression* expr, Array* result, long priority, long flags, ArrayPool* arrs)
{
	long i, ind;
	long op = expr->op;	
	Array* arr;	
	Exclude excl;
	
	err = CAL_RESULT_OK;	
	
	// increment counters beforehand!
	i = 0;
	while(expr->args[i]){expr->args[i]->useCounter++; i++;}	
	result->useCounter++;
	result->isReservedForGet = TRUE;
			
	if( (op == OpIdent) || (op == OpAdd) || (op == OpSub) || (op == OpDotProd) || (op == OpEwMul) || (op == OpEwDiv) )
	{							
		i = 0;
		while( expr->args[i] && (err == CAL_RESULT_OK) )
		{	
			if(!expr->args[i]->localRes)
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
				
				if(err == CAL_RESULT_OK)
				{
					if(expr->args[i]->remoteRes)	// array data is in the remote memory
					{
						err = expr->args[i]->CopyRemoteToLocal(ctx);
						expr->args[i]->FreeRemote();
					}
					else
						err = expr->args[i]->SetDataToLocal(ctx,expr->args[i]->cpuData);					
				}
			}

			i++;
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
	CALresult err;

	if(!expr)	
		return CAL_RESULT_INVALID_PARAMETER;

	if(expr->op == OpIdent)	// just copy the data
	{		
		if(result->nDims == expr->args[0]->nDims)	// just copy data from one to another
		{
			if(result->remoteRes)
			{
				if(expr->args[0]->remoteRes)
					err = result->Copy(ctx,result->remoteRes,expr->args[0]->remoteRes);
				else
					err = result->Copy(ctx,result->remoteRes,expr->args[0]->localRes);
			}
			else
			{
				if(expr->args[0]->localRes)
					err = result->Copy(ctx,result->localRes,expr->args[0]->localRes);
				else
					err = result->Copy(ctx,result->localRes,expr->args[0]->remoteRes);					
			}
		}
		else
			return CAL_RESULT_NOT_SUPPORTED;
	}
}
