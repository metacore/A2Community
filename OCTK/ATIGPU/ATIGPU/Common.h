#pragma once
#include "cal_ext.h"
#include "cal_ext_counter.h"

#define TSHORTINT	1
#define TINTEGER	2
#define TLONGINT	3
#define THUGEINT	4 
#define TREAL		5
#define TLONGREAL	6

// Conversion from ArrayObjects data type to GPU data format
CALformat GetFormat(long dType, long numComponents);

// Get element size for a given data type
long GetElementSize(long dType);

// Get element size for a given data format
long GetElementSize(CALformat dFormat);

// returns number of elements fitting to the size padded to the multiple of "numComponents"
long GetPaddedNumElements(long size, long numComponents);

