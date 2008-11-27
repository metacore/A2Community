#include "StdAfx.h"
#include "Modules.h"

Module::Module(CALcontext ctx, Kernel* kern)
{
	long i;
	module = 0;
	inputNames = NULL;
	outputNames = NULL;
	constNames = NULL;
	gbufName = 0;

	char str[8];
	
	this->ctx = ctx;
	this->kern = kern;	

	err = calModuleLoad(&module,ctx,kern->img);
	if(err != CAL_RESULT_OK)
	{
		module = 0; 
		return;
	}	
	err = calModuleGetEntry(&func,ctx,module,"main");
	if(err != CAL_RESULT_OK)
	{
		calModuleUnload(ctx,module); 
		module = 0; 
		return;
	}

	nInputs = kern->nInputs;
	nOutputs = kern->nOutputs;
	nConstants = kern->nConstants;
	usesGlobalBuffer = kern->usesGlobalBuffer;
	
	if(nInputs)
		inputNames = new CALname[nInputs];
	if(nOutputs)
		outputNames = new CALname[nOutputs];
	if(nConstants)
		constNames = new CALname[nConstants];

	for(i = 0; (i < nInputs) && (err == CAL_RESULT_OK); i++)
	{
		sprintf_s(str,"i%d",i);
		err = calModuleGetName(&inputNames[i],ctx,module,str);
	}
	if(err != CAL_RESULT_OK)
	{
		if(inputNames){delete inputNames; inputNames = NULL;}
		if(outputNames){delete outputNames; outputNames = NULL;}
		if(constNames){delete constNames; constNames = NULL;}
		calModuleUnload(ctx,module); 
		module = 0; 
		return;
	}
		
	for(i = 0; (i < nOutputs) && (err == CAL_RESULT_OK); i++)
	{
		sprintf_s(str,"o%d",i);
		err = calModuleGetName(&outputNames[i],ctx,module,str);
	}
	if(err != CAL_RESULT_OK)
	{
		if(inputNames){delete inputNames; inputNames = NULL;}
		if(outputNames){delete outputNames; outputNames = NULL;}
		if(constNames){delete constNames; constNames = NULL;}
		calModuleUnload(ctx,module); 
		module = 0; 
		return;
	}	

	for(i = 0; (i < nConstants) && (err == CAL_RESULT_OK); i++)
	{
		sprintf_s(str,"cb%d",i);
		err = calModuleGetName(&constNames[i],ctx,module,str);
	}
	if(err != CAL_RESULT_OK)
	{
		if(inputNames){delete inputNames; inputNames = NULL;}
		if(outputNames){delete outputNames; outputNames = NULL;}
		if(constNames){delete constNames; constNames = NULL;}
		calModuleUnload(ctx,module); 
		module = 0; 
		return;
	}

	if(usesGlobalBuffer)			
		err = calModuleGetName(&gbufName,ctx,module,"g[]");
	if(err != CAL_RESULT_OK)
	{
		if(inputNames){delete inputNames; inputNames = NULL;}
		if(outputNames){delete outputNames; outputNames = NULL;}
		if(constNames){delete constNames; constNames = NULL;}
		calModuleUnload(ctx,module); 
		module = 0; 
		return;
	}

}

Module::~Module(void)
{
	if(nInputs)
		delete inputNames;

	if(nOutputs)
		delete outputNames;

	if(nConstants)
		delete constNames;

	if(module)
		calModuleUnload(ctx,module);
}

ModulePool::ModulePool(void)
{
	err = CAL_RESULT_OK;
}


ModulePool::~ModulePool(void)
{
	RemoveAll();
}

Module* ModulePool::Get(long ind)
{
	return (Module*)ObjectPool::Get(ind);
}

void ModulePool::Remove(long ind)
{
	Module* module = Get(ind);
	if(module)
		delete module;
	
	ObjectPool::Remove(ind);
}
