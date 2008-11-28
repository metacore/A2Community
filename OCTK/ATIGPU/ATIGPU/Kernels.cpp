#include "StdAfx.h"
#include "Kernels.h"

Kernel::Kernel(long iKernel, CALtarget target)
{
	img = 0;
	obj = 0;
		
	err = CAL_RESULT_INVALID_PARAMETER;

	const char* kernelStr = NULL;

	nInputs = 0;
	nOutputs = 0;
	nConstants = 0;
	usesGlobalBuffer = FALSE;

	switch(iKernel)
	{
		case KernAddR: 
			kernelStr = kernelAddR; nInputs = 2; nOutputs = 1;
			break;		
		case KernAddLR: 
			kernelStr = kernelAddLR; nInputs = 2; nOutputs = 1;
			break;
		case KernSubR: 
			kernelStr = kernelSubR; nInputs = 2; nOutputs = 1;					
			break;
		case KernSubLR: 
			kernelStr = kernelSubLR; nInputs = 2; nOutputs = 1;					
			break;
		case KernEwMulR: 
			kernelStr = kernelEwMulR; nInputs = 2; nOutputs = 1;
			break;		
		case KernEwMulLR: 
			kernelStr = kernelEwMulLR; nInputs = 2; nOutputs = 1;
			break;
		case KernEwDivR: 
			kernelStr = kernelEwDivR; nInputs = 2; nOutputs = 1;
			break;		
		case KernEwDivLR: 
			kernelStr = kernelEwDivLR; nInputs = 2; nOutputs = 1;
			break;
		case KernDotProdR: 
			kernelStr = kernelDotProdR; nInputs = 2; nOutputs = 1;
			break;
		case KernDotProdLR: 
			kernelStr = kernelDotProdLR; nInputs = 2; nOutputs = 1;
			break;
		case KernAssign:
			kernelStr = kernelAssign; nOutputs = 1; nConstants = 1;
			break;
		case KernMatVecR: 
			kernelStr = kernelMatVecR; nInputs = 2; nOutputs = 1; nConstants = 1;
			break;


		default:
			return;
	}

	err = calclCompile(&obj,CAL_LANGUAGE_IL,kernelStr,target);
	if(err == CAL_RESULT_OK) 							
		err = calclLink(&img,&obj,1);
	
	if(err != CAL_RESULT_OK)
	{
		if(obj)
			calclFreeObject(obj);
		obj = NULL;
		img = NULL;
		return;
	}

	this->iKernel = iKernel;
}

Kernel::~Kernel(void)
{
	if(img)
		calclFreeImage(img);
	if(obj)
		calclFreeObject(obj);
}

KernelPool::KernelPool(void)
{
	err = CAL_RESULT_OK;
}


KernelPool::~KernelPool(void)
{
	RemoveAll();
}


void KernelPool::Remove(long ind)
{
	Kernel* kern = (Kernel*)ObjectPool::Get(ind);
	if(kern)
		delete kern;
	
	ObjectPool::Remove(ind);
}
