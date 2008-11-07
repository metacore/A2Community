// cudalib.cpp : Defines the entry point for the DLL application.
//

#include "stdafx.h"

static DWORD dwTlsIndex; // address of shared memory
static long isLoaded = FALSE; // TRUE when dll is loaded by a process
long isInitialized = FALSE; // TRUE when interface is initialized by some thread (only a single thread)
static long thereIsAnActiveThread = FALSE; // TRUE when there is an active thread

// device memory pull (X,Y,Z are in size decreasing order)
void* dMemX = 0; long szMemX = 0;
void* dMemY = 0; long szMemY = 0;
void* dMemZ = 0; long szMemZ = 0;

#ifdef _MANAGED
#pragma managed(push, off)
#endif

// returns 1 if current thread is active
long IsActiveThread()
{
	LPVOID lpvData;	
	long* pVal;
	
	if(isInitialized)
	{
		lpvData = TlsGetValue(dwTlsIndex);         
		if(lpvData != NULL)
		{
			pVal = (long*)lpvData; 
			return *pVal;
		}
		else return 0;
	}
	else return 0;
}

long CheckForActiveThread()
{	
	if(isInitialized)
	{
		if(thereIsAnActiveThread) return IsActiveThread();
		else // set current as active 
		{
			LPVOID lpvData = TlsGetValue(dwTlsIndex);         
			if(lpvData != NULL) 
			{
				*((long*)lpvData) = 1;			
				return 1;
			}
			else return 0;
		}
	}
	else return 0;
}

BOOL APIENTRY DllMain( HMODULE hModule,
                       DWORD  ul_reason_for_call,
                       LPVOID lpReserved
					 )
{	
	LPVOID lpvData;	

	switch (ul_reason_for_call)
	{
	case DLL_PROCESS_ATTACH:
		if(!isLoaded) 
		{
			// Allocate a TLS index. 
            if ((dwTlsIndex = TlsAlloc()) == TLS_OUT_OF_INDEXES) return FALSE; 
			lpvData = (LPVOID)LocalAlloc(LPTR,sizeof(long));
			if(lpvData != NULL) 
			{
				*((long*)(lpvData)) = 0;
				TlsSetValue(dwTlsIndex,lpvData);		
			}
			else return FALSE;

			if(cublasInit() == CUBLAS_STATUS_SUCCESS) isInitialized = TRUE;
						
			isLoaded = TRUE;
		}
		else
		{
			MessageBox(NULL,L"Only one process is alowed to load the library!",L"Error",MB_OK);
			return FALSE;
		}
		break;			
	case DLL_THREAD_ATTACH:
		
		// Initialize the TLS index for this thread.				
        lpvData = (LPVOID)LocalAlloc(LPTR,sizeof(long));
        if(lpvData != NULL) 
		{
			*((long*)(lpvData)) = 0;
			TlsSetValue(dwTlsIndex,lpvData);		
		}

		break;
	case DLL_THREAD_DETACH:							
		
		// if it is thread which initialized the interface - free all resources!
		if(IsActiveThread())
		{			
			// free device memory
			if(szMemX){ cublasFree(dMemX); szMemX = 0; }
			if(szMemY){ cublasFree(dMemY); szMemY = 0; }
			if(szMemZ){ cublasFree(dMemZ); szMemZ = 0; }			
		}	

		lpvData = TlsGetValue(dwTlsIndex); 
        if(lpvData != NULL) LocalFree((HLOCAL)lpvData);

		break;
	case DLL_PROCESS_DETACH:		
		
		// if it is thread which initialized the interface - free all resources!
		if(IsActiveThread())
		{			
			// free device memory
			if(szMemX){ cublasFree(dMemX); szMemX = 0; }
			if(szMemY){ cublasFree(dMemY); szMemY = 0; }
			if(szMemZ){ cublasFree(dMemZ); szMemZ = 0; }			
		}	

		lpvData = TlsGetValue(dwTlsIndex); 
        if(lpvData != NULL) LocalFree((HLOCAL)lpvData);

        // Release the TLS index. 
        TlsFree(dwTlsIndex); 

		cublasShutdown();
		isInitialized = FALSE;
		isLoaded = FALSE;	

		break;
	}
    return TRUE;
}

