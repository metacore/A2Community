#pragma once
#include "ObjectPool.h"

/*
 REAL kernels
*/

// addition
#define KernAddR				0
#define KernAddLR				1

// subtraction
#define KernSubR				2
#define KernSubLR				3

// elementwise multiply
#define KernEwMulR				4
#define KernEwMulLR				5

// elementwise divide
#define KernEwDivR				6
#define KernEwDivLR				7

// dot product
#define KernDotProdR			8
#define KernDotProdLR			9

// matrix vector multiply
#define KernMatVecR				10

// assignment
#define KernAssign				11

#define NKernels				12	// total number of kernels

const char kernelAssign[] =
"il_ps_2_0\n"
"dcl_output_generic o0\n"
"dcl_cb cb0[1]\n"
"mov o0, cb0[0]\n"
"end\n";

// add
const char kernelAddR[] =
"il_ps_2_0\n"
"dcl_input_position_interp(linear_noperspective) vWinCoord0.xy__\n"
"dcl_output_generic o0\n"
"dcl_resource_id(0)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_resource_id(1)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"sample_resource(0)_sampler(0) r0, vWinCoord0\n"
"sample_resource(1)_sampler(1) r1, vWinCoord0\n"
"add o0, r0, r1\n"
"end\n";

const char kernelAddLR[] =
"il_ps_2_0\n"
"dcl_input_position_interp(linear_noperspective) vWinCoord0.xy__\n"
"dcl_output_generic o0\n"
"dcl_resource_id(0)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_resource_id(1)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"sample_resource(0)_sampler(0) r0, vWinCoord0\n"
"sample_resource(1)_sampler(1) r1, vWinCoord0\n"
"dadd o0.xy, r0.xy, r1.xy\n"
"dadd o0.zw, r0.zw, r1.zw\n"
"end\n";

/*
"il_ps_2_0\n"
"dcl_input_position_interp(linear_noperspective) vWinCoord0.xy__\n"
"dcl_resource_id(0)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_resource_id(1)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_literal l0, 0, 0, 0, 0\n"
"dcl_literal l1, 1024.0f, 1.0f, 0.0f, 0.0f\n" // pitch in number of components
"dcl_literal l2, 8, 1024, 0, 0\n"				// step in number of components, ntimes

// input 2D indexer
"mov r1, vWinCoord0\n"

// output linear indexer
"flr r0.y, r1.y\n"
"mul r0.x, r0.y, l1.x\n"
"ftoi r0.x, r0.x\n" // convert to integer index

"mov r2.x___, l0\n"
"whileloop\n"
"    ieq r2._y__, r2.x, l2.y\n"
"    break_logicalnz r2.y\n"

"	 sample_resource(0)_sampler(0) r3, r1\n"
"	 sample_resource(1)_sampler(1) r4, r1\n"
"    add r1.x___, r1.x, l1.y\n"

"	 sample_resource(0)_sampler(0) r5, r1\n"
"	 sample_resource(1)_sampler(1) r6, r1\n"
"    add r1.x___, r1.x, l1.y\n"

"	 sample_resource(0)_sampler(0) r7, r1\n"
"	 sample_resource(1)_sampler(1) r8, r1\n"
"    add r1.x___, r1.x, l1.y\n"

"	 sample_resource(0)_sampler(0) r9, r1\n"
"	 sample_resource(1)_sampler(1) r10, r1\n"
"	 add r1.x___, r1.x, l1.y\n"

//
"	 sample_resource(0)_sampler(0) r11, r1\n"
"	 sample_resource(1)_sampler(1) r12, r1\n"
"	 add r1.x___, r1.x, l1.y\n"

"	 sample_resource(0)_sampler(0) r13, r1\n"
"	 sample_resource(1)_sampler(1) r14, r1\n"
"	 add r1.x___, r1.x, l1.y\n"

"	 sample_resource(0)_sampler(0) r15, r1\n"
"	 sample_resource(1)_sampler(1) r16, r1\n"
"	 add r1.x___, r1.x, l1.y\n"

"	 sample_resource(0)_sampler(0) r17, r1\n"
"	 sample_resource(1)_sampler(1) r18, r1\n"
"	 add r1.x___, r1.x, l1.y\n"

//

"	 add r19, r3, r4\n"
"	 add r20, r5, r6\n"
"	 add r21, r7, r8\n"
"	 add r22, r9, r10\n"
"	 add r23, r11, r12\n"
"	 add r24, r13, r14\n"
"	 add r25, r15, r16\n"
"	 add r26, r17, r18\n"

"	 mov g[r0.x], r19\n"
"	 mov g[r0.x+1], r20\n"
"	 mov g[r0.x+2], r21\n"
"	 mov g[r0.x+3], r22\n"
"	 mov g[r0.x+4], r23\n"
"	 mov g[r0.x+5], r24\n"
"	 mov g[r0.x+6], r25\n"
"	 mov g[r0.x+7], r26\n"

"    iadd r2.x___, r2.x, l2.x\n"
"    iadd r0.x___, r0.x, l2.x\n"
"endloop\n"

"end\n";
*/

