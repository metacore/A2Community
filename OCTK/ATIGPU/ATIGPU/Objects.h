#include <crtdbg.h>

#define TSHORTINT	1
#define TINTEGER	2
#define TLONGINT	3
#define THUGEINT	4 
#define TREAL		5
#define TLONGREAL	6

#define OP_ADD	0
#define NOPS	1	// number of operations/kernels


/*
	Object pool
*/
class ObjectPool
{	
protected:
	void** objs;
	long nObjs;
	CRITICAL_SECTION cs;

public:
	ObjectPool(void);
	~ObjectPool(void);
	
	long Length();	// returns length of the pool
	void* Get(long ind);	// returns an entry at givne position
	void* GetLast(void);	// get last object in the pool
	void Lock(){ EnterCriticalSection(&cs); };	// locks object both for writing and reading
	void Unlock(){ LeaveCriticalSection(&cs); };	// unlocks object
	virtual void Add(void* obj);	// add a new entry
	virtual void Remove(long ind);	// remove an entry given its position
	void RemoveAll();	// remove all entries
	long Find(void* obj);	// find an entry by its pointer, returns index of found entry or -1 if not found	
};

/*
	An array argument 
*/
class Argument
{	
public:
	Argument(CALdevice hDev, long argID, CALformat dFormat, long nDims, long* size, void* data);
	~Argument(void);
	CALresult AllocateLocal(CALuint flags);	// allocate local memory
	CALresult AllocateRemote(CALuint flags);	// allocate remote memory
	void FreeLocal(void);	// free local memory
	void FreeRemote(void);	// free remote memory
	CALresult FreeLocalKeepInRemote(CALcontext ctx);	// if possible store data in remote memory and free local memory
	CALresult SetDataToLocal(CALcontext ctx);	// sets data to local GPU memory
	CALresult SetDataToRemote(CALcontext ctx);	// sets data to remote GPU memory
	CALresult GetDataFromLocal(CALcontext ctx);	// get data from local GPU memory to the CPU memory
	CALresult GetDataFromRemote(CALcontext ctx);	// get data from remote GPU memory to the CPU memory
	CALresult CopyRemoteToLocal(CALcontext ctx);	// copy from remote memory to local
	CALresult CopyLocalToRemote(CALcontext ctx);	// copy from local memory to remote	
	CALresult CopyCPUToLocal(CALcontext ctx);		// copy from CPU memory to local
	CALresult CopyLocalToCPU(CALcontext ctx);		// copy from local memory to CPU 


	long argID;	// argument ID
	CALdevice hDev;	// device on which the argument exists
	long nDevs;	// number of devices
	void* cpuData;	// CPU data pointer
	CALformat dFormat;	// data format
	long nDims;	// number of dimensions
	long* size;	// argument size
	long dSize;	// data size in bytes
	CALresource remoteRes;	// remote GPU resource
	CALresource localRes;	// local GPU resource

	BOOL isInUse;	// flag indicating that argument is currently in use	
};


/*
	Object with GPU kernel description
*/
class Kernel
{
public:
	Kernel(long op, CALtarget target);
	~Kernel(void);	
	
	const char* funcName;	// function name
	const char* arg1Name;	// Arg1 name
	const char* arg2Name;	// Arg2 name
	const char* retArgName;	// RetArg name
	CALobject obj;
	CALimage img;
};


/*
	Kernel pool
*/
class KernelPool : public ObjectPool
{
public:
	KernelPool(void);
	~KernelPool(void);
	void Remove(long ind);
};

/*
	Module object
*/
class Module
{
public:
	Module(CALcontext ctx, Kernel* kern);
	~Module(void);

	CALcontext ctx;	
	CALmodule module;	
	Kernel* kern;

	CALfunc func;
	CALname arg1Name;
	CALname arg2Name;
	CALname retArgName;
};

class ModulePool : public ObjectPool
{
public:
	ModulePool(void);
	~ModulePool(void);
	Module* Get(long ind);	
	void Remove(long ind);
};

/*
	A computation context
*/
class Context
{
public:
	Context(CALdevice hDev, KernelPool* kernels);
	~Context(void);
	CALresult Do(long op);	// perform an operation
	CALcontext ctx;	// GPU context
	CALdevice hDev;

	// arguments of the current expression
	Argument* arg1;
	Argument* arg2;
	Argument* retArg;

	ModulePool* modules;
};

/*
	Used for excluding argument in Find procedures
*/
class Exclude 
{
public:
	Exclude(void);
	~Exclude(void);
	void Add(void* obj);	// add a new element in exclude list
	BOOL In(void* obj); // returns TRUE if an object is in exclude list

	void* obj;
	Exclude* next;
};


/*
	Argument pool
*/
class ArgumentPool : public ObjectPool
{
public:			
	ArgumentPool(void);
	~ArgumentPool(void);
	Argument* Get(long ind);
	long Find(long argID); // find an argument by given ID
	void Remove(long ind);	// remove an entry
	// find currently unused argument with maximum (from all arguments) allocated local memory
	Argument* FindMaxLocalNotInUse(Exclude* excl);
	// find currently unused argument with minimum (from all arguments) allocated local memory
	Argument* FindMinLocalNotInUse(Exclude* excl);
	// create a new argument and put it to the pool
	CALresult NewArgument(CALdevice hDev, CALcontext ctx, long argID, long dType, long nDims, long* size, void* data);
};


/*
	Context pool
*/
class ContextPool : public ObjectPool
{	
public:	
	ContextPool(CALdevice hDev);	
	~ContextPool(void);	
	CALdevice hDev;

	Context* Get(long ind);	
	void Remove(long ind);
	long Find(long ctx);
};


/*
	GPU Device object
*/
class Device
{
public:
	CALdevice hDev;
	ContextPool* ctxs;
	CALdeviceattribs attribs;
	
	KernelPool* kernels;	// device kernels
	ArgumentPool* args;		// arguments created on the device

	Device(long devNum);
	~Device(void);	
	CALresult NewContext(long* ctx);	
};

/*
	Pool with Device objects
*/
class DevicePool : public ObjectPool
{
public:	
	DevicePool(void);
	~DevicePool(void);
	Device* Get(long ind);	
	void Remove(long ind);
};






