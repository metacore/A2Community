#pragma once
#include "ObjectPool.h"
#include "Exclude.h"

// array description
struct ArrayDesc
{
	long id;	// array ID
	long dType;	// array data type code
	long nDims;	// number of dimensions	
	long* size;	// array size
	void* data;	// array data address
};

// array expression description
struct ArrayExpressionDesc
{
	long op;		// operation code
	long dType;		// data type code
	long nDims;		// number of dimensions of expression result
	long* size;		// size of expression result
	long* transpDims;	// transposed dimensions in case of transposition operation
	ArrayDesc* arg1;	// first argument desription
	ArrayDesc* arg2;	// second argument desription
	ArrayDesc* arg3;	// second argument desription	
};

class Array
{
public:
	Array(CALdevice hDev, CALdeviceinfo* devInfo, CALdeviceattribs* devAttribs, long arrID, long dType, long nDims, long* size);
	~Array(void);
	
	CALresult AllocateLocal(CALuint flags);	// allocate local memory
	CALresult AllocateRemote(CALuint flags);	// allocate remote memory
	void FreeLocal(void);	// free local memory
	void FreeRemote(void);	// free remote memory
	CALresult CopyRemoteToLocal(CALcontext ctx);	// copy from remote memory to local
	CALresult CopyLocalToRemote(CALcontext ctx);	// copy from local memory to remote	
	CALresult FreeLocalKeepInRemote(CALcontext ctx);	// if possible store data in remote memory and free local memory
	CALresult SetDataToRemote(CALcontext ctx, void* cpuData);	// sets data to remote GPU memory
	CALresult GetDataFromRemote(CALcontext ctx, void* cpuData);	// get data from remote GPU memory to the CPU memory
	CALresult SetDataToLocal(CALcontext ctx, void* cpuData);	// sets data to local GPU memory
	CALresult GetDataFromLocal(CALcontext ctx, void* cpuData);	// gets data from local GPU memory to the CPU memory
	CALresult err;	// error code for last operation
	
	CALdevice hDev;			// handle of device on which the array exists	

	long arrID;				// array ID		
	long dType;				// data type code	
	void* cpuData;			// CPU data pointer
	long nDims;				// number of dimensions (logical)
	long* size;				// array size
	long elemSize;			// element size in bytes	
	long dataSize;			// total data size in bytes

	long physNumComponents;	// number of components in each element on the GPU
	long physElemSize;		// physical element size
	CALformat dFormat;		// data format on the GPU	
	long logicDataSize;		// logical data size in bytes
	long physDataSize;		// physical data size in bytes

	long nLogicDims;		// number of logical dimensions on the GPU
	long* logicSize;		// logical size on the GPU
	long* physSize;			// physical size on the GPU with account of padding to multiple of physNumComponents

	CALresource remoteRes;	// remote GPU resource
	CALresource localRes;	// local GPU resource			
	
	BOOL localIsGlobalBuf;	// TRUE when local resource is a global buffer
	BOOL remoteIsGlobalBuf;	// TRUE when remote resource is a global buffer
	BOOL isVirtualized;		// memory virtualization is used to fit to the hardware requirements
	long useCounter;		// counter for storing number of contextes which use the array
	BOOL isReservedForGet;	// the object is reserved for further getting (for example a return argument)
	// copy data from one resource to another
	CALresult Copy(CALcontext ctx, CALresource dstRes, CALresource srcRes);
};

// array expression for internal use
class ArrayExpression
{
public:
	ArrayExpression(long op, long dType, long nDims, long* size, long* transpDims);
	~ArrayExpression(void);

	long op;		// operation code
	long dType;		// data type code
	long nDims;		// number of dimensions of expression result
	long* size;		// size of expression result
	long* transpDims;	// transposed dimensions in case of transposition operation
	Array** args;	// expression arguments
};

class ArrayPool :
	public ObjectPool
{
public:
	ArrayPool(void);
	~ArrayPool(void);
	
	Array* Get(long ind);
	long Find(long arrID);	// find an array by given ID
	void Remove(long ind);	// remove an entry

	// find currently unused array with maximum (from all arrays in the pool) allocated local memory
	Array* FindMaxLocalNotInUse(Exclude* excl);
	long FindMaxLocalNotInUse1(Exclude* excl);
	// find currently unused array with minimum (from all arrays in the pool) allocated local memory
	Array* FindMinLocalNotInUse(Exclude* excl);
	long FindMinLocalNotInUse1(Exclude* excl);

	CALresult err;	// error code for last operation
};