// subtract
const char kernelSubR[] =
"il_ps_2_0\n"
"dcl_input_position_interp(linear_noperspective) vWinCoord0.xy__\n"
"dcl_output_generic o0\n"
"dcl_resource_id(0)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_resource_id(1)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"sample_resource(0)_sampler(0) r0, vWinCoord0\n"
"sample_resource(1)_sampler(1) r1, vWinCoord0\n"
"sub o0, r0, r1\n"
"end\n";

const char kernelSubLR[] =
"il_ps_2_0\n"
"dcl_input_position_interp(linear_noperspective) vWinCoord0.xy__\n"
"dcl_output_generic o0\n"
"dcl_resource_id(0)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_resource_id(1)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"sample_resource(0)_sampler(0) r0, vWinCoord0\n"
"sample_resource(1)_sampler(1) r1, vWinCoord0\n"
"dcl_literal l0, 0x00000000, 0xBFF00000, 0x00000000, 0xBFF00000\n" // [-1.0D0, -1.0D0]
"dmad o0.xy, r1.xy, l0.xy, r0.xy\n"	// o0 = r1*(-1) + r0 == r0 - r1
"dmad o0.zw, r1.zw, l0.zw, r0.zw\n"	// o0 = r1*(-1) + r0 == r0 - r1
"end\n";

// naive matrix multiply: C{2D stream} := A{2D stream} * B{2D stream}
const char kernelNaiveMatMulR[] =
"il_ps_2_0\n"
"dcl_input_position_interp(linear_noperspective) vWinCoord0.xy__\n"
"dcl_output_generic o0\n"
"dcl_resource_id(0)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_resource_id(1)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"sample_resource(0)_sampler(0) r0, vWinCoord0\n"
"sample_resource(1)_sampler(1) r1, vWinCoord0\n"
"mul o0, r0, r1\n"
"end\n";

// elementwise multiply
const char kernelEwMulR[] =
"il_ps_2_0\n"
"dcl_input_position_interp(linear_noperspective) vWinCoord0.xy__\n"
"dcl_output_generic o0\n"
"dcl_resource_id(0)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_resource_id(1)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"sample_resource(0)_sampler(0) r0, vWinCoord0\n"
"sample_resource(1)_sampler(1) r1, vWinCoord0\n"
"mul o0, r0, r1\n"
"end\n";

const char kernelEwMulLR[] =
"il_ps_2_0\n"
"dcl_input_position_interp(linear_noperspective) vWinCoord0.xy__\n"
"dcl_output_generic o0\n"
"dcl_resource_id(0)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_resource_id(1)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"sample_resource(0)_sampler(0) r0, vWinCoord0\n"
"sample_resource(1)_sampler(1) r1, vWinCoord0\n"
"dmul o0.xy, r0.xy, r1.xy\n"
"dmul o0.zw, r0.zw, r1.zw\n"
"end\n";

// elementwise divide
const char kernelEwDivR[] =
"il_ps_2_0\n"
"dcl_input_position_interp(linear_noperspective) vWinCoord0.xy__\n"
"dcl_output_generic o0\n"
"dcl_resource_id(0)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_resource_id(1)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"sample_resource(0)_sampler(0) r0, vWinCoord0\n"
"sample_resource(1)_sampler(1) r1, vWinCoord0\n"
"div_zeroop(zero) o0, r0, r1\n"
"end\n";