#ifdef _MANAGED
#pragma managed(pop)
#endif

//
//	returns TRUE if double precision is supported by the device
//
CUDALIB_API long IsDoubleSupported(void)
{
	return FALSE;
}

//
// Computes C := alpha*op(A)*op(B) + beta*C (single precision)
// op(A): [m,k]
// op(B): [k,n]
// C: [m,n]
//	if transpA = 0 then op(A)[m,k]=A[m,k] else op(A)[m,k]=(A[k,m])^T
//	if transpB = 0 then op(B)[k,n]=B[k,n] else op(B)[k,n]=(B[n,k])^T
//
//	matrices assumed to be stored in row-major format (compatible to Oberon, Pascal, C, C++)
//
// Returns 0 in case of success, otherwise error code
//
CUDALIB_API long SGEMM(void* A, long transpA, void* B, long transpB, void* C, float alpha, float beta, long m, long n, long k)
{
	long status;

	void* d_A;
    void* d_B;
    void* d_C;		

	if(1/*CheckForActiveThread()*/)			
	{	
		long dsize = sizeof(float);

		long szA = m*k*dsize;
		long szB = k*n*dsize;
		long szC = m*n*dsize;

		if( (szC >= szA) && (szC >= szB) )
		{				
			if(szMemX < szC)
			{
				status = cublasAlloc(szC,1,(void**)&dMemX);
				if (status != CUBLAS_STATUS_SUCCESS) return DEV_FAILED_TO_MALLOC;
				szMemX = szC;
			}
			d_C = dMemX;

			if(szA >= szB) // order C,A,B
			{
				if(szMemY < szA)
				{
					status = cublasAlloc(szA,1,(void**)&dMemY);
					if (status != CUBLAS_STATUS_SUCCESS) return DEV_FAILED_TO_MALLOC;
					szMemY = szA;
				}
				d_A = dMemY;

				if(szMemZ < szB)
				{
					status = cublasAlloc(szB,1,(void**)&dMemZ);
					if (status != CUBLAS_STATUS_SUCCESS) return DEV_FAILED_TO_MALLOC;
					szMemZ = szB;
				}
				d_B = dMemZ;
			}
			else // order C,B,A
			{
				if(szMemY < szB)
				{
					status = cublasAlloc(szB,1,(void**)&dMemY);
					if (status != CUBLAS_STATUS_SUCCESS) return DEV_FAILED_TO_MALLOC;
					szMemY = szB;
				}
				d_B = dMemY;

				if(szMemZ < szA)
				{
					status = cublasAlloc(szA,1,(void**)&dMemZ);
					if (status != CUBLAS_STATUS_SUCCESS) return DEV_FAILED_TO_MALLOC;
					szMemZ = szA;
				}
				d_A = dMemZ;
			}
		}
		else if( szA >= szB )// order: A, B, C
		{
			if(szMemX < szA)
			{
				status = cublasAlloc(szA,1,(void**)&dMemX);
				if (status != CUBLAS_STATUS_SUCCESS) return DEV_FAILED_TO_MALLOC;
				szMemX = szA;
			}
			d_A = dMemX;

			if(szMemY < szB)
			{
				status = cublasAlloc(szB,1,(void**)&dMemY);
				if (status != CUBLAS_STATUS_SUCCESS) return DEV_FAILED_TO_MALLOC;
				szMemY = szB;
			}
			d_B = dMemY;

			if(szMemZ < szC)
			{
				status = cublasAlloc(szC,1,(void**)&dMemZ);
				if (status != CUBLAS_STATUS_SUCCESS) return DEV_FAILED_TO_MALLOC;
				szMemZ = szC;
			}
			d_C = dMemZ;
		}
		else // order B,A,C
		{
			if(szMemX < szB)
			{
				status = cublasAlloc(szB,1,(void**)&dMemX);
				if (status != CUBLAS_STATUS_SUCCESS) return DEV_FAILED_TO_MALLOC;
				szMemX = szB;
			}
			d_B = dMemX;

			if(szMemY < szA)
			{
				status = cublasAlloc(szA,1,(void**)&dMemY);
				if (status != CUBLAS_STATUS_SUCCESS) return DEV_FAILED_TO_MALLOC;
				szMemY = szA;
			}
			d_A = dMemY;

			if(szMemZ < szC)
			{
				status = cublasAlloc(szC,1,(void**)&dMemZ);
				if (status != CUBLAS_STATUS_SUCCESS) return DEV_FAILED_TO_MALLOC;
				szMemZ = szC;
			}
			d_C = dMemZ;
		}

		// initialize the device matrices with the host matrices
		status = cublasSetVector(m*k,dsize,A,1,d_A,1);
		if (status != CUBLAS_STATUS_SUCCESS) return DEV_ACCESS_ERROR;		

		status = cublasSetVector(k*n,dsize,B,1,d_B,1);
		if (status != CUBLAS_STATUS_SUCCESS) return DEV_ACCESS_ERROR;		

		if(beta != 0)
		{
			status = cublasSetVector(m*n,dsize,C,1,d_C,1);
			if (status != CUBLAS_STATUS_SUCCESS) return DEV_ACCESS_ERROR;			
		}

		// compute operation
		if(transpA == 0)
		{
			if(transpB == 0) // transpA==0, transpB==0
				cublasSgemm('n','n',n,m,k,alpha,(float*)d_B,n,(float*)d_A,k,beta,(float*)d_C,n);
			else // transpA==0, transpB==1
				cublasSgemm('t','n',n,m,k,alpha,(float*)d_B,k,(float*)d_A,k,beta,(float*)d_C,n);
		}
		else if(transpB = 0) // transpA==1, transpB==0
			cublasSgemm('n','t',n,m,k,alpha,(float*)d_B,n,(float*)d_A,m,beta,(float*)d_C,n);
		else // transpA==1, transpB==1
			cublasSgemm('t','t',n,m,k,alpha,(float*)d_B,k,(float*)d_A,m,beta,(float*)d_C,n);

		status = cublasGetError();
		if(status != CUBLAS_STATUS_SUCCESS) return DEV_EXEC_ERROR;		

		// copy data from device to the host
		status = cublasGetVector(m*n,dsize,d_C,1,C,1);
		if (status != CUBLAS_STATUS_SUCCESS) return DEV_ACCESS_ERROR;		

		return 0;
	}
	else return DEV_ACCESS_ERROR;		
}

