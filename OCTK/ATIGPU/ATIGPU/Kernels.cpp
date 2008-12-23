#include "StdAfx.h"
#include "Kernels.h"

Kernel::Kernel(KernelCode iKernel, CALtarget target, CALresult* err)
{	
	img = 0;
	obj = 0;			

	const char* kernelStr = NULL;

	nInputs = 0;
	nOutputs = 0;
	nConstants = 0;
	usesGlobalBuffer = FALSE;

	constSizes = NULL;
	constFormats = NULL;	

	switch(iKernel)
	{		
		case KernAddR_PS: 
			kernelStr = kernelAddR_PS; nInputs = 2; nOutputs = 1;
			break;		

		case KernAddLR_PS: 
			kernelStr = kernelAddLR_PS; nInputs = 2; nOutputs = 1;
			break;		

		case KernSubR_PS: 
			kernelStr = kernelSubR_PS; nInputs = 2; nOutputs = 1;					
			break;		

		case KernSubLR_PS: 
			kernelStr = kernelSubLR_PS; nInputs = 2; nOutputs = 1;					
			break;

		case KernEwMulR_PS: 
			kernelStr = kernelEwMulR_PS; nInputs = 2; nOutputs = 1;
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
			constFormats = new CALformat[1]; constFormats[0] = CAL_FORMAT_FLOAT_4;
			break;

		case KernMatVec4PartsR_PS:
			kernelStr = kernelMatVec4PartsR_PS; nInputs = 5; nOutputs = 1; nConstants = 1;
			constSizes = new long[1]; constSizes[0] = 1;
			constFormats = new CALformat[1]; constFormats[0] = CAL_FORMAT_FLOAT_4;
			break;

		case KernMatVec8PartsR_PS:
			kernelStr = kernelMatVec8PartsR_PS; nInputs = 9; nOutputs = 1; nConstants = 1;
			constSizes = new long[1]; constSizes[0] = 1;
			constFormats = new CALformat[1]; constFormats[0] = CAL_FORMAT_FLOAT_4;
			break;

		case KernMatMul88Parts8x4by4x4R_PS: 
			kernelStr = kernelMatMul88Parts8x4by4x4R_PS; nInputs = 16; nOutputs = 8; nConstants = 1;
			constSizes = new long[1]; constSizes[0] = 1;
			constFormats = new CALformat[1]; constFormats[0] = CAL_FORMAT_FLOAT_4;
			break;

		case KernReshapeMatToMatNoBounds_PS:
			kernelStr = kernelReshapeMatToMatNoBounds_PS; nInputs = 1; nOutputs = 1; nConstants = 1;
			constSizes = new long[1]; constSizes[0] = 1;
			constFormats = new CALformat[1]; constFormats[0] = CAL_FORMAT_INT_4;
			break;

		case KernReshapeArr1DWToMat4DW_PS:
			kernelStr = kernelReshapeArr1DWToMat4DW_PS; nInputs = 1; nOutputs = 1; nConstants = 1;
			constSizes = new long[1]; constSizes[0] = 1;
			constFormats = new CALformat[1]; constFormats[0] = CAL_FORMAT_INT_4;
			break;

		case KernReshapeMat4DWToArr1DW_PS:
			kernelStr = kernelReshapeMat4DWToArr1DW_PS; nInputs = 1; nOutputs = 1; nConstants = 1;
			constSizes = new long[1]; constSizes[0] = 1;
			constFormats = new CALformat[1]; constFormats[0] = CAL_FORMAT_INT_4;
			break;

		case KernTranspose3D_PS:
			kernelStr = kernelTranspose3D_PS; nInputs = 1; nOutputs = 1; nConstants = 1;
			constSizes = new long[1]; constSizes[0] = 3;
			constFormats = new CALformat[1]; constFormats[0] = CAL_FORMAT_INT_4;
			break;

		case KernTranspose4D_PS:
			kernelStr = kernelTranspose4D_PS; nInputs = 1; nOutputs = 1; nConstants = 1;
			constSizes = new long[1]; constSizes[0] = 3;
			constFormats = new CALformat[1]; constFormats[0] = CAL_FORMAT_INT_4;
			break;

		case KernSplitMatrixTo4Parts_PS:
			kernelStr = kernelSplitMatrixTo4Parts_PS; nInputs = 1; nOutputs = 4;
			break;

		case KernSplitMatrixTo8Parts_PS:
			kernelStr = kernelSplitMatrixTo8Parts_PS; nInputs = 1; nOutputs = 8;
			break;

		case KernZeroMemory_PS:
			kernelStr = kernelZeroMemory_PS; nOutputs = 1;
			break;

		default:
			*err = CAL_RESULT_INVALID_PARAMETER;
			return;
	}

	*err = calclCompile(&obj,CAL_LANGUAGE_IL,kernelStr,target);
	if(*err == CAL_RESULT_OK) 							
		*err = calclLink(&img,&obj,1);
	
	if(*err != CAL_RESULT_OK)
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
	if(constSizes)
		delete constSizes;
	if(constFormats)
		delete constFormats;	
	if(img)
		calclFreeImage(img);
	if(obj)
		calclFreeObject(obj);
}
