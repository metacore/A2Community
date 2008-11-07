// The following ifdef block is the standard way of creating macros which make exporting 
// from a DLL simpler. All files within this DLL are compiled with the CUDALIB_EXPORTS
// symbol defined on the command line. this symbol should not be defined on any project
// that uses this DLL. This way any other project whose source files include this file see 
// CUDALIB_API functions as being imported from a DLL, whereas this DLL sees symbols
// defined with this macro as being exported.
#ifdef CUDALIB_EXPORTS
//#define CUDALIB_API __declspec(dllexport)
#define CUDALIB_API extern "C" __declspec(dllexport)
#else
#define CUDALIB_API __declspec(dllimport)
#endif

#define NOT_INITIALIZED 1
#define DEV_FAILED_TO_MALLOC 2	// device failed to allocate memory
#define DEV_ACCESS_ERROR 3		// device data access error
#define DEV_EXEC_ERROR 4		// device execution error

//
// Computes C := alpha*op(A)*op(B) + beta*C (single/double precision)
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
CUDALIB_API long SGEMM(void* A, long transpA, void* B, long transpB, void* C, float alpha, float beta, long m, long n, long k);
CUDALIB_API long DGEMM(void* A, long transpA, void* B, long transpB, void* C, double alpha, double beta, long m, long n, long k);

//
// Computes y := alpha* op(A)*x + beta*y (single/double precision)
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
CUDALIB_API long SGEMV(void* A, long transpA, void* x, void* y, float alpha, float beta, long m, long n, long incx, long incy);
CUDALIB_API long DGEMV(void* A, long transpA, void* x, void* y, double alpha, double beta, long m, long n, long incx, long incy);

//
// Computes s := x+*y (single/double precision)
//	n - number of element in x and y
//	incx - increment of x
//	incy - increment of y
//
// Returns 0 in case of success, otherwise error code
//
CUDALIB_API long SDOT(void* x, void* y, long n, long incx, long incy, float* val);
CUDALIB_API long DDOT(void* x, void* y, long n, long incx, long incy, double* val);

//
//	returns TRUE if double precision is supported by the device
//
CUDALIB_API long IsDoubleSupported(void);