const char kernelEwDivLR[] =
"il_ps_2_0\n"
"dcl_input_position_interp(linear_noperspective) vWinCoord0.xy__\n"
"dcl_output_generic o0\n"
"dcl_resource_id(0)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_resource_id(1)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"sample_resource(0)_sampler(0) r0, vWinCoord0\n"
"sample_resource(1)_sampler(1) r1, vWinCoord0\n"
"ddiv_zeroop(zero) o0.xy, r0.xy, r1.xy\n"
"ddiv_zeroop(zero) o0.zw, r0.zw, r1.zw\n"
"end\n";

// dot product
const char kernelDotProdR[] =
"il_ps_2_0\n"
"dcl_input_position_interp(linear_noperspective) vWinCoord0.xy__\n"
"dcl_output_generic o0\n"
"dcl_resource_id(0)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_resource_id(1)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"sample_resource(0)_sampler(0) r0, vWinCoord0\n"
"sample_resource(1)_sampler(1) r1, vWinCoord0\n"
"mul o0, r0, r1\n"
"end\n";

const char kernelDotProdLR[] =
"il_ps_2_0\n"
"dcl_input_position_interp(linear_noperspective) vWinCoord0.xy__\n"
"dcl_output_generic o0\n"
"dcl_resource_id(0)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_resource_id(1)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"sample_resource(0)_sampler(0) r0, vWinCoord0\n"
"sample_resource(1)_sampler(1) r1, vWinCoord0\n"
"dmul o0, r0, r1\n"
"end\n";

const char kernelMatVecR[] =
"il_ps_2_0\n"
"dcl_input_position_interp(linear_noperspective) vWinCoord0.xy__\n"
"dcl_cb cb0[1]\n"
"dcl_output_generic o0\n"
"dcl_literal l0, 0, 0, 0, 0\n"
"dcl_literal l1, 1, 0, 0, 0\n"
"dcl_literal l2, 1.0f, 1.0f, 0.0f, 0.0f\n"
"dcl_literal l3, 7.0f, 8.0f, 9.0f, 10.0f\n"
"dcl_resource_id(0)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_resource_id(1)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"

/*
"mov o0, l0\n"	// zeroing the output

"mov r0, vWinCoord0\n"	// input 2D index [x,y]

"mov r2, l0\n"	// r2.x is the loop counter
"whileloop\n"
"    ieq r2._y__, r2.x, cb0[0].x\n"	// while(loop counter != cb0[0].x)
"    break_logicalnz r2.y\n"

"	mov r1, r0\n"	// copy [x,y] position

// load a part of first row
"	sample_resource(0)_sampler(0) r3, r0\n"
"	sample_resource(1)_sampler(1) r4, r0\n"
// load a part of second row
"	add r1.y, r1.y, l2.y\n"
"	sample_resource(0)_sampler(0) r5, r1\n"
"	sample_resource(1)_sampler(1) r6, r1\n"
// load a part of third row
"	add r1.y, r1.y, l2.y\n"
"	sample_resource(0)_sampler(0) r7, r1\n"
"	sample_resource(1)_sampler(1) r8, r1\n"
// load a part of fourth row
"	add r1.y, r1.y, l2.y\n"
"	sample_resource(0)_sampler(0) r9, r1\n"
"	sample_resource(1)_sampler(1) r10, r1\n"

//"	dp4 o0.x___, r3, r4\n"		// r3+*r4
//"	dp4 o0._y__, r5, r6\n"		// r5+*r6
//"	dp4 o0.__z_, r7, r8\n"		// r7+*r8
//"	dp4 o0.___w, r9, r10\n"	// r9+*r10

//"	add o0, o0, r5.x\n"
"	iadd r2.x___, r2.x, l1.x\n"	// loop counter ++
"	add r0.x___, r0.x, l2.x\n"	// inputXIndex = inputXIndex + 1.0
"endloop\n"
*/
"mov o0, l3\n"

"end\n";

class Kernel
{
public:
	Kernel(long iKernel, CALtarget target);
	~Kernel(void);

	CALresult err;	// error code for last operation
	long iKernel;	// kernel code
	CALobject obj;	// CAL object
	CALimage img;	// CAL image

	long nInputs;	// number of kernel inputs
	long nOutputs;	// number of kernel outputs
	long nConstants;	// number of kernel constants
	BOOL usesGlobalBuffer;	// TRUE when kernel uses a global buffer
};

/*
	Pool of kernels
*/
class KernelPool :
	public ObjectPool
{
public:
	KernelPool(void);
	~KernelPool(void);	
	void Remove(long ind);

	CALresult err;	// error code for last operation
};
