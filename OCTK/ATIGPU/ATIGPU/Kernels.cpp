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

	constFormats = NULL;
	constSizes = NULL;

	switch(iKernel)
	{
		case KernFillByNComp_PS:
			kernelStr = kernelFillByNComp_PS; nOutputs = 1; 
			nConstants = 1;
			constSizes = new long[1]; constSizes[0] = 0;
			constFormats = new CALformat[1]; constFormats[0] = CALformat(0);
			break;

		case KernFillBy2xNComp_CS:
			kernelStr = kernelFillBy2xNComp_CS; nConstants = 1; usesGlobalBuffer = TRUE;
			constSizes = new long[1]; constSizes[0] = 0;
			constFormats = new CALformat[1]; constFormats[0] = CALformat(0);
			break;

		case KernFillBy4xNComp_CS:
			kernelStr = kernelFillBy4xNComp_CS; nConstants = 1; usesGlobalBuffer = TRUE;
			constSizes = new long[1]; constSizes[0] = 0;
			constFormats = new CALformat[1]; constFormats[0] = CALformat(0);
			break;

		case KernFillBy8xNComp_CS:
			kernelStr = kernelFillBy8xNComp_CS; nConstants = 1; usesGlobalBuffer = TRUE;
			break;

		case KernFillBy16xNComp_CS:
			kernelStr = kernelFillBy16xNComp_CS; nConstants = 1; usesGlobalBuffer = TRUE;
			constSizes = new long[1]; constSizes[0] = 0;
			constFormats = new CALformat[1]; constFormats[0] = CALformat(0);
			break;

		case KernAddR_PS: 
			kernelStr = kernelAddR_PS; nInputs = 2; nOutputs = 1;
			break;	

		case KernAddLR_PS: 
			kernelStr = kernelAddLR_PS; nInputs = 2; nOutputs = 1;
			break;

		case KernAddR_CS:
			kernelStr = kernelAddR_CS; nInputs = 2; usesGlobalBuffer = TRUE; nOutputs = 0; 
			nConstants = 1;
			constSizes = new long[1]; constSizes[0] = 1;
			constFormats = new CALformat[1]; constFormats[0] = CAL_FORMAT_FLOAT_4;
			break;

		case KernSubR_PS: 
			kernelStr = kernelSubR_PS; nInputs = 2; nOutputs = 1;					
			break;

		case KernSubR_CS:
			kernelStr = kernelSubR_CS; nInputs = 2; usesGlobalBuffer = TRUE; nOutputs = 0; 
			nConstants = 1;
			constSizes = new long[1]; constSizes[0] = 1;
			constFormats = new CALformat[1]; constFormats[0] = CAL_FORMAT_FLOAT_4;
			break;

		case KernSubLR_PS: 
			kernelStr = kernelSubLR_PS; nInputs = 2; nOutputs = 1;					
			break;

		case KernEwMulR_PS: 
			kernelStr = kernelEwMulR_PS; nInputs = 2; nOutputs = 1;
			break;	

		case KernEwMulR_CS:
			kernelStr = kernelEwMulR_CS; nInputs = 2; usesGlobalBuffer = TRUE; nOutputs = 0; 
			nConstants = 1;
			constSizes = new long[1]; constSizes[0] = 1;
			constFormats = new CALformat[1]; constFormats[0] = CAL_FORMAT_FLOAT_4;
			break;

		case KernEwDivR_CS:
			kernelStr = kernelEwDivR_CS; nInputs = 2; usesGlobalBuffer = TRUE; nOutputs = 0; 
			nConstants = 1;
			constSizes = new long[1]; constSizes[0] = 1;
			constFormats = new CALformat[1]; constFormats[0] = CAL_FORMAT_FLOAT_4;
			break;

		case KernEwMulLR_PS: 
			kernelStr = kernelEwMulLR_PS; nInputs = 2; nOutputs = 1;
			break;

		case KernEwDivR_PS: 
			kernelStr = kernelEwDivR_PS; nInputs = 2; nOutputs = 1;
			break;		

		case KernEwDivLR_PS: 
			kernelStr = kernelEwDivLR_PS; nInputs = 2; nOutputs = 1;
			break;				

		case KernMatVecR_PS: 
			kernelStr = kernelMatVecR_PS; nInputs = 2; nOutputs = 1; nConstants = 1;
			constSizes = new long[1]; constSizes[0] = 1;
			constFormats = new CALformat[1]; constFormats[0] = CAL_FORMAT_FLOAT_2;
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
	if(constFormats)
		delete constFormats;
	if(constSizes)
		delete constSizes;
	if(img)
		calclFreeImage(img);
	if(obj)
		calclFreeObject(obj);
}