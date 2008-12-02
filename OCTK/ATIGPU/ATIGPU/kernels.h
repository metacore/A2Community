#pragma once
#include "ObjectPool.h"

#define GBufBurstSize						64	// global buffer burst size in bytes
#define MinFillPhysNumElements_PS			64	// minimal data size in bytes used for filling memory using pixel shader kernels

/*
 REAL kernels
*/

// data filling kernels
enum KernelCode
{
KernFillByNComp_PS,		// pixel shader for filling memory by NumComponents elements per thread
KernFillBy2xNComp_CS,	// compute shader for filling memory by 2xNumComponents elements per thread
KernFillBy4xNComp_CS,	// compute shader for filling memory by 4xNumComponents elements per thread
KernFillBy8xNComp_CS,	// compute shader for filling memory by 8xNumComponents elements per thread
KernFillBy16xNComp_CS,	// compute shader for filling memory by 16xNumComponents elements per thread

// addition
KernAddR_PS,
KernAddR_CS,
KernAddLR_PS,

// subtraction
KernSubR_PS,
KernSubR_CS,
KernSubLR_PS,

// elementwise multiply
KernEwMulR_PS,
KernEwMulR_CS,
KernEwMulLR_PS,

// elementwise divide
KernEwDivR_PS,
KernEwDivR_CS,
KernEwDivLR_PS,

// matrix vector multiply
KernMatVecR_PS
};

// total number of kernels
#define NKernels				18

const char kernelFillByNComp_PS[] =
"il_ps_2_0\n"
"dcl_output_generic o0\n"
"dcl_cb cb0[1]\n"
"mov o0, cb0[0]\n"
"end\n";

const char kernelFillBy2xNComp_CS[] =
"il_cs_2_0\n"
"dcl_num_thread_per_group 64\n"
"dcl_cb cb0[1]\n"
"mov r0, vaTid0.x\n"
"dcl_literal l0, 2, 0, 0, 0\n"
"imul r0.x, r0.x, l0.x\n"
"mov g[r0.x], cb0[0]\n"
"mov g[r0.x+1], cb0[0]\n"
"end\n";

const char kernelFillBy4xNComp_CS[] =
"il_cs_2_0\n"
"dcl_num_thread_per_group 64\n"
"dcl_cb cb0[1]\n"
"mov r0, vaTid0.x\n"
"dcl_literal l0, 4, 0, 0, 0\n"
"imul r0.x, r0.x, l0.x\n"
"mov g[r0.x], cb0[0]\n"
"mov g[r0.x+1], cb0[0]\n"
"mov g[r0.x+2], cb0[0]\n"
"mov g[r0.x+3], cb0[0]\n"
"end\n";

const char kernelFillBy8xNComp_CS[] =
"il_cs_2_0\n"
"dcl_num_thread_per_group 64\n"
"dcl_cb cb0[1]\n"
"mov r0, vaTid0.x\n"
"dcl_literal l0, 8, 0, 0, 0\n"
"imul r0.x, r0.x, l0.x\n"
"mov g[r0.x], cb0[0]\n"
"mov g[r0.x+1], cb0[0]\n"
"mov g[r0.x+2], cb0[0]\n"
"mov g[r0.x+3], cb0[0]\n"
"mov g[r0.x+4], cb0[0]\n"
"mov g[r0.x+5], cb0[0]\n"
"mov g[r0.x+6], cb0[0]\n"
"mov g[r0.x+7], cb0[0]\n"
"end\n";

const char kernelFillBy16xNComp_CS[] =
"il_cs_2_0\n"
"dcl_num_thread_per_group 64\n"
"dcl_cb cb0[1]\n"
"mov r0, vaTid0.x\n"
"dcl_literal l0, 16, 0, 0, 0\n"
"imul r0.x, r0.x, l0.x\n"
"mov g[r0.x], cb0[0]\n"
"mov g[r0.x+1], cb0[0]\n"
"mov g[r0.x+2], cb0[0]\n"
"mov g[r0.x+3], cb0[0]\n"
"mov g[r0.x+4], cb0[0]\n"
"mov g[r0.x+5], cb0[0]\n"
"mov g[r0.x+6], cb0[0]\n"
"mov g[r0.x+7], cb0[0]\n"
"mov g[r0.x+8], cb0[0]\n"
"mov g[r0.x+9], cb0[0]\n"
"mov g[r0.x+10], cb0[0]\n"
"mov g[r0.x+11], cb0[0]\n"
"mov g[r0.x+12], cb0[0]\n"
"mov g[r0.x+13], cb0[0]\n"
"mov g[r0.x+14], cb0[0]\n"
"mov g[r0.x+15], cb0[0]\n"
"end\n";

