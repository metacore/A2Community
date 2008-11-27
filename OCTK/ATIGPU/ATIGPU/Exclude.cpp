#include "StdAfx.h"
#include "Exclude.h"

Exclude::Exclude(void)
{
	obj = NULL; 
	next = NULL;
};

Exclude::~Exclude(void)
{
	delete next;
};

void Exclude::Add(void* obj)
{
	if(next) 
		next->Add(obj);
	else if(this->obj)
	{
		next = new Exclude;
		next->obj = obj;
	}
	else	
		this->obj = obj;
};

BOOL Exclude::In(void* obj)
{
	if(next)
		if (this->obj == obj) 
			return TRUE;
		else
			return next->In(obj);
	else if(this->obj)	
		return this->obj == obj;
	else 
		return FALSE;
}