//
// Computes C := alpha*op(A)*op(B) + beta*C (double precision)
// op(A): [m,k]
// op(B): [k,n]
// C: [m,n]
//	if transpA = 0 then op(A)[m,k]=A[m,k] else op(A)[m,k]=(A[k,m])^T
//	if transpB = 0 then op(B)[k,n]=B[k,n] else op(B)[k,n]=(B[n,k])^T
//
//	matrices assumed to be stored in row-major format (compatible to Oberon, Pascal, C, C++)
//
// Returns 0 in case of success, otherwise error code
//
CUDALIB_API long DGEMM(void* A, long transpA, void* B, long transpB, void* C, double alpha, double beta, long m, long n, long k)
{
	long status;

	void* d_A;
    void* d_B;
    void* d_C;	

	if(CheckForActiveThread())			
	{
		long dsize = sizeof(double);

		// allocate device memory for the matrices
		status = cublasAlloc(m*k,dsize,(void**)&d_A);
		if (status != CUBLAS_STATUS_SUCCESS) return DEV_FAILED_TO_MALLOC;		

		status = cublasAlloc(k*n,dsize,(void**)&d_B);
		if (status != CUBLAS_STATUS_SUCCESS) 
		{	        
			status = cublasFree(d_A);
			return DEV_FAILED_TO_MALLOC;
		}	

		status = cublasAlloc(m*n,dsize,(void**)&d_C);
	    if (status != CUBLAS_STATUS_SUCCESS) 
		{		
			status = cublasFree(d_A);
			status = cublasFree(d_B);
			return DEV_FAILED_TO_MALLOC;
		}

		// initialize the device matrices with the host matrices
		status = cublasSetVector(m*k,dsize, A, 1, d_A, 1);
		if (status != CUBLAS_STATUS_SUCCESS)
		{
			status = cublasFree(d_A);
			status = cublasFree(d_B);
			status = cublasFree(d_C);
			return DEV_ACCESS_ERROR;
		}

		status = cublasSetVector(k*n,dsize, B, 1, d_B, 1);
		if (status != CUBLAS_STATUS_SUCCESS)
		{
			status = cublasFree(d_A);
			status = cublasFree(d_B);
			status = cublasFree(d_C);
			return DEV_ACCESS_ERROR;
		}
		
		if(beta != 0)
		{
			status = cublasSetVector(m*n,dsize, C, 1, d_C, 1);
			if (status != CUBLAS_STATUS_SUCCESS)
			{
				status = cublasFree(d_A);
				status = cublasFree(d_B);
				status = cublasFree(d_C);
				return DEV_ACCESS_ERROR;
			}
		}

		// compute operation
		if(transpA == 0)
		{
			if(transpB == 0) // transpA==0, transpB==0
				cublasDgemm('n','n',n,m,k,alpha,(double*)d_B,n,(double*)d_A,k,beta,(double*)d_C,n);
			else // transpA==0, transpB==1
				cublasDgemm('t','n',n,m,k,alpha,(double*)d_B,k,(double*)d_A,k,beta,(double*)d_C,n);
		}
		else if(transpB = 0) // transpA==1, transpB==0
			cublasDgemm('n','t',n,m,k,alpha,(double*)d_B,n,(double*)d_A,m,beta,(double*)d_C,n);
		else // transpA==1, transpB==1
			cublasDgemm('t','t',n,m,k,alpha,(double*)d_B,k,(double*)d_A,m,beta,(double*)d_C,n);

		status = cublasGetError();
		if(status != CUBLAS_STATUS_SUCCESS) 
		{
			status = cublasFree(d_A);
			status = cublasFree(d_B);
			status = cublasFree(d_C);
			return DEV_EXEC_ERROR;
		}

		// copy data from device to the host
		status = cublasGetVector(m*n,dsize,d_C,1,C,1);
		if (status != CUBLAS_STATUS_SUCCESS)
		{
			status = cublasFree(d_A);
			status = cublasFree(d_B);
			status = cublasFree(d_C);
			return DEV_ACCESS_ERROR;
		}

		// free device memory
		status = cublasFree(d_A);
		status = cublasFree(d_B);
		status = cublasFree(d_C);

		return 0;
	}
	else return DEV_ACCESS_ERROR;		
}