const char kernelAddR_PS[] =
"il_ps_2_0\n"
"dcl_input_position_interp(linear_noperspective) vWinCoord0.xy__\n"
"dcl_output_generic o0\n"
"dcl_resource_id(0)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_resource_id(1)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"sample_resource(0)_sampler(0) r0, vWinCoord0\n"
"sample_resource(1)_sampler(1) r1, vWinCoord0\n"
"add o0, r0, r1\n"
"end\n";

const char kernelAddLR_PS[] =
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

const char kernelAddR_CS[] =
"il_cs_2_0\n"
"dcl_num_thread_per_blk 64\n"
"dcl_resource_id(0)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_resource_id(1)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_cb cb0[1]\n"

"ftoi r0.x, cb0[0].w"
"ilt r0.y, vaTid0.x, r0.x\n"

"if_logicalnz r0.y\n"
"	itof r0.z, vaTid0.x\n"				// r0.z := thread_index
"	mul r0.y, r0.z, cb0[0].y\n"			// r0.y := thread_index*(1/width) == y index
"	mod r0.x, r0.z, cb0[0].x\n"			// r0.x := thread_index % width == x index
"	flr r0.xy, r0.xy\n"					// [x,y] := floor(r0.xy)
"	mad r1.x, r0.y, cb0[0].z, r0.x\n"	// index := y*pitch + x - index with account of the alignment pitch
"	ftoi r1.x, r1.x"					// convert to integer
"	sample_resource(0)_sampler(0) r2, r0.xy\n"
"	sample_resource(1)_sampler(1) r3, r0.xy\n"
"	add r4, r2, r3\n"
"	mov g[r1.x], r4\n"
"endif\n"

"end\n";

const char kernelSubR_CS[] =
"il_cs_2_0\n"
"dcl_num_thread_per_blk 64\n"
"dcl_resource_id(0)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_resource_id(1)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_cb cb0[1]\n"

"ftoi r0.x, cb0[0].w"
"ilt r0.y, vaTid0.x, r0.x\n"

"if_logicalnz r0.y\n"
"	itof r0.z, vaTid0.x\n"				// r0.z := thread_index
"	mul r0.y, r0.z, cb0[0].y\n"			// r0.y := thread_index*(1/width) == y index
"	mod r0.x, r0.z, cb0[0].x\n"			// r0.x := thread_index % width == x index
"	flr r0.xy, r0.xy\n"					// [x,y] := floor(r0.xy)
"	mad r1.x, r0.y, cb0[0].z, r0.x\n"	// index := y*pitch + x - index with account of the alignment pitch
"	ftoi r1.x, r1.x"					// convert to integer
"	sample_resource(0)_sampler(0) r2, r0.xy\n"
"	sample_resource(1)_sampler(1) r3, r0.xy\n"
"	sub r4, r2, r3\n"
"	mov g[r1.x], r4\n"
"endif\n"

"end\n";

const char kernelEwMulR_CS[] =
"il_cs_2_0\n"
"dcl_num_thread_per_blk 64\n"
"dcl_resource_id(0)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_resource_id(1)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_cb cb0[1]\n"

"ftoi r0.x, cb0[0].w"
"ilt r0.y, vaTid0.x, r0.x\n"

"if_logicalnz r0.y\n"
"	itof r0.z, vaTid0.x\n"				// r0.z := thread_index
"	mul r0.y, r0.z, cb0[0].y\n"			// r0.y := thread_index*(1/width) == y index
"	mod r0.x, r0.z, cb0[0].x\n"			// r0.x := thread_index % width == x index
"	flr r0.xy, r0.xy\n"					// [x,y] := floor(r0.xy)
"	mad r1.x, r0.y, cb0[0].z, r0.x\n"	// index := y*pitch + x - index with account of the alignment pitch
"	ftoi r1.x, r1.x"					// convert to integer
"	sample_resource(0)_sampler(0) r2, r0.xy\n"
"	sample_resource(1)_sampler(1) r3, r0.xy\n"
"	mul r4, r2, r3\n"
"	mov g[r1.x], r4\n"
"endif\n"

"end\n";

const char kernelEwDivR_CS[] =
"il_cs_2_0\n"
"dcl_num_thread_per_blk 64\n"
"dcl_resource_id(0)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_resource_id(1)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_cb cb0[1]\n"

"ftoi r0.x, cb0[0].w"
"ilt r0.y, vaTid0.x, r0.x\n"

