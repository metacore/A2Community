#pragma once

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