//
// Computes y := alpha* op(A)*x + beta*y (single precision)
//	n - number of element in x and y
//	incx - increment of x
//  incy - increment of y
//	op(A): [m,n] 
//	if transpA = 0 then op(A)[m,k]=A[m,k] else op(A)[m,k]=(A[k,m])^T
//
//	matrix assumed to be stored in row-major format (compatible to Oberon, Pascal, C, C++)
//
// Returns 0 in case of success, otherwise error code
//
CUDALIB_API long SGEMV(void* A, long transpA, void* x, void* y, float alpha, float beta, long m, long n, long incx, long incy)
{
	long status, k;

	void* d_A;
    void* d_x;
    void* d_y;			

	if(CheckForActiveThread())			
	{	
		long dsize = sizeof(float);

		k = m*n*dsize;
		if(szMemX < k)		
		{			
			status = cublasAlloc(k,1,(void**)&dMemX);
			if (status != CUBLAS_STATUS_SUCCESS) return DEV_FAILED_TO_MALLOC;
			szMemX = k;
		}
		d_A = dMemX;
		
		k = n*dsize;
		if(szMemY < k)		
		{			
			status = cublasAlloc(k,1,(void**)&dMemY);
			if (status != CUBLAS_STATUS_SUCCESS) return DEV_FAILED_TO_MALLOC;
			szMemY = k;
		}
		d_x = dMemY;
		
		if(szMemZ < k)		
		{			
			status = cublasAlloc(k,1,(void**)&dMemZ);
			if (status != CUBLAS_STATUS_SUCCESS) return DEV_FAILED_TO_MALLOC;
			szMemZ = k;
		}
		d_y = dMemZ;
		
		// initialize the device matrices with the host matrices
		status = cublasSetVector(m*n,dsize,A,1,d_A,1);
		if (status != CUBLAS_STATUS_SUCCESS) return DEV_ACCESS_ERROR;		

		status = cublasSetVector(n,dsize,x,incx,d_x,1);
		if (status != CUBLAS_STATUS_SUCCESS) return DEV_ACCESS_ERROR;
		
		if(beta != 0)
		{
			status = cublasSetVector(n,dsize,y,incy,d_y,1);
			if (status != CUBLAS_STATUS_SUCCESS) return DEV_ACCESS_ERROR;
		}

		// compute operation
		if(transpA == 0)		
			cublasSgemv('t',m,n,alpha,(float*)d_A,n,(float*)d_x,1,beta,(float*)d_y,1);		
		else
			cublasSgemv('n',m,n,alpha,(float*)d_A,m,(float*)d_x,1,beta,(float*)d_y,1);

		status = cublasGetError();
		if(status != CUBLAS_STATUS_SUCCESS) return DEV_EXEC_ERROR;		

		// copy data from device to the host
		status = cublasGetVector(n,dsize,d_y,1,y,incy);
		if (status != CUBLAS_STATUS_SUCCESS) return DEV_ACCESS_ERROR;		

		return 0;
	}
	else return DEV_ACCESS_ERROR;		
}

