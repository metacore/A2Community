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

	return CAL_FORMAT_FLOAT_4;
}

// Get element size for a given data format
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

// returns number of elements fitting to the size padded to the multiple of "numComponents"
long GetPaddedNumElements(long size, long numComponents)
{
	long k = size/numComponents;
	
	if(k*numComponents >= size)
		return k;
	else
		return k+1;
}