"if_logicalnz r0.y\n"
"	itof r0.z, vaTid0.x\n"				// r0.z := thread_index
"	mul r0.y, r0.z, cb0[0].y\n"			// r0.y := thread_index*(1/width) == y index
"	mod r0.x, r0.z, cb0[0].x\n"			// r0.x := thread_index % width == x index
"	flr r0.xy, r0.xy\n"					// [x,y] := floor(r0.xy)
"	mad r1.x, r0.y, cb0[0].z, r0.x\n"	// index := y*pitch + x - index with account of the alignment pitch
"	ftoi r1.x, r1.x"					// convert to integer
"	sample_resource(0)_sampler(0) r2, r0.xy\n"
"	sample_resource(1)_sampler(1) r3, r0.xy\n"
"	div_zeroop(zero) r4, r2, r3\n"
"	mov g[r1.x], r4\n"
"endif\n"

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
const char kernelSubR_PS[] =
"il_ps_2_0\n"
"dcl_input_position_interp(linear_noperspective) vWinCoord0.xy__\n"
"dcl_output_generic o0\n"
"dcl_resource_id(0)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_resource_id(1)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"sample_resource(0)_sampler(0) r0, vWinCoord0\n"
"sample_resource(1)_sampler(1) r1, vWinCoord0\n"
"sub o0, r0, r1\n"
"end\n";

const char kernelSubLR_PS[] =
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

// elementwise multiply
const char kernelEwMulR_PS[] =
"il_ps_2_0\n"
"dcl_input_position_interp(linear_noperspective) vWinCoord0.xy__\n"
"dcl_output_generic o0\n"
"dcl_resource_id(0)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_resource_id(1)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"sample_resource(0)_sampler(0) r0, vWinCoord0\n"
"sample_resource(1)_sampler(1) r1, vWinCoord0\n"
"mul o0, r0, r1\n"
"end\n";

const char kernelEwMulLR_PS[] =
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
const char kernelEwDivR_PS[] =
"il_ps_2_0\n"
"dcl_input_position_interp(linear_noperspective) vWinCoord0.xy__\n"
"dcl_output_generic o0\n"
"dcl_resource_id(0)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_resource_id(1)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"sample_resource(0)_sampler(0) r0, vWinCoord0\n"
"sample_resource(1)_sampler(1) r1, vWinCoord0\n"
"div_zeroop(zero) o0, r0, r1\n"
"end\n";

const char kernelEwDivLR_PS[] =
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

const char kernelMatVecR_old[] =
"il_ps_2_0\n"
"dcl_input_position_interp(linear_noperspective) vWinCoord0.xy__\n"
"dcl_cb cb0[1]\n"
"dcl_output_generic o0\n"
"dcl_literal l0, 0, 0, 0, 0\n"
"dcl_literal l1, 1, 0, 0, 0\n"
"dcl_literal l2, 1.0f, 1.0f, 4.0f, 0.0f\n"
"dcl_literal l3, 1.0f, 1.0f, 1.0f, 1.0f\n"
"dcl_resource_id(0)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_resource_id(1)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"

"mov o0, l0\n"	// zeroing the output

"mov r0, l0\n"	// index of first rhs element

// 2D position of first input row
"flr r1.xy, vWinCoord0.yx\n"
"mul r1.y, r1.y, l2.z\n"

"add r2.0y, r1.y, l2.y\n"		// 2D position of second input row
"add r3.0y, r2.y, l2.y\n"		// 2D position of third input row
"add r4.0y, r3.y, l2.y\n"		// 2D position of fourth input row

"mov r20, l0\n"
"mov r21, l0\n"
"mov r22, l0\n"
"mov r23, l0\n"

"mov r10, l0\n"	// loop counter = 0

"whileloop\n"
"    ige r10.y, r10.x, cb0[0].x\n"	// while(loop counter < cb0[0].x)
"    break_logicalnz r10.y\n"

	// load next part of rhs
"	sample_resource(1)_sampler(1) r5, r0\n"

	// load rows parts
"	sample_resource(0)_sampler(0) r6, r1\n"
"	sample_resource(0)_sampler(0) r7, r2\n"
"	sample_resource(0)_sampler(0) r8, r3\n"
"	sample_resource(0)_sampler(0) r9, r4\n"

	// do element wise multiply
"	mad r20, r5, r6, r20\n"
"	mad r21, r5, r7, r21\n"
"	mad r22, r5, r8, r22\n"
"	mad r23, r5, r9, r23\n"

