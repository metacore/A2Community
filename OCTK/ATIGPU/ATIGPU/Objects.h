#include <crtdbg.h>

#define TSHORTINT	1
#define TINTEGER	2
#define TLONGINT	3
#define THUGEINT	4 
#define TREAL		5
#define TLONGREAL	6

// operation codes
#define OpAdd		0	
#define OpSub		1
#define OpMul		2
#define OpDiv		3
#define OpDotProd	4
#define OpMulInc	5
#define	OpMulDec	6	
#define OpEwMul		7
#define OpEwDiv		8

/*
	Object with GPU kernel description
*/
class Kernel
{
public:
	Kernel(long op, CALtarget target);
	~Kernel(void);	
	
	long iKernel;	// kernel code

	CALobject obj;
	CALimage img;
};

/*
	Object pool
*/
class ObjectPool
{	
protected:
	void** objs;
	long nObjs;	

public:
	ObjectPool(void);
	~ObjectPool(void);
	
	long Length();	// returns length of the pool
	void* Get(long ind);	// returns an entry at givne position
	void* GetLast(void);	// get last object in the pool	
	virtual void Add(void* obj);	// add a new entry
	virtual void Remove(long ind);	// remove an entry given its position
	void RemoveAll();	// remove all entries
	long Find(void* obj);	// find an entry by its pointer, returns index of found entry or -1 if not found	
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

	CALname* inputNames;	// names of input parameters
	long nInputs;			// number of inputs
	CALname* outputNames;	// names of output parameters
	long nOutputs;			// number of outputs
	CALname* constNames;	// names of constant parameters
	long nConstants;		// number of constants
};

/*
	Pool with compute modules
*/
class ModulePool : public ObjectPool
{
public:
	ModulePool(void);
	~ModulePool(void);
	Module* Get(long ind);	
	void Remove(long ind);
};


/*
	An array argument 
*/
class Argument
{	
public:
	Argument(CALdevice hDev, CALdeviceinfo* devInfo, CALlong argID, long dType, long nDims, long* size, void* data);
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


	long argID;	// argument ID
	CALdevice hDev;	// device on which the argument exists	
	void* cpuData;	// CPU data pointer	
	long dType;	// data type code
	CALformat dFormat;	// data format
	long nDims;	// number of dimensions (logical)
	long* size;	// argument size
	long elemSize;	// element size in bytes	
	long physNumComponents;	// number of components in each element on GPU
	long physElemSize;	// physical element size
	long dataSize;		// data size in bytes
	long logicDataSize;	// logical data size in bytes
	long physDataSize;	// physical data size in bytes
	CALresource remoteRes;	// remote GPU resource
	CALresource localRes;	// local GPU resource	
	
	long nLogicDims;	// number of logical dimensions on the GPU (1D or 2D)
	long* logicSize;	// logical size on the GPU	
	long* physSize;		// physical size on the GPU with account of padding to 16 bytes

	BOOL isVirtualized;	// memory virtualization is used to fit to the hardware requirements
	long useCounter;	// counter for storing number of contextes which use the argument
	BOOL isReservedForGet;	// the object is reserved for furter getting (for example a return argument)	
};

/*
	A computation context
*/
class Context
{
public:
	Context(CALdevice hDev, KernelPool* kernels);
	~Context(void);	
	Module* GetSuitedModule(long op, CALdomain* domain);	// get module suited for given operation and arguments	
	CALresult DoElementwise(long op);	
	CALresult DoMul(void);
	CALresult DoDotProd(void);
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
	long FindMaxLocalNotInUse1(Exclude* excl);
	// find currently unused argument with minimum (from all arguments) allocated local memory
	Argument* FindMinLocalNotInUse(Exclude* excl);
	long FindMinLocalNotInUse1(Exclude* excl);
	// create a new argument and put it to the pool
	CALresult NewArgument(CALdevice hDev, CALdeviceinfo* devInfo, CALcontext ctx, long argID, long dType, long nDims, long* size, void* data, CALuint flags);
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
	CALdeviceinfo info;
	
	CALuint devNum;	// device index
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