//
// Computes y := alpha* op(A)*x + beta*y (double precision)
//	n - number of element in x and y
//	incx - increment of x
//  incy - increment of y
//	op(A): [m,n] 
//	if transpA = 0 then op(A)[m,k]=A[m,k] else op(A)[m,k]=(A[k,m])^T
//
//	matrix assumed to be stored in row-major format (compatible to Oberon, Pascal, C, C++)
//
// Returns 0 in case of success, otherwise error code
//
CUDALIB_API long DGEMV(void* A, long transpA, void* x, void* y, double alpha, double beta, long m, long n, long incx, long incy)
{
	long status, k;

	void* d_A;
    void* d_x;
    void* d_y;			

	if(CheckForActiveThread())			
	{	
		long dsize = sizeof(double);

		k = m*n*dsize;
		if(szMemX < k)		
		{			
			status = cublasAlloc(k,1,(void**)&dMemX);
			if (status != CUBLAS_STATUS_SUCCESS) return DEV_FAILED_TO_MALLOC;
			szMemX = k;
		}
		d_A = dMemX;
		
		k = n*dsize;
		if(szMemY < k)		
		{			
			status = cublasAlloc(k,1,(void**)&dMemY);
			if (status != CUBLAS_STATUS_SUCCESS) return DEV_FAILED_TO_MALLOC;
			szMemY = k;
		}
		d_x = dMemY;
		
		if(szMemZ < k)		
		{			
			status = cublasAlloc(k,1,(void**)&dMemZ);
			if (status != CUBLAS_STATUS_SUCCESS) return DEV_FAILED_TO_MALLOC;
			szMemZ = k;
		}
		d_y = dMemZ;
		
		// initialize the device matrices with the host matrices
		status = cublasSetVector(m*n,dsize,A,1,d_A,1);
		if (status != CUBLAS_STATUS_SUCCESS) return DEV_ACCESS_ERROR;		

		status = cublasSetVector(n,dsize,x,incx,d_x,1);
		if (status != CUBLAS_STATUS_SUCCESS) return DEV_ACCESS_ERROR;
		
		if(beta != 0)
		{
			status = cublasSetVector(n,dsize,y,incy,d_y,1);
			if (status != CUBLAS_STATUS_SUCCESS) return DEV_ACCESS_ERROR;
		}

		// compute operation
		if(transpA == 0)		
			cublasDgemv('t',m,n,alpha,(double*)d_A,n,(double*)d_x,1,beta,(double*)d_y,1);		
		else
			cublasDgemv('n',m,n,alpha,(double*)d_A,m,(double*)d_x,1,beta,(double*)d_y,1);

		status = cublasGetError();
		if(status != CUBLAS_STATUS_SUCCESS) return DEV_EXEC_ERROR;		

		// copy data from device to the host
		status = cublasGetVector(n,dsize,d_y,1,y,incy);
		if (status != CUBLAS_STATUS_SUCCESS) return DEV_ACCESS_ERROR;		

		return 0;
	}
	else return DEV_ACCESS_ERROR;
}

