#pragma once

class ObjectPool
{
protected:
	void** objs;					// array of object pointers
	long nObjs;						// number of objects in the pool
	long len;						// length of pointer array (>= nObjs)

public:
	ObjectPool(void);
	~ObjectPool(void);

	long Length(void);				// get length of the pool
	void* Get(long ind);			// get an entry at given position
	void* GetLast(void);			// get last object in the pool
	void Add(void* obj);			// add a new entry
	virtual void Remove(long ind);	// remove an entry given its position
	void RemoveAll(void);			// remove all pool entries
	long Find(void* obj);			// find an entry by its pointer, returns index of found entry or -1 if not found	
	// set an object at given index
	void Set(long ind, void* obj);
};