"	add r0.x, r0.x, l2.x\n"
"	add r1.x, r1.x, l2.x\n"
"	add r2.x, r2.x, l2.x\n"
"	add r3.x, r3.x, l2.x\n"
"	add r4.x, r4.x, l2.x\n"

"	iadd r10.x, r10.x, l1.x\n"	// loop counter ++
"endloop\n"

// now do final horizontal add
"dp4 o0.x, r20, l3\n"	// r20 +* ones == r20.x+r20.y+r20.z+r20.w
"dp4 o0.y, r21, l3\n"
"dp4 o0.z, r22, l3\n"
"dp4 o0.w, r23, l3\n"

"end\n";

const char kernelMatVecR_CS[] =
"il_cs_2_0\n"
"dcl_num_thread_per_blk 64\n"
"dcl_resource_id(0)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_resource_id(1)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_cb cb0[1]\n"

"ftoi r0.x, cb0[0].w"
"ilt r0.y, vaTid0.x, r0.x\n"

"if_logicalnz r0.y\n"
"	itof r0.z, vaTid0.x\n"				// r0.z := thread_index

/*
"	mul r0.y, r0.z, cb0[0].y\n"			// r0.y := thread_index*(1/width) == y index
"	mod r0.x, r0.z, cb0[0].x\n"			// r0.x := thread_index % width == x index
"	flr r0.xy, r0.xy\n"					// [x,y] := floor(r0.xy)
"	mad r1.x, r0.y, cb0[0].z, r0.x\n"	// index := y*pitch + x - index with account of the alignment pitch
"	ftoi r1.x, r1.x"					// convert to integer
*/

/*
"	sample_resource(0)_sampler(0) r2, r0.xy\n"
"	sample_resource(1)_sampler(1) r3, r0.xy\n"
"	div_zeroop(zero) r4, r2, r3\n"
*/
"	mov g[r1.x], r4\n"
"endif\n"

"end\n";

const char kernelMatVecR_PS[] =
"il_ps_2_0\n"
"dcl_input_position_interp(linear_noperspective) vWinCoord0.xy__\n"
"dcl_cb cb0[1]\n"
"dcl_literal l0, 0, 0, 0, 0\n"
"dcl_literal l2, 0.0f, 0.0f, 0.0f, 4.0f\n"
"dcl_resource_id(0)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_resource_id(1)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"

"mov r0, r0.0000\n"	// r0.xy is index of the first rhs element

// r0.zw -> 2D position of first input row
"flr r0.___w, vWinCoord0.x\n"
"mul r0.w, r0.w, l2.w\n"

"mov r1.0yzw, r0.w\n"
"add r1.y, r1.y, r1.1\n"		// 2D position of second input row
"add r1.z, r1.y, r1.1\n"		// 2D position of third input row
"add r1.w, r1.z, r1.1\n"		// 2D position of fourth input row

"mov r20, r20.0000\n"
"mov r21, r21.0000\n"
"mov r22, r22.0000\n"
"mov r23, r23.0000\n"

"mov r10, r10.0000\n"	// loop counter
"itof r11, cb0[0]\n"

"whileloop\n"
"    ge r10.y, r10.x, r11.x\n"	// while(loop counter < cb0[0].x)
"    break_logicalnz r10.y\n"

	// load next part of rhs
"	sample_resource(1)_sampler(1) r5, r0.xy\n"

	// load rows parts
"	sample_resource(0)_sampler(0) r6, r0.zw\n"
"	sample_resource(0)_sampler(0) r7, r1.xy\n"
"	sample_resource(0)_sampler(0) r8, r1.xz\n"
"	sample_resource(0)_sampler(0) r9, r1.xw\n"

	// do element wise multiply	
"	mad r20, r5, r6, r20\n"
"	mad r21, r5, r7, r21\n"
"	mad r22, r5, r8, r22\n"
"	mad r23, r5, r9, r23\n"

"	add r0.xz, r0.xz, r0.11\n"
"	add r1.x, r1.x, r1.1\n"

"	add r10.x, r10.x, r10.1\n"	// loop counter ++
"endloop\n"

// now do final horizontal add
"dp4 r30.x, r20, r20.1111\n"	// r20 +* ones == r20.x+r20.y+r20.z+r20.w
"dp4 r30.y, r21, r21.1111\n"
"dp4 r30.z, r22, r22.1111\n"
"dp4 r30.w, r23, r23.1111\n"

"dcl_output_generic o0\n"
"mov o0, r30\n"

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

	CALformat* constFormats;	// data formats for each constant
	long* constSizes;			// sizes for each constant
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