//
// Computes s := x+*y (single precision)
//	n - number of element in x and y
//	incx - increment of x
//	incy - increment of y
//
// Returns 0 in case of success, otherwise error code
//
CUDALIB_API long SDOT(void* x, void* y, long n, long incx, long incy, float* val)
{
	long status, k;

	void* d_x;
    void* d_y;	
		
	if(CheckForActiveThread())			
	{	
		long dsize = sizeof(float);

		k = n*dsize;
		if(szMemX < k)
		{			
			status = cublasAlloc(k,1,(void**)&dMemX);
			if (status != CUBLAS_STATUS_SUCCESS) return DEV_FAILED_TO_MALLOC;
			szMemX = k;
		}
		d_x = dMemX;

		if(szMemY < k)
		{			
			status = cublasAlloc(k,1,(void**)&dMemY);
			if (status != CUBLAS_STATUS_SUCCESS) return DEV_FAILED_TO_MALLOC;
			szMemY = k;
		}
		d_y = dMemY;

		// initialize the device vectors with the host vectors
		status = cublasSetVector(n,dsize,x,incx,d_x,1);
		if (status != CUBLAS_STATUS_SUCCESS) return DEV_ACCESS_ERROR;		

		status = cublasSetVector(n,dsize,y,incy,d_y,1);
		if (status != CUBLAS_STATUS_SUCCESS) return DEV_ACCESS_ERROR;		

		*val = cublasSdot(n,(float*)d_x,1,(float*)d_y,1);
		
		status = cublasGetError();
		if(status != CUBLAS_STATUS_SUCCESS) return DEV_EXEC_ERROR;		

		return 0;
	}
	else return DEV_ACCESS_ERROR;

}

//
// Computes s := x+*y (double precision)
//	n - number of element in x and y
//	incx - increment of x
//	incy - increment of y
//
// Returns 0 in case of success, otherwise error code
//
CUDALIB_API long DDOT(void* x, void* y, long n, long incx, long incy, double* val)
{
	long status, k;

	void* d_x;
    void* d_y;	
		
	if(CheckForActiveThread())			
	{	
		long dsize = sizeof(double);

		k = n*dsize;
		if(szMemX < k)
		{			
			status = cublasAlloc(k,1,(void**)&dMemX);
			if (status != CUBLAS_STATUS_SUCCESS) return DEV_FAILED_TO_MALLOC;
			szMemX = k;
		}
		d_x = dMemX;

		if(szMemY < k)
		{			
			status = cublasAlloc(k,1,(void**)&dMemY);
			if (status != CUBLAS_STATUS_SUCCESS) return DEV_FAILED_TO_MALLOC;
			szMemY = k;
		}
		d_y = dMemY;

		// initialize the device vectors with the host vectors
		status = cublasSetVector(n,dsize,x,incx,d_x,1);
		if (status != CUBLAS_STATUS_SUCCESS) return DEV_ACCESS_ERROR;		

		status = cublasSetVector(n,dsize,y,incy,d_y,1);
		if (status != CUBLAS_STATUS_SUCCESS) return DEV_ACCESS_ERROR;		

		*val = cublasDdot(n,(double*)d_x,1,(double*)d_y,1);
		
		status = cublasGetError();
		if(status != CUBLAS_STATUS_SUCCESS) return DEV_EXEC_ERROR;		

		return 0;
	}
	else return DEV_ACCESS_ERROR;

}