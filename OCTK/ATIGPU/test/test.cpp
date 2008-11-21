// test.cpp : Defines the entry point for the console application.
//

#include "stdafx.h"
#include "Objects.h"

int _tmain(int argc, _TCHAR* argv[])
{
	Argument arg;
	arg.argID = 1;

	ArgumentPool argPool;
	long n;

	argPool.Add(arg);
	argPool.Add(arg);
	
	return 0;
}

