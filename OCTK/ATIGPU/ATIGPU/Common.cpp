#include "StdAfx.h"
#include "Common.h"

// Conversion from ArrayObjects data type to GPU data format
CALformat GetFormat(long dType, long numComponents)
{
	switch(dType)
	{
		case TSHORTINT: 
			switch(numComponents)
			{
				case 1:
					return CAL_FORMAT_BYTE_1;
				case 2:
					return CAL_FORMAT_BYTE_2;				
				case 4:	
					return CAL_FORMAT_BYTE_4;
			}

		case TINTEGER: 
			switch(numComponents)
			{
				case 1:
					return CAL_FORMAT_SHORT_1;
				case 2:
					return CAL_FORMAT_SHORT_2;				
				case 4:	
					return CAL_FORMAT_SHORT_4;
			}		

		case TLONGINT: 
			switch(numComponents)
			{
				case 1:
					return CAL_FORMAT_INT_1;
				case 2:
					return CAL_FORMAT_INT_2;				
				case 4:	
					return CAL_FORMAT_INT_4;
			}

		case TREAL: 
			switch(numComponents)
			{
				case 1:
					return CAL_FORMAT_FLOAT_1;
				case 2:
					return CAL_FORMAT_FLOAT_2;				
				case 4:	
					return CAL_FORMAT_FLOAT_4;
			}

		case TLONGREAL: 
			switch(numComponents)
			{
				case 1:
					return CAL_FORMAT_DOUBLE_1;
				case 2:
					return CAL_FORMAT_DOUBLE_2;				
			}
			
	}

	return CALformat(0);
}

// Get element size for a given data type
long GetElementSize(long dType)
{
	switch(dType)
	{
		case TSHORTINT: 
			return 1;
		case TINTEGER: 
			return 2;
		case TLONGINT: 
			return 4;		
		case TREAL: 
			return 4;
		case TLONGREAL: 
			return 8;		
		default: 
			return 0;
	}	
}

// Get element size for a given data format
long GetElementSize1(CALformat dFormat)
{
	switch(dFormat)
	{
		case CAL_FORMAT_BYTE_1: return 1;
		case CAL_FORMAT_BYTE_2: return 2;
		case CAL_FORMAT_BYTE_4: return 4;
		case CAL_FORMAT_SHORT_1: return 2;
		case CAL_FORMAT_SHORT_2: return 4;
		case CAL_FORMAT_SHORT_4: return 8;
		case CAL_FORMAT_INT_1: return 4;
		case CAL_FORMAT_INT_2: return 8;
		case CAL_FORMAT_INT_4: return 16;
		case CAL_FORMAT_FLOAT_1: return 4;
		case CAL_FORMAT_FLOAT_2: return 8;
		case CAL_FORMAT_FLOAT_4: return 16;
		case CAL_FORMAT_DOUBLE_1: return 8;
		case CAL_FORMAT_DOUBLE_2: return 16;
		default: 
			return 0;
	}	
}

// returns number of elements fitting to the size padded to the multiple of "numComponents"
long GetPaddedNumElements(long size, long numComponents)
{
	return (size+numComponents-1)/numComponents;
}

// returns TRUE if to array sizes are equal
BOOL EqualSizes(long nDims1, long* size1, long nDims2, long* size2)
{	
	if(nDims1 == nDims2)
	{
		nDims1--;
		for(; (nDims1 >= 0) && (size1[nDims1] == size2[nDims1]); nDims1--);

		return nDims1 == -1;
	}
	else
		return FALSE;
}

// copy data from one resource to another
CALresult ResCopy(CALcontext ctx, CALresource dstRes, CALresource srcRes)
{
	CALresult err;
	CALmem srcMem, dstMem;
	CALevent ev;	

	err = calCtxGetMem(&dstMem,ctx,dstRes);
	if(err != CAL_RESULT_OK) 
		return err;

	err = calCtxGetMem(&srcMem,ctx,srcRes);
	if(err != CAL_RESULT_OK)
	{
		calCtxReleaseMem(ctx,dstMem);
		return err;
	}	

	err = calMemCopy(&ev,ctx,srcMem,dstMem,0);
	if(err != CAL_RESULT_OK) 
	{
		calCtxReleaseMem(ctx,srcMem);
		calCtxReleaseMem(ctx,dstMem);	
		return err;
	}

	while(calCtxIsEventDone(ctx,ev) == CAL_RESULT_PENDING);	

	calCtxReleaseMem(ctx,srcMem);
	calCtxReleaseMem(ctx,dstMem);	

	return err;
}
