#include "StdAfx.h"
#include "ObjectPool.h"

#define InitPoolLength	8
#define PoolIncLength	8

ObjectPool::ObjectPool(void)
{
	objs = NULL;
	nObjs = 0;

	len = InitPoolLength;
	objs = (void**)malloc(len*sizeof(void*));
}

ObjectPool::~ObjectPool(void)
{	
	free(objs);
}

// get length of the pool
long ObjectPool::Length(void)
{
	return nObjs;
}

// get an entry at given position
void* ObjectPool::Get(long ind)
{
	void* obj = NULL;
	
	if( (ind >= 0) && (ind < nObjs) ) 
		obj = objs[ind];

	return obj;
}

// get last entry in the pool
void* ObjectPool::GetLast(void)
{
	if(nObjs) 
		return objs[nObjs-1];
	else 
		return NULL;
}

// add a new entry
void ObjectPool::Add(void* obj)
{	
	// if necessary reallocate
	if(nObjs == len)
	{
		len += PoolIncLength;
		objs = (void**)realloc(&objs[0],len*sizeof(void*));
	}
	objs[nObjs] = obj;
	nObjs++;
}

// remove an entry given its position
void ObjectPool::Remove(long ind)
{
	long i;
	
	if( (ind >= 0) && (ind < nObjs) )
	{				
		for(i = ind; i < nObjs-1; i++) 
			objs[i] = objs[i+1];

		nObjs--;		
	}
}

// remove all pool entries
void ObjectPool::RemoveAll(void)
{	
	while(nObjs) Remove(nObjs-1);
}

// find an entry by its pointer, returns index of found entry or -1 if not found
long ObjectPool::Find(void* obj)
{
	long i;
	for(i = 0; (i < nObjs) && (objs[i] != obj); i++);
	if(i < nObjs) 
		return i; 
	else 
		return -1;
}
// set an object at given index
void ObjectPool::Set(long ind, void* obj)
{
	if( (ind >= 0) && (ind < nObjs) )
	{
		objs[ind] = obj;
	}
}
