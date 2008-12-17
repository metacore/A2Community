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
		case KernFill_PS:
			kernelStr = kernelFill_PS; nOutputs = 1; 
			nConstants = 1;
			constSizes = new long[1]; constSizes[0] = 0;
			constFormats = new CALformat[1]; constFormats[0] = CALformat(0);
			break;	

		case KernFill1_PS:
			kernelStr = kernelFill1_PS; nOutputs = 1; 
			nConstants = 2;
			constSizes = new long[2]; constSizes[0] = 0; constSizes[1] = 1;
			constFormats = new CALformat[2]; constFormats[0] = CALformat(0); constFormats[1] = CAL_FORMAT_FLOAT_4;
			break;	

		case KernAddR_PS: 
			kernelStr = kernelAddR_PS; nInputs = 2; nOutputs = 1;
			break;	

		case KernAddByPartsR_PS:
			kernelStr = kernelAddByPartsR_PS; nInputs = 16; nOutputs = 8;
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

		case KernMatVecByPartsR_PS:
			kernelStr = kernelMatVecByPartsR_PS; nInputs = 9; nOutputs = 1; nConstants = 1;
			constSizes = new long[1]; constSizes[0] = 1;
			constFormats = new CALformat[1]; constFormats[0] = CAL_FORMAT_FLOAT_4;
			break;	
		
		case KernDivideMatrixTo4Parts_PS:				
			kernelStr = kernelDivideMatrixTo4Parts_PS; nInputs = 1; nOutputs = 4;
			break;		

		case KernDivideMatrixTo8Parts_PS:				
			kernelStr = kernelDivideMatrixTo8Parts_PS; nInputs = 1; nOutputs = 8;
			break;		

		case KernMatMul4x8x4by4x4x4R_PS: 
			kernelStr = kernelMatMul4x8x4by4x4x4R_PS; nInputs = 2; nOutputs = 0; nConstants = 1; usesGlobalBuffer = TRUE;
			constSizes = new long[1]; constSizes[0] = 1;
			constFormats = new CALformat[1]; constFormats[0] = CAL_FORMAT_FLOAT_4;
			break;
		
		case KernMatMul8x4by4x4R_PS: 
			kernelStr = kernelMatMul8x4by4x4R_PS; nInputs = 2; nOutputs = 0; nConstants = 1; usesGlobalBuffer = TRUE;
			constSizes = new long[1]; constSizes[0] = 1;
			constFormats = new CALformat[1]; constFormats[0] = CAL_FORMAT_FLOAT_4;
			break;

		case KernMatMul4x4by4x4R_PS: 
			kernelStr = kernelMatMul4x4by4x4R_PS; nInputs = 2; nOutputs = 0; nConstants = 1; usesGlobalBuffer = TRUE;
			constSizes = new long[1]; constSizes[0] = 1;
			constFormats = new CALformat[1]; constFormats[0] = CAL_FORMAT_FLOAT_4;
			break;

		case KernMatMul4x8x4by4x4x4R_CS: 
			kernelStr = kernelMatMul4x8x4by4x4x4R_CS; nInputs = 2; nOutputs = 0; nConstants = 1; usesGlobalBuffer = TRUE;
			constSizes = new long[1]; constSizes[0] = 2;
			constFormats = new CALformat[1]; constFormats[0] = CAL_FORMAT_FLOAT_4;
			break;		

		case KernMatMul8x4by4x4R_CS: 
			kernelStr = kernelMatMul8x4by4x4R_CS; nInputs = 2; nOutputs = 0; nConstants = 1; usesGlobalBuffer = TRUE;
			constSizes = new long[1]; constSizes[0] = 2;
			constFormats = new CALformat[1]; constFormats[0] = CAL_FORMAT_FLOAT_4;
			break;

		case KernMatMul4x4by4x4R_CS: 
			kernelStr = kernelMatMul4x4by4x4R_CS; nInputs = 2; nOutputs = 0; nConstants = 1; usesGlobalBuffer = TRUE;
			constSizes = new long[1]; constSizes[0] = 2;
			constFormats = new CALformat[1]; constFormats[0] = CAL_FORMAT_FLOAT_4;
			break;
		
		case KernMatMulByParts4x4x4by4x4x4R_PS: 
			kernelStr = kernelMatMulByParts4x4x4by4x4x4R_PS; nInputs = 8; nOutputs = 4; nConstants = 1;
			constSizes = new long[1]; constSizes[0] = 1;
			constFormats = new CALformat[1]; constFormats[0] = CAL_FORMAT_FLOAT_4;
			break;

		case KernMatMulByParts4x8x4by4x4x4R_PS: 
			kernelStr = kernelMatMulByParts4x8x4by4x4x4R1_PS; nInputs = 16; nOutputs = 8; nConstants = 1;
			constSizes = new long[1]; constSizes[0] = 1;
			constFormats = new CALformat[1]; constFormats[0] = CAL_FORMAT_FLOAT_4;
			break;

		case KernMatMulByParts2x8x4by2x4x4R_PS: 
			kernelStr = kernelMatMulByParts2x8x4by2x4x4R_PS; nInputs = 16; nOutputs = 8; nConstants = 1;
			constSizes = new long[1]; constSizes[0] = 1;
			constFormats = new CALformat[1]; constFormats[0] = CAL_FORMAT_FLOAT_4;
			break;

		case KernGatherMatrixFrom8Parts_PS:
			kernelStr = kernelGatherMatrixFrom8Parts_PS; nInputs = 8; nOutputs = 0;  nConstants = 1; usesGlobalBuffer = TRUE; 
			constSizes = new long[1]; constSizes[0] = 1;
			constFormats = new CALformat[1]; constFormats[0] = CAL_FORMAT_FLOAT_4;
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