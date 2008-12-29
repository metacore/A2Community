#pragma once

enum KernelCode
{
// addition
KernAddR_PS,
KernAddLR_PS,

// subtraction
KernSubR_PS,
KernSubLR_PS,

// elementwise multiply
KernEwMulR_PS,
KernEwMulLR_PS,

// elementwise divide
KernEwDivR_PS,
KernEwDivLR_PS,

// matrix vector multiplication
KernMatVecR_PS,
KernMatVec4PartsR_PS,
KernMatVec8PartsR_PS,

// matrix multiplication
KernMatMul88Parts8x4by4x4R_PS,
KernMatMul88Parts2x8x4by2x4x4R_PS,

// split a matrix to parts
KernSplitMatrixTo4Parts_PS,
KernSplitMatrixTo8Parts_PS,

// reshape a matrix to matrix
KernReshapeMatToMatNoBounds_PS,

// reshape a ND array to matrix
KernReshapeArr1DWToMat4DW_PS,

// reshape a matrix to ND array
KernReshapeMat4DWToArr1DW_PS,

KernReshapeMat4Parts4DWToArr1DW_PS,
KernReshapeMat8Parts4DWToArr1DW_PS,

// 3D transpose
KernTranspose3D_PS,
KernTranspose4D_PS,

// matrix transposition
KernTransposeMat4DW_PS,

// zero memory
KernZeroMemory_PS,

NKernels		// total number of kernels
};

/*
	Addition
*/
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

/* 
	Subtract
*/
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

/* 
	Elementwise multiply
*/
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

/*
	Elementwise divide
*/
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

/*
	Matrix vector multiplication
*/
const char kernelMatVecR_PS[] =
"il_ps_2_0\n"
"dcl_input_position_interp(linear_noperspective) vWinCoord0.xy__\n"
"dcl_output_generic o0\n"

"dcl_cb cb0[1]\n"
"dcl_resource_id(0)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_resource_id(1)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"

"dcl_literal l0, 0.0f, 0.0f, 0.0f, 4.0f\n"

"mov r0, r0.0000\n"	// r0.xy is index of the first rhs element

// r0.zw -> 2D position of first input row
"flr r0.___w, vWinCoord0.x\n"
"mul r0.w, r0.w, l0.w\n"

"mov r1.0yzw, r0.w\n"			
"add r1.y, r1.y, r1.1\n"		// 2D position of second input row
"add r1.z, r1.y, r1.1\n"		// 2D position of third input row
"add r1.w, r1.z, r1.1\n"		// 2D position of fourth input row

"sub r0.xz, r0.xz, r0.11\n"		// account first increment
"sub r1.x, r1.x, r1.1\n"		// account first increment

"mov r20, r20.0000\n"
"mov r21, r21.0000\n"
"mov r22, r22.0000\n"
"mov r23, r23.0000\n"

"mov r10, r10.0000\n"			// loop counter
"sub r10.x, r10.x, r10.1\n"		// account first increment

"mov r11, cb0[0]\n"

"whileloop\n"

	// increment counters of row elements
"	add r0.xz, r0.xz, r0.11\n"
"	add r1.x, r1.x, r1.1\n"

"	add r10.x, r10.x, r10.1\n"	// loop counter ++
"   ge r10.y, r10.x, r11.x\n"	// while(loop counter < cb0[0].x)
"   break_logicalnz r10.y\n"

	// load next part of rhs
"	sample_resource(1)_sampler(1) r5, r0.xy\n"

	// load netx parts of rows
"	sample_resource(0)_sampler(0) r6, r0.zw\n"
"	sample_resource(0)_sampler(0) r7, r1.xy\n"
"	sample_resource(0)_sampler(0) r8, r1.xz\n"
"	sample_resource(0)_sampler(0) r9, r1.xw\n"

	// do elementwise multiply and accumulate	
"	mad r20, r5, r6, r20\n"
"	mad r21, r5, r7, r21\n"
"	mad r22, r5, r8, r22\n"
"	mad r23, r5, r9, r23\n"
"endloop\n"

// now do final horizontal add
"dp4 r30.x, r20, r20.1111\n"	// r +* ones == r.x+r.y+r.z+r.w
"dp4 r30.y, r21, r21.1111\n"
"dp4 r30.z, r22, r22.1111\n"
"dp4 r30.w, r23, r23.1111\n"

"mov o0, r30\n"

"end\n";

/*
	Matrix vector multiplication for the case when matrix is splitted into 8 parts
*/
const char kernelMatVec8PartsR_PS[] =
"il_ps_2_0\n"
"dcl_input_position_interp(linear_noperspective) vWinCoord0.xy__\n"
"dcl_output_generic o0\n"

"dcl_cb cb0[1]\n"

"dcl_resource_id(0)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_resource_id(1)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_resource_id(2)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_resource_id(3)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_resource_id(4)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_resource_id(5)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_resource_id(6)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_resource_id(7)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"

"dcl_resource_id(8)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"

"dcl_literal l0, 0.0f, 0.5f, 0.0f, 0.0f\n"

"mov r0, r0.0000\n"	// r0.xy is [x,y] of the first rhs element

"flr r2.y, vWinCoord0.x\n"
"mul r2.y, r2.y, l0.y\n"
"flr r1.0y, r2.y\n"			// r1.xy -> [x,y] of first element in input row
"sub r2.y, r2.y, r1.y\n"	// remainder of division by 2

"sub r0.x, r0.x, r0.1\n"		// account first increment
"sub r1.x, r1.x, r1.1\n"		// account first increment

"mov r20, r20.0000\n"
"mov r21, r21.0000\n"
"mov r22, r22.0000\n"
"mov r23, r23.0000\n"

"mov r10, r10.0000\n"			// loop counter
"sub r10.x, r10.x, r10.1\n"		// account first increment

"mov r11, cb0[0]\n"

"eq r2.z, r2.y, r2.0\n"
"if_logicalnz r2.z\n"	// if r2.y == 0

"	whileloop\n"

		// increment counters of row elements
"		add r0.x, r0.x, r0.1\n"
"		add r1.x, r1.x, r1.1\n"

"		add r10.x, r10.x, r10.1\n"	// loop counter ++
"		ge r10.y, r10.x, r11.x\n"	// while(loop counter < cb0[0].x)
"		break_logicalnz r10.y\n"

		// load next part of rhs
"		sample_resource(8)_sampler(8) r5, r0.xy\n"

		// load next parts from 4 rows
"		sample_resource(0)_sampler(0) r6, r1.xy\n"
"		sample_resource(1)_sampler(1) r7, r1.xy\n"
"		sample_resource(2)_sampler(2) r8, r1.xy\n"
"		sample_resource(3)_sampler(3) r9, r1.xy\n"

		// do elementwise multiply	
"		mad r20, r5, r6, r20\n"
"		mad r21, r5, r7, r21\n"
"		mad r22, r5, r8, r22\n"
"		mad r23, r5, r9, r23\n"
"	endloop\n"

"else\n"

"	whileloop\n"

		// increment counters of row elements
"		add r0.x, r0.x, r0.1\n"
"		add r1.x, r1.x, r1.1\n"

"		add r10.x, r10.x, r10.1\n"	// loop counter ++
"		ge r10.y, r10.x, r11.x\n"	// while(loop counter < cb0[0].x)
"		break_logicalnz r10.y\n"

		// load next part of rhs
"		sample_resource(8)_sampler(8) r5, r0.xy\n"

		// load next parts from 4 rows
"		sample_resource(4)_sampler(4) r6, r1.xy\n"
"		sample_resource(5)_sampler(5) r7, r1.xy\n"
"		sample_resource(6)_sampler(6) r8, r1.xy\n"
"		sample_resource(7)_sampler(7) r9, r1.xy\n"

		// do elementwise multiply	
"		mad r20, r5, r6, r20\n"
"		mad r21, r5, r7, r21\n"
"		mad r22, r5, r8, r22\n"
"		mad r23, r5, r9, r23\n"
"	endloop\n"

"endif\n"

// now do final horizontal add
"dp4 r30.x, r20, r20.1111\n"	// r +* ones == r.x+r.y+r.z+r.w
"dp4 r30.y, r21, r21.1111\n"
"dp4 r30.z, r22, r22.1111\n"
"dp4 r30.w, r23, r23.1111\n"

"mov o0, r30\n"

"end\n";

/*
	Matrix vector multiplication for the case when matrix is splitted into 4 parts
*/
const char kernelMatVec4PartsR_PS[] =
"il_ps_2_0\n"
"dcl_input_position_interp(linear_noperspective) vWinCoord0.xy__\n"
"dcl_output_generic o0\n"

"dcl_cb cb0[1]\n"

"dcl_resource_id(0)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_resource_id(1)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_resource_id(2)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_resource_id(3)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"

"dcl_resource_id(4)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"

"dcl_literal l0, 0.0f, 0.5f, 0.0f, 0.0f\n"

"mov r0, r0.0000\n"	// r0.xy is [x,y] of the first rhs element
"mov r1.0y, vWinCoord0.x\n"	// r1.xy -> [x,y] of first element in input row

"sub r0.x, r0.x, r0.1\n"		// account first increment
"sub r1.x, r1.x, r1.1\n"		// account first increment

"mov r20, r20.0000\n"
"mov r21, r21.0000\n"
"mov r22, r22.0000\n"
"mov r23, r23.0000\n"

"mov r10, r10.0000\n"			// loop counter
"sub r10.x, r10.x, r10.1\n"		// account first increment

"mov r11, cb0[0]\n"


"whileloop\n"

	// increment counters of row elements
"	add r0.x, r0.x, r0.1\n"
"	add r1.x, r1.x, r1.1\n"

"	add r10.x, r10.x, r10.1\n"	// loop counter ++
"	ge r10.y, r10.x, r11.x\n"	// while(loop counter < cb0[0].x)
"	break_logicalnz r10.y\n"

	// load next part of rhs
"	sample_resource(4)_sampler(4) r5, r0.xy\n"

	// load next parts from 4 rows
"	sample_resource(0)_sampler(0) r6, r1.xy\n"
"	sample_resource(1)_sampler(1) r7, r1.xy\n"
"	sample_resource(2)_sampler(2) r8, r1.xy\n"
"	sample_resource(3)_sampler(3) r9, r1.xy\n"

	// do elementwise multiply	
"	mad r20, r5, r6, r20\n"
"	mad r21, r5, r7, r21\n"
"	mad r22, r5, r8, r22\n"
"	mad r23, r5, r9, r23\n"
"endloop\n"

// now do final horizontal add
"dp4 r30.x, r20, r20.1111\n"	// r +* ones == r.x+r.y+r.z+r.w
"dp4 r30.y, r21, r21.1111\n"
"dp4 r30.z, r22, r22.1111\n"
"dp4 r30.w, r23, r23.1111\n"

"mov o0, r30\n"

"end\n";

/*
	Matrix multiplication for the case when both A and B are splitted in 8 parts

	performs series of 8x4 by 4x4 matrix multiplications without loop unrolling
*/
const char kernelMatMul88Parts8x4by4x4R_PS[] = 
"il_ps_2_0\n"
"dcl_input_position_interp(linear_noperspective) vWinCoord0.xy__\n"
"dcl_cb cb0[1]\n"	// [A.width,...]

"dcl_output_generic o0\n"
"dcl_output_generic o1\n"
"dcl_output_generic o2\n"
"dcl_output_generic o3\n"
"dcl_output_generic o4\n"
"dcl_output_generic o5\n"
"dcl_output_generic o6\n"
"dcl_output_generic o7\n"

// parts of A
"dcl_resource_id(0)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_resource_id(1)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_resource_id(2)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_resource_id(3)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_resource_id(4)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_resource_id(5)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_resource_id(6)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_resource_id(7)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"

// parts of B
"dcl_resource_id(8)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_resource_id(9)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_resource_id(10)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_resource_id(11)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_resource_id(12)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_resource_id(13)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_resource_id(14)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_resource_id(15)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"

"dcl_literal l0, 2.0f, 0.5f, 0.0f, 0.0f\n"

// initialize sample counters of A
"mov r0.0y, vWinCoord0.y\n"				// r0 := [0,y]
"sub r0.x, r0.x, r0.1\n"				// account first increment

// initialize sample counter of B
"mov r1.x0, vWinCoord0.x\n"				// [x,0]
"sub r1.y, r1.y, l0.y\n"				// account first increment

// clear float4 accumulators for 8x4 * 4x4 matrix multiply result
"mov r34, r34.0000\n"	
"mov r35, r35.0000\n"
"mov r36, r36.0000\n"
"mov r37, r37.0000\n"
"mov r38, r38.0000\n"	
"mov r39, r39.0000\n"
"mov r40, r40.0000\n"
"mov r41, r41.0000\n"

"mov r2.0y00, cb0[0].x\n"				// r2.x is the loop counter, r2.y := A.width
"sub r2.x, r2.x, r2.1\n"				// account first increment

"whileloop\n"

	// increment sample counter of B
"	add r1.y, r1.y, l0.y\n"

	// increment sample counter of A
"	add r0.x, r0.x, r0.1\n"

"	add r2.x, r2.x, r2.1\n"	// loop counter ++

"   ge r2.z, r2.x, r2.y\n"	// while(loop counter < A.width)
"   break_logicalnz r2.z\n"

	// load next 4x4 block of B

"	mod r3.x, r2.x, l0.x\n"	// r3.x := r2.x % 2

"	eq r3.y, r3.x, r3.0\n"
"	if_logicalnz r3.y\n"	// if r3.x == 0
"		sample_resource(8)_sampler(8) r10, r1.xy00\n"
"		sample_resource(9)_sampler(9) r11, r1.xy00\n"
"		sample_resource(10)_sampler(10) r12, r1.xy00\n"
"		sample_resource(11)_sampler(11) r13, r1.xy00\n"
"	else\n"
"		sample_resource(12)_sampler(12) r10, r1.xy00\n"
"		sample_resource(13)_sampler(13) r11, r1.xy00\n"
"		sample_resource(14)_sampler(14) r12, r1.xy00\n"
"		sample_resource(15)_sampler(15) r13, r1.xy00\n"
"	endif\n"

	// load next 8x4 block of A
"	sample_resource(0)_sampler(0) r26, r0.xy00\n"
"	sample_resource(1)_sampler(1) r27, r0.xy00\n"
"	sample_resource(2)_sampler(2) r28, r0.xy00\n"
"	sample_resource(3)_sampler(3) r29, r0.xy00\n"
"	sample_resource(4)_sampler(4) r30, r0.xy00\n"
"	sample_resource(5)_sampler(5) r31, r0.xy00\n"
"	sample_resource(6)_sampler(6) r32, r0.xy00\n"
"	sample_resource(7)_sampler(7) r33, r0.xy00\n"

	// compute Ablk * Bblk

	// row 1
"	mad r42, r26.x, r10, r34\n"	// r42 := Ablk[0,0]*Bblk0[0,*] + Cblk[0,*]
"	mad r42, r26.y, r11, r42\n"	// r42 := Ablk[0,1]*Bblk0[1,*] + r42
"	mad r42, r26.z, r12, r42\n"	// r42 := Ablk[0,2]*Bblk0[2,*] + r42
"	mad r34, r26.w, r13, r42\n"	// Cblk[0,*] := Ablk[0,3]*Bblk0[3,*] + r42
	// row 2
"	mad r42, r27.x, r10, r35\n"
"	mad r42, r27.y, r11, r42\n"
"	mad r42, r27.z, r12, r42\n"
"	mad r35, r27.w, r13, r42\n"
	// row 3
"	mad r42, r28.x, r10, r36\n"
"	mad r42, r28.y, r11, r42\n"
"	mad r42, r28.z, r12, r42\n"
"	mad r36, r28.w, r13, r42\n"
	// row 4
"	mad r42, r29.x, r10, r37\n"
"	mad r42, r29.y, r11, r42\n"
"	mad r42, r29.z, r12, r42\n"
"	mad r37, r29.w, r13, r42\n"
	// row 5
"	mad r42, r30.x, r10, r38\n"
"	mad r42, r30.y, r11, r42\n"
"	mad r42, r30.z, r12, r42\n"
"	mad r38, r30.w, r13, r42\n"
	// row 6
"	mad r42, r31.x, r10, r39\n"
"	mad r42, r31.y, r11, r42\n"
"	mad r42, r31.z, r12, r42\n"
"	mad r39, r31.w, r13, r42\n"
	// row 7
"	mad r42, r32.x, r10, r40\n"
"	mad r42, r32.y, r11, r42\n"
"	mad r42, r32.z, r12, r42\n"
"	mad r40, r32.w, r13, r42\n"
	// row 8
"	mad r42, r33.x, r10, r41\n"
"	mad r42, r33.y, r11, r42\n"
"	mad r42, r33.z, r12, r42\n"
"	mad r41, r33.w, r13, r42\n"

"endloop\n"

// store the result
"mov o0, r34\n"
"mov o1, r35\n"
"mov o2, r36\n"
"mov o3, r37\n"
"mov o4, r38\n"
"mov o5, r39\n"
"mov o6, r40\n"
"mov o7, r41\n"

"end\n";

/*
	Matrix multiplication for the case when both A and B are splitted in 8 parts

	performs series of 8x4 by 4x4 matrix multiplications with loop unrolling by 2
*/
const char kernelMatMul88Parts2x8x4by2x4x4R_PS[] = 
"il_ps_2_0\n"
"dcl_input_position_interp(linear_noperspective) vWinCoord0.xy__\n"
"dcl_cb cb0[1]\n"	// [A.width,...]

"dcl_output_generic o0\n"
"dcl_output_generic o1\n"
"dcl_output_generic o2\n"
"dcl_output_generic o3\n"
"dcl_output_generic o4\n"
"dcl_output_generic o5\n"
"dcl_output_generic o6\n"
"dcl_output_generic o7\n"

"dcl_resource_id(0)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_resource_id(1)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_resource_id(2)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_resource_id(3)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_resource_id(4)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_resource_id(5)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_resource_id(6)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_resource_id(7)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"

"dcl_resource_id(8)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_resource_id(9)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_resource_id(10)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_resource_id(11)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"

"dcl_resource_id(12)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_resource_id(13)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_resource_id(14)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_resource_id(15)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"

"dcl_literal l0, 2.0f, 0.0f, 0.0f, 0.0f\n"

// initialize sample counters of A
"mov r0.01z0, vWinCoord0.00y0\n"			// r0 := [0,1,y,0]
"sub r0.xy, r0.xy, l0.xx\n"					// account first increment

// initialize sample counter of B
"mov r1.x0, vWinCoord0.x\n"					// [x,0,1,...]
"sub r1.y, r1.y, r1.1\n"					// account first increment

// clear float4 accumulators for 8x4 * 4x4 matrix multiply result
"mov r34, r34.0000\n"	
"mov r35, r35.0000\n"
"mov r36, r36.0000\n"
"mov r37, r37.0000\n"
"mov r38, r38.0000\n"	
"mov r39, r39.0000\n"
"mov r40, r40.0000\n"
"mov r41, r41.0000\n"

"mov r2.0y00, cb0[0].x\n"	// r2.x is the loop counter, r2.y := A.width
"sub r2.x, r2.x, l0.x\n"	// account first increment

"whileloop\n"

	// increment sample counter of B
"	add r1.y, r1.y, r1.1\n"

	// increment sample counters of A
"	add r0.xy, r0.xy, l0.xx\n"

"	add r2.x, r2.x, l0.x\n"	// loop counter ++

"   ge r2.z, r2.x, r2.y\n"	// while(loop counter < A.width)
"   break_logicalnz r2.z\n"

	// load 4 next 4x4 blocks of B
"	sample_resource(8)_sampler(8) r10, r1.xy00\n"
"	sample_resource(9)_sampler(9) r11, r1.xy00\n"
"	sample_resource(10)_sampler(10) r12, r1.xy00\n"
"	sample_resource(11)_sampler(11) r13, r1.xy00\n"

"	sample_resource(12)_sampler(12) r14, r1.xy00\n"
"	sample_resource(13)_sampler(13) r15, r1.xy00\n"
"	sample_resource(14)_sampler(14) r16, r1.xy00\n"
"	sample_resource(15)_sampler(15) r17, r1.xy00\n"

	// load next 8x4 block of A
"	sample_resource(0)_sampler(0) r26, r0.xz00\n"
"	sample_resource(1)_sampler(1) r27, r0.xz00\n"
"	sample_resource(2)_sampler(2) r28, r0.xz00\n"
"	sample_resource(3)_sampler(3) r29, r0.xz00\n"
"	sample_resource(4)_sampler(4) r30, r0.xz00\n"
"	sample_resource(5)_sampler(5) r31, r0.xz00\n"
"	sample_resource(6)_sampler(6) r32, r0.xz00\n"
"	sample_resource(7)_sampler(7) r33, r0.xz00\n"

	// compute Ablk * Bblk0

	// row 1
"	mad r42, r26.x, r10, r34\n"	// r42 := Ablk[0,0]*Bblk0[0,*] + Cblk[0,*]
"	mad r42, r26.y, r11, r42\n"	// r42 := Ablk[0,1]*Bblk0[1,*] + r42
"	mad r42, r26.z, r12, r42\n"	// r42 := Ablk[0,2]*Bblk0[2,*] + r42
"	mad r34, r26.w, r13, r42\n"	// Cblk[0,*] := Ablk[0,3]*Bblk0[3,*] + r42
	// row 2
"	mad r42, r27.x, r10, r35\n"
"	mad r42, r27.y, r11, r42\n"
"	mad r42, r27.z, r12, r42\n"
"	mad r35, r27.w, r13, r42\n"
	// row 3
"	mad r42, r28.x, r10, r36\n"
"	mad r42, r28.y, r11, r42\n"
"	mad r42, r28.z, r12, r42\n"
"	mad r36, r28.w, r13, r42\n"
	// row 4
"	mad r42, r29.x, r10, r37\n"
"	mad r42, r29.y, r11, r42\n"
"	mad r42, r29.z, r12, r42\n"
"	mad r37, r29.w, r13, r42\n"
	// row 5
"	mad r42, r30.x, r10, r38\n"
"	mad r42, r30.y, r11, r42\n"
"	mad r42, r30.z, r12, r42\n"
"	mad r38, r30.w, r13, r42\n"
	// row 6
"	mad r42, r31.x, r10, r39\n"
"	mad r42, r31.y, r11, r42\n"
"	mad r42, r31.z, r12, r42\n"
"	mad r39, r31.w, r13, r42\n"
	// row 7
"	mad r42, r32.x, r10, r40\n"
"	mad r42, r32.y, r11, r42\n"
"	mad r42, r32.z, r12, r42\n"
"	mad r40, r32.w, r13, r42\n"
	// row 8
"	mad r42, r33.x, r10, r41\n"
"	mad r42, r33.y, r11, r42\n"
"	mad r42, r33.z, r12, r42\n"
"	mad r41, r33.w, r13, r42\n"

	// load next 8x4 block of A
"	sample_resource(0)_sampler(0) r26, r0.yz00\n"
"	sample_resource(1)_sampler(1) r27, r0.yz00\n"
"	sample_resource(2)_sampler(2) r28, r0.yz00\n"
"	sample_resource(3)_sampler(3) r29, r0.yz00\n"
"	sample_resource(4)_sampler(4) r30, r0.yz00\n"
"	sample_resource(5)_sampler(5) r31, r0.yz00\n"
"	sample_resource(6)_sampler(6) r32, r0.yz00\n"
"	sample_resource(7)_sampler(7) r33, r0.yz00\n"

	// compute Ablk * Bblk1

	// row 1
"	mad r42, r26.x, r14, r34\n"	// r42 := Ablk[0,0]*Bblk1[0,*] + Cblk[0,*]
"	mad r42, r26.y, r15, r42\n"	// r42 := Ablk[0,1]*Bblk1[1,*] + r42
"	mad r42, r26.z, r16, r42\n"	// r42 := Ablk[0,2]*Bblk1[2,*] + r42
"	mad r34, r26.w, r17, r42\n"	// Cblk[0,*] := Ablk[0,3]*Bblk1[3,*] + r42
	// row 2
"	mad r42, r27.x, r14, r35\n"
"	mad r42, r27.y, r15, r42\n"
"	mad r42, r27.z, r16, r42\n"
"	mad r35, r27.w, r17, r42\n"
	// row 3
"	mad r42, r28.x, r14, r36\n"
"	mad r42, r28.y, r15, r42\n"
"	mad r42, r28.z, r16, r42\n"
"	mad r36, r28.w, r17, r42\n"
	// row 4
"	mad r42, r29.x, r14, r37\n"
"	mad r42, r29.y, r15, r42\n"
"	mad r42, r29.z, r16, r42\n"
"	mad r37, r29.w, r17, r42\n"
	// row 5
"	mad r42, r30.x, r14, r38\n"
"	mad r42, r30.y, r15, r42\n"
"	mad r42, r30.z, r16, r42\n"
"	mad r38, r30.w, r17, r42\n"
	// row 6
"	mad r42, r31.x, r14, r39\n"
"	mad r42, r31.y, r15, r42\n"
"	mad r42, r31.z, r16, r42\n"
"	mad r39, r31.w, r17, r42\n"
	// row 7
"	mad r42, r32.x, r14, r40\n"
"	mad r42, r32.y, r15, r42\n"
"	mad r42, r32.z, r16, r42\n"
"	mad r40, r32.w, r17, r42\n"
	// row 8
"	mad r42, r33.x, r14, r41\n"
"	mad r42, r33.y, r15, r42\n"
"	mad r42, r33.z, r16, r42\n"
"	mad r41, r33.w, r17, r42\n"

"endloop\n"

// store the result
"mov o0, r34\n"
"mov o1, r35\n"
"mov o2, r36\n"
"mov o3, r37\n"
"mov o4, r38\n"
"mov o5, r39\n"
"mov o6, r40\n"
"mov o7, r41\n"
"end\n";

/*
	C := reshape(A,width,height);
	Reshape A with (A.width % physNumComponents == 0) to C with (C.width % physNumComponents == 0)

	Easiest case without handling of boundaries

	NOTE: vObjectIndex0.x gives strange indexing!!! That is why it is not used in this implementation.
*/
const char kernelReshapeMatToMatNoBounds_PS[] =
"il_ps_2_0\n"
"dcl_cb cb0[1]\n"	// int32[A.width,C.width]
"dcl_output_generic o0\n"
"dcl_input_position_interp(linear_noperspective) vWinCoord0.xy__\n"
"dcl_resource_id(0)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"

"ftoi r0.xy, vWinCoord0.xy\n"
"umad r0.x, r0.y, cb0[0].y, r0.x\n"

// compute 2D index in the input matrix
"udiv r1.y, r0.x, cb0[0].x\n"	// y := index/A.width
"umod r1.x, r0.x, cb0[0].x\n"	// x := index % A.width

"itof r1, r1\n"
"sample_resource(0)_sampler(0) o0, r1.xy\n"

"end\n";

/*
	Reshape a virtualized array with 1-double word elements to a matrix with 4-double word elements

	C := A.Reshape(width,height);

	NOTE: vObjectIndex0.x gives strange indexing!!! That is why it is not used in this implementation.
*/
const char kernelReshapeArr1DWToMat4DW_PS[] =
"il_ps_2_0\n"
"dcl_cb cb0[1]\n"	// [A.physWidth,C.physWidth,C.width]
"dcl_output_generic o0\n"
"dcl_input_position_interp(linear_noperspective) vWinCoord0.xy__\n"
"dcl_resource_id(0)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"

"dcl_literal l0, 4, 1, 2, 3\n"
"dcl_literal l1, -1, 0, 0, 0\n"

// compute linear index in the input
"ftoi r5, vWinCoord0\n"
"umul r0.x, r5.x, l0.x\n"
"umad r0.x, r5.y, cb0[0].z, r0.x\n"

// compute 2D position for 4 input elements
"iadd r0.xyzw, r0.xxxx, l0.0yzw\n" // [index,index+1,index+2,index+3]

// x coordinates
"umod r1, r0, cb0[0].xxxx\n"		// [index,index+1,index+2,index+3] % A.physWidth
// y coordinates
"udiv r2, r0, cb0[0].xxxx\n"		// [index,index+1,index+2,index+3]/A.physWidth

"itof r1, r1\n"
"itof r2, r2\n"

"mov r3.xz, r1.xy\n"
"mov r3.yw, r2.xy\n"
"mov r4.xz, r1.zw\n"
"mov r4.yw, r2.zw\n"

"sample_resource(0)_sampler(0) r2.x, r3.xy\n"
"sample_resource(0)_sampler(0) r2.y, r3.zw\n"
"sample_resource(0)_sampler(0) r2.z, r4.xy\n"
"sample_resource(0)_sampler(0) r2.w, r4.zw\n"

"iadd r1.y, cb0[0].y, l1.x\n"	// r1.y := C.physWidth-1
"ine r1.x, r5.x, r1.y\n"
"if_logicalnz r1.x\n"	// if x != C.physWidth-1
"	mov o0, r2\n"
"else\n"
	
	// r1.x := C.physWidth*4 - C.width
"	umul r1.x, cb0[0].y, l0.x\n"
"	umul r1.y, cb0[0].z, l1.x\n"
"	iadd r1.x, r1.x, r1.y\n"

"	switch r1.x\n"

"		default\n"
"			mov o0, r2\n"
"		break\n"

"		case 1\n"
"			mov o0, r2.xyz0\n"
"		break\n"

"		case 2\n"
"			mov o0, r2.xy00\n"
"		break\n"

"		case 3\n"
"			mov o0, r2.x000\n"
"		break\n"

"	endswitch\n"

"endif\n"

"end\n";

/*
	Reshape  a matrix with 4-double word elements to virtualized array with 1-double word elements

	C := A.Reshape(size);

	NOTE: vObjectIndex0.x gives strange indexing!!! That is why it is not used in this implementation.
*/
const char kernelReshapeMat4DWToArr1DW_PS[] =
"il_ps_2_0\n"
"dcl_cb cb0[1]\n"	// int32[C.physWidth,A.Width]
"dcl_output_generic o0\n"
"dcl_input_position_interp(linear_noperspective) vWinCoord0.xy__\n"
"dcl_resource_id(0)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"

"dcl_literal l0, 4, 0, 0, 0\n"

// compute linear index in the output
"ftoi r5, vWinCoord0\n"
"umad r0.x, r5.y, cb0[0].x, r5.x\n"

// compute 2D position in the input
"umod r2.x, r0.x, cb0[0].y\n"	// x coordinate
"udiv r2.y, r0.x, cb0[0].y\n"	// y coordinate

"umod r1.x, r2.x, l0.x\n"		// remainder from division by 4

"udiv r2.x, r2.x, l0.x\n"		// division by 4 to get x coordinate in quads
"itof r2, r2\n"

"switch r1.x\n"

"	default\n"
"	sample_resource(0)_sampler(0) r3.x___, r2.xy\n"
"	mov o0.x, r3.x\n"
"	break\n"

"	case 1\n"
"	sample_resource(0)_sampler(0) r3._y__, r2.xy\n"
"	mov o0.x, r3.y\n"
"	break\n"

"	case 2\n"
"	sample_resource(0)_sampler(0) r3.__z_, r2.xy\n"
"	mov o0.x, r3.z\n"
"	break\n"

"	case 3\n"
"	sample_resource(0)_sampler(0) r3.___w, r2.xy\n"
"	mov o0.x, r3.w\n"
"	break\n"

"endswitch\n"

"end\n";

/*
	Transpose a 3D array with single component elements
*/
const char kernelTranspose3D_PS[] = 
"il_ps_2_0\n"
"dcl_cb cb0[3]\n"	// int32[physWidth, C.Ny*C.Nx, C.Nx, 1], int32[tZ, tY, tX, 0], int32[A.Ny*A.Nx, A.Nx, 1, 0]
"dcl_output_generic o0\n"
"dcl_input_position_interp(linear_noperspective) vWinCoord0.xy__\n"
"dcl_resource_id(0)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"

// compute linear index in the output
"ftoi r5, vWinCoord0\n"
"umad r0.x, r5.y, cb0[0].x, r5.x\n"

// compute z, y, x coordinates in the output
"udiv r1.x, r0.x, cb0[0].y\n"	// z := ind/(C.Ny*C.Nx)
"umod r1.z, r0.x, cb0[0].y\n"	// r1.z := ind - z*C.Ny*C.Nx
"udiv r1.y, r1.z, cb0[0].z\n"	// y := (ind - z*C.Ny*C.Nx)/C.Nx
"umod r1.z, r1.z, cb0[0].z\n"	// x := ind - z*C.Ny*C.Nx - y*C.Nx

// shuffle the coordinates

"switch cb0[1].x\n"

"	default\n"
"	mov r2.x, r1.x\n"
"	break\n"

"	case 1\n"
"	mov r2.y, r1.x\n"
"	break\n"

"	case 2\n"
"	mov r2.z, r1.x\n"
"	break\n"

"endswitch\n"

"switch cb0[1].y\n"

"	default\n"
"	mov r2.x, r1.y\n"
"	break\n"

"	case 1\n"
"	mov r2.y, r1.y\n"
"	break\n"

"	case 2\n"
"	mov r2.z, r1.y\n"
"	break\n"

"endswitch\n"

"switch cb0[1].z\n"

"	default\n"
"	mov r2.x, r1.z\n"
"	break\n"

"	case 1\n"
"	mov r2.y, r1.z\n"
"	break\n"

"	case 2\n"
"	mov r2.z, r1.z\n"
"	break\n"

"endswitch\n"

// compute linear index in the input
"imul r2.xyz, r2.xyz, cb0[2].xyz\n"	// [z*A.Ny*A.Nx, y*A.Nx, x*1]

// horizontal add
"iadd r2.x, r2.x, r2.y\n"
"iadd r2.x, r2.x, r2.z\n"

// compute corresponding 2D index in the input
"umod r3.x, r2.x, cb0[0].x\n"	// x := index % physWidth
"udiv r3.y, r2.x, cb0[0].x\n"	// y := index / physWidth
"itof r3, r3\n"

"sample_resource(0)_sampler(0) o0, r3.xy\n"

"end\n";

/*
	Transpose a 4D array  with single component elements
*/
const char kernelTranspose4D_PS[] = 
"il_ps_2_0\n"
"dcl_cb cb0[3]\n"	// int32[physWidth, C.Nz*C.Ny*C.Nx, C.Ny*C.Nx, C.Nx], int32[tT, tZ, tY, tX], int32[A.Nz*A.Ny*A.Nx, A.Ny*A.Nx, A.Nx, 1]
"dcl_output_generic o0\n"
"dcl_input_position_interp(linear_noperspective) vWinCoord0.xy__\n"
"dcl_resource_id(0)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"

// compute linear index in the output
"ftoi r5, vWinCoord0\n"
"umad r0.x, r5.y, cb0[0].x, r5.x\n"

// compute t, z, y, x coordinates in the output
"udiv r1.x, r0.x, cb0[0].y\n"	// t := ind/(C.Nz*C.Ny*C.Nx)
"umod r1.w, r0.x, cb0[0].y\n"	// r1.w := ind - t*C.Nz*C.Ny*C.Nx
"udiv r1.y, r1.w, cb0[0].z\n"	// z := (ind - t*C.Nz*C.Ny*C.Nx)/(C.Ny*C.Nx)
"umod r1.w, r1.w, cb0[0].z\n"	// r1.w := ind - t*C.Nz*C.Ny*C.Nx - z*(C.Ny*C.Nx)
"udiv r1.z, r1.w, cb0[0].w\n"	// y := (ind - t*C.Nz*C.Ny*C.Nx - z*(C.Ny*C.Nx))/C.Nx
"umod r1.w, r1.w, cb0[0].w\n"	// x := (ind - t*C.Nz*C.Ny*C.Nx - z*(C.Ny*C.Nx)) % C.Nx

// shuffle the coordinates

"switch cb0[1].x\n"

"	default\n"
"	mov r2.x, r1.x\n"
"	break\n"

"	case 1\n"
"	mov r2.y, r1.x\n"
"	break\n"

"	case 2\n"
"	mov r2.z, r1.x\n"
"	break\n"

"endswitch\n"

"switch cb0[1].y\n"

"	default\n"
"	mov r2.x, r1.y\n"
"	break\n"

"	case 1\n"
"	mov r2.y, r1.y\n"
"	break\n"

"	case 2\n"
"	mov r2.z, r1.y\n"
"	break\n"

"	case 3\n"
"	mov r2.w, r1.y\n"
"	break\n"

"endswitch\n"

"switch cb0[1].z\n"

"	default\n"
"	mov r2.x, r1.z\n"
"	break\n"

"	case 1\n"
"	mov r2.y, r1.z\n"
"	break\n"

"	case 2\n"
"	mov r2.z, r1.z\n"
"	break\n"

"	case 3\n"
"	mov r2.w, r1.z\n"
"	break\n"

"endswitch\n"

"switch cb0[1].w\n"

"	default\n"
"	mov r2.x, r1.w\n"
"	break\n"

"	case 1\n"
"	mov r2.y, r1.w\n"
"	break\n"

"	case 2\n"
"	mov r2.z, r1.w\n"
"	break\n"

"	case 3\n"
"	mov r2.w, r1.w\n"
"	break\n"

"endswitch\n"

// compute linear index in the input
"imul r2.xyzw, r2.xyzw, cb0[2].xyzw\n"	// [t*A.Nz*A.Ny*A.Nx, z*A.Ny*A.Nx, y*A.Nx, x*1]

// horizontal add
"iadd r2.x, r2.x, r2.y\n"
"iadd r2.x, r2.x, r2.z\n"
"iadd r2.x, r2.x, r2.w\n"

// compute corresponding 2D index in the input
"umod r3.x, r2.x, cb0[0].x\n"	// x := index % physWidth
"udiv r3.y, r2.x, cb0[0].x\n"	// y := index / physWidth
"itof r3, r3\n"

"sample_resource(0)_sampler(0) o0, r3.xy\n"

"end\n";

/*
	Reshape a matrix (4 double word elements) splitted to 4 parts to 1 double word ND array
*/
const char kernelReshapeMat4Parts4DWToArr1DW_PS[] = 
"il_ps_2_0\n"
"dcl_cb cb0[1]\n"	// int32[C.physWidth,A.Width]
"dcl_output_generic o0\n"
"dcl_input_position_interp(linear_noperspective) vWinCoord0.xy__\n"

"dcl_resource_id(0)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_resource_id(1)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_resource_id(2)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_resource_id(3)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"

"dcl_literal l0, 4, 4, 0, 0\n"

/*
// compute linear index in the output
"ftoi r5, vWinCoord0\n"
"umad r0.x, r5.y, cb0[0].x, r5.x\n"

// compute corresponding 2D index in the input
"umod r3.x, r0.x, cb0[0].y\n"	// x := index % A.Width
"udiv r3.y, r0.x, cb0[0].y\n"	// y := index / A.Width

// compute which input from available 4 to use
"umod r4.y, r3.y, l0.y\n"	// r4.y := y % 4
// compute which sample to take
"umod r4.z, r3.x, l0.x\n"	// r4.z := x % 4

"switch r4.y\n"

"	default\n"
"		switch r4.z\n"
"			default\n"
"				sample_resource(0)_sampler(0) r1.x___, r3.xy\n"
"				mov o0, r1.x\n"
"			break\n"

"			case 1\n"
"				sample_resource(0)_sampler(0) r1._y__, r3.xy\n"
"				mov o0, r1.y\n"
"			break\n"

"			case 2\n"
"				sample_resource(0)_sampler(0) r1.__z_, r3.xy\n"
"				mov o0, r1.z\n"
"			break\n"

"			case 3\n"
"				sample_resource(0)_sampler(0) r1.___w, r3.xy\n"
"				mov o0, r1.w\n"
"			break\n"
"		endswitch\n"

"	break\n"

"	case 1\n"
"		switch r4.z\n"
"			default\n"
"				sample_resource(1)_sampler(1) r1.x___, r3.xy\n"
"				mov o0, r1.x\n"
"			break\n"

"			case 1\n"
"				sample_resource(1)_sampler(1) r1._y__, r3.xy\n"
"				mov o0, r1.y\n"
"			break\n"

"			case 2\n"
"				sample_resource(1)_sampler(1) r1.__z_, r3.xy\n"
"				mov o0, r1.z\n"
"			break\n"

"			case 3\n"
"				sample_resource(1)_sampler(1) r1.___w, r3.xy\n"
"				mov o0, r1.w\n"
"			break\n"
"		endswitch\n"
"	break\n"

"	case 2\n"
"		switch r4.z\n"
"			default\n"
"				sample_resource(2)_sampler(2) r1.x___, r3.xy\n"
"				mov o0, r1.x\n"
"			break\n"

"			case 1\n"
"				sample_resource(2)_sampler(2) r1._y__, r3.xy\n"
"				mov o0, r1.y\n"
"			break\n"

"			case 2\n"
"				sample_resource(2)_sampler(2) r1.__z_, r3.xy\n"
"				mov o0, r1.z\n"
"			break\n"

"			case 3\n"
"				sample_resource(2)_sampler(2) r1.___w, r3.xy\n"
"				mov o0, r1.w\n"
"			break\n"
"		endswitch\n"
"	break\n"

"	case 3\n"
"		switch r4.z\n"
"			default\n"
"				sample_resource(3)_sampler(3) r1.x___, r3.xy\n"
"				mov o0, r1.x\n"
"			break\n"

"			case 1\n"
"				sample_resource(3)_sampler(3) r1._y__, r3.xy\n"
"				mov o0, r1.y\n"
"			break\n"

"			case 2\n"
"				sample_resource(3)_sampler(3) r1.__z_, r3.xy\n"
"				mov o0, r1.z\n"
"			break\n"

"			case 3\n"
"				sample_resource(3)_sampler(3) r1.___w, r3.xy\n"
"				mov o0, r1.w\n"
"			break\n"
"		endswitch\n"
"	break\n"

"endswitch\n"
*/

"end\n";

/*
	Reshape a matrix (4 double word elements) splitted to 8 parts to 1 double word ND array
*/
const char kernelReshapeMat8Parts4DWToArr1DW_PS[] = 
"il_ps_2_0\n"
"dcl_cb cb0[1]\n"	// int32[C.physWidth,A.Width]
"dcl_output_generic o0\n"
"dcl_input_position_interp(linear_noperspective) vWinCoord0.xy__\n"

"dcl_resource_id(0)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_resource_id(1)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_resource_id(2)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_resource_id(3)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_resource_id(4)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_resource_id(5)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_resource_id(6)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_resource_id(7)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"

"dcl_literal l0, 4, 8, 0, 0\n"

// compute linear index in the output
"ftoi r5, vWinCoord0\n"
"umad r0.x, r5.y, cb0[0].x, r5.x\n"

// compute corresponding 2D index in the input
"umod r3.x, r0.x, cb0[0].y\n"	// x := index % A.Width
"udiv r3.y, r0.x, cb0[0].y\n"	// y := index / A.Width

// compute which input from 8 available to use
"umod r4.y, r3.y, l0.y\n"	// r4.y := y % 8
// compute which sample to take
"umod r4.z, r3.x, l0.x\n"	// r4.z := x % 4

"switch r4.y\n"

"	default\n"
"		call 0\n"
"	break\n"

"	case 1\n"
"		call 1\n"
"	break\n"

"	case 2\n"
"		call 2\n"
"	break\n"

"	case 3\n"
"		call 3\n"
"	break\n"

"	case 4\n"
"		call 4\n"
"	break\n"

"	case 5\n"
"		call 5\n"
"	break\n"

"	case 6\n"
"		call 6\n"
"	break\n"

"	case 7\n"
"		call 7\n"
"	break\n"

"endswitch\n"

/*
"switch r4.y\n"

"	default\n"
		
"		switch r4.z\n"
"			default\n"
"				sample_resource(0)_sampler(0) r1.x___, r3.xy\n"
"				mov o0, r1.x\n"
"			break\n"

"			case 1\n"
"				sample_resource(0)_sampler(0) r1._y__, r3.xy\n"
"				mov o0, r1.y\n"
"			break\n"

"			case 2\n"
"				sample_resource(0)_sampler(0) r1.__z_, r3.xy\n"
"				mov o0, r1.z\n"
"			break\n"

"			case 3\n"
"				sample_resource(0)_sampler(0) r1.___w, r3.xy\n"
"				mov o0, r1.w\n"
"			break\n"
"		endswitch\n"

"	break\n"

"	case 1\n"

"		switch r4.z\n"
"			default\n"
"				sample_resource(1)_sampler(1) r1.x___, r3.xy\n"
"				mov o0, r1.x\n"
"			break\n"

"			case 1\n"
"				sample_resource(1)_sampler(1) r1._y__, r3.xy\n"
"				mov o0, r1.y\n"
"			break\n"

"			case 2\n"
"				sample_resource(1)_sampler(1) r1.__z_, r3.xy\n"
"				mov o0, r1.z\n"
"			break\n"

"			case 3\n"
"				sample_resource(1)_sampler(1) r1.___w, r3.xy\n"
"				mov o0, r1.w\n"
"			break\n"
"		endswitch\n"

"	break\n"

"	case 2\n"
"		switch r4.z\n"
"			default\n"
"				sample_resource(2)_sampler(2) r1.x___, r3.xy\n"
"				mov o0, r1.x\n"
"			break\n"

"			case 1\n"
"				sample_resource(2)_sampler(2) r1._y__, r3.xy\n"
"				mov o0, r1.y\n"
"			break\n"

"			case 2\n"
"				sample_resource(2)_sampler(2) r1.__z_, r3.xy\n"
"				mov o0, r1.z\n"
"			break\n"

"			case 3\n"
"				sample_resource(2)_sampler(2) r1.___w, r3.xy\n"
"				mov o0, r1.w\n"
"			break\n"
"		endswitch\n"
"	break\n"

"	case 3\n"
"		switch r4.z\n"
"			default\n"
"				sample_resource(3)_sampler(3) r1.x___, r3.xy\n"
"				mov o0, r1.x\n"
"			break\n"

"			case 1\n"
"				sample_resource(3)_sampler(3) r1._y__, r3.xy\n"
"				mov o0, r1.y\n"
"			break\n"

"			case 2\n"
"				sample_resource(3)_sampler(3) r1.__z_, r3.xy\n"
"				mov o0, r1.z\n"
"			break\n"

"			case 3\n"
"				sample_resource(3)_sampler(3) r1.___w, r3.xy\n"
"				mov o0, r1.w\n"
"			break\n"
"		endswitch\n"
"	break\n"

"	case 4\n"
"		switch r4.z\n"
"			default\n"
"				sample_resource(4)_sampler(4) r1.x___, r3.xy\n"
"				mov o0, r1.x\n"
"			break\n"

"			case 1\n"
"				sample_resource(4)_sampler(4) r1._y__, r3.xy\n"
"				mov o0, r1.y\n"
"			break\n"

"			case 2\n"
"				sample_resource(4)_sampler(4) r1.__z_, r3.xy\n"
"				mov o0, r1.z\n"
"			break\n"

"			case 3\n"
"				sample_resource(4)_sampler(4) r1.___w, r3.xy\n"
"				mov o0, r1.w\n"
"			break\n"
"		endswitch\n"
"	break\n"

"	case 5\n"
"		switch r4.z\n"
"			default\n"
"				sample_resource(5)_sampler(5) r1.x___, r3.xy\n"
"				mov o0, r1.x\n"
"			break\n"

"			case 1\n"
"				sample_resource(5)_sampler(5) r1._y__, r3.xy\n"
"				mov o0, r1.y\n"
"			break\n"

"			case 2\n"
"				sample_resource(5)_sampler(5) r1.__z_, r3.xy\n"
"				mov o0, r1.z\n"
"			break\n"

"			case 3\n"
"				sample_resource(5)_sampler(5) r1.___w, r3.xy\n"
"				mov o0, r1.w\n"
"			break\n"
"		endswitch\n"
"	break\n"

"	case 6\n"
"		switch r4.z\n"
"			default\n"
"				sample_resource(6)_sampler(6) r1.x___, r3.xy\n"
"				mov o0, r1.x\n"
"			break\n"

"			case 1\n"
"				sample_resource(6)_sampler(6) r1._y__, r3.xy\n"
"				mov o0, r1.y\n"
"			break\n"

"			case 2\n"
"				sample_resource(6)_sampler(6) r1.__z_, r3.xy\n"
"				mov o0, r1.z\n"
"			break\n"

"			case 3\n"
"				sample_resource(6)_sampler(6) r1.___w, r3.xy\n"
"				mov o0, r1.w\n"
"			break\n"
"		endswitch\n"
"	break\n"

"	case 7\n"
"		switch r4.z\n"
"			default\n"
"				sample_resource(7)_sampler(7) r1.x___, r3.xy\n"
"				mov o0, r1.x\n"
"			break\n"

"			case 1\n"
"				sample_resource(7)_sampler(7) r1._y__, r3.xy\n"
"				mov o0, r1.y\n"
"			break\n"

"			case 2\n"
"				sample_resource(7)_sampler(7) r1.__z_, r3.xy\n"
"				mov o0, r1.z\n"
"			break\n"

"			case 3\n"
"				sample_resource(7)_sampler(7) r1.___w, r3.xy\n"
"				mov o0, r1.w\n"
"			break\n"
"		endswitch\n"
"	break\n"

"endswitch\n"
*/

"endmain\n"

"func 0\n"
"	switch r4.z\n"
"		default\n"
"			sample_resource(0)_sampler(0) r1.x___, r3.xy\n"
"			mov o0, r1.x\n"
"		break\n"

"		case 1\n"
"			sample_resource(0)_sampler(0) r1._y__, r3.xy\n"
"			mov o0, r1.y\n"
"		break\n"

"		case 2\n"
"			sample_resource(0)_sampler(0) r1.__z_, r3.xy\n"
"			mov o0, r1.z\n"
"		break\n"

"		case 3\n"
"			sample_resource(0)_sampler(0) r1.___w, r3.xy\n"
"			mov o0, r1.w\n"
"		break\n"
"	endswitch\n"

"ret\n"
"endfunc\n"

"func 1\n"
"	switch r4.z\n"
"		default\n"
"			sample_resource(1)_sampler(1) r1.x___, r3.xy\n"
"			mov o0, r1.x\n"
"		break\n"

"		case 1\n"
"			sample_resource(1)_sampler(1) r1._y__, r3.xy\n"
"			mov o0, r1.y\n"
"		break\n"

"		case 2\n"
"			sample_resource(1)_sampler(1) r1.__z_, r3.xy\n"
"			mov o0, r1.z\n"
"		break\n"

"		case 3\n"
"			sample_resource(1)_sampler(1) r1.___w, r3.xy\n"
"			mov o0, r1.w\n"
"		break\n"
"	endswitch\n"
"ret\n"
"endfunc\n"

"func 2\n"
"	switch r4.z\n"
"		default\n"
"			sample_resource(2)_sampler(2) r1.x___, r3.xy\n"
"			mov o0, r1.x\n"
"		break\n"

"		case 1\n"
"			sample_resource(2)_sampler(2) r1._y__, r3.xy\n"
"			mov o0, r1.y\n"
"		break\n"

"		case 2\n"
"			sample_resource(2)_sampler(2) r1.__z_, r3.xy\n"
"			mov o0, r1.z\n"
"		break\n"

"		case 3\n"
"			sample_resource(2)_sampler(2) r1.___w, r3.xy\n"
"			mov o0, r1.w\n"
"		break\n"
"	endswitch\n"
"ret\n"
"endfunc\n"

"func 3\n"
"	switch r4.z\n"
"		default\n"
"			sample_resource(3)_sampler(3) r1.x___, r3.xy\n"
"			mov o0, r1.x\n"
"		break\n"

"		case 1\n"
"			sample_resource(3)_sampler(3) r1._y__, r3.xy\n"
"			mov o0, r1.y\n"
"		break\n"

"		case 2\n"
"			sample_resource(3)_sampler(3) r1.__z_, r3.xy\n"
"			mov o0, r1.z\n"
"		break\n"

"		case 3\n"
"			sample_resource(3)_sampler(3) r1.___w, r3.xy\n"
"			mov o0, r1.w\n"
"		break\n"
"	endswitch\n"
"ret\n"
"endfunc\n"

"func 4\n"
"	switch r4.z\n"
"		default\n"
"			sample_resource(4)_sampler(4) r1.x___, r3.xy\n"
"			mov o0, r1.x\n"
"		break\n"

"		case 1\n"
"			sample_resource(4)_sampler(4) r1._y__, r3.xy\n"
"			mov o0, r1.y\n"
"		break\n"

"		case 2\n"
"			sample_resource(4)_sampler(4) r1.__z_, r3.xy\n"
"			mov o0, r1.z\n"
"		break\n"

"		case 3\n"
"			sample_resource(4)_sampler(4) r1.___w, r3.xy\n"
"			mov o0, r1.w\n"
"		break\n"
"	endswitch\n"
"ret\n"
"endfunc\n"

"func 5\n"
"	switch r4.z\n"
"		default\n"
"			sample_resource(5)_sampler(5) r1.x___, r3.xy\n"
"			mov o0, r1.x\n"
"		break\n"

"		case 1\n"
"			sample_resource(5)_sampler(5) r1._y__, r3.xy\n"
"			mov o0, r1.y\n"
"		break\n"

"		case 2\n"
"			sample_resource(5)_sampler(5) r1.__z_, r3.xy\n"
"			mov o0, r1.z\n"
"		break\n"

"		case 3\n"
"			sample_resource(5)_sampler(5) r1.___w, r3.xy\n"
"			mov o0, r1.w\n"
"		break\n"
"	endswitch\n"
"ret\n"
"endfunc\n"

"func 6\n"
"	switch r4.z\n"
"		default\n"
"			sample_resource(6)_sampler(6) r1.x___, r3.xy\n"
"			mov o0, r1.x\n"
"		break\n"

"		case 1\n"
"			sample_resource(6)_sampler(6) r1._y__, r3.xy\n"
"			mov o0, r1.y\n"
"		break\n"

"		case 2\n"
"			sample_resource(6)_sampler(6) r1.__z_, r3.xy\n"
"			mov o0, r1.z\n"
"		break\n"

"		case 3\n"
"			sample_resource(6)_sampler(6) r1.___w, r3.xy\n"
"			mov o0, r1.w\n"
"		break\n"
"	endswitch\n"
"ret\n"
"endfunc\n"

"func 7\n"
"	switch r4.z\n"
"		default\n"
"			sample_resource(7)_sampler(7) r1.x___, r3.xy\n"
"			mov o0, r1.x\n"
"		break\n"

"		case 1\n"
"			sample_resource(7)_sampler(7) r1._y__, r3.xy\n"
"			mov o0, r1.y\n"
"		break\n"

"		case 2\n"
"			sample_resource(7)_sampler(7) r1.__z_, r3.xy\n"
"			mov o0, r1.z\n"
"		break\n"

"		case 3\n"
"			sample_resource(7)_sampler(7) r1.___w, r3.xy\n"
"			mov o0, r1.w\n"
"		break\n"
"	endswitch\n"
"ret\n"
"endfunc\n"

"end\n";

/*
	Transpose a matrix with 4 double word elements
*/
const char kernelTransposeMat4DW_PS[] =
"il_ps_2_0\n"
"dcl_input_position_interp(linear_noperspective) vWinCoord0.xy__\n"
"dcl_output_generic o0\n"
"dcl_resource_id(0)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"

"dcl_literal l0, 4.0f, 0.25f, 1.0f, 2.0f\n"

"flr r0.xy00, vWinCoord0.yx00\n"	// transposed 2D index 
"mul r0.y, r0.y, l0.x\n"			// account that we are working with quads 

"add r0.__zw, r0.00yy, l0.00zw\n"	// r0 := [x,y,y+1,y+2]

"mod r2.x, r0.x, l0.x\n"			// x % 4
"ftoi r2.x, r2.x\n"

"mul r0.x, r0.x, l0.y\n"			// x := x/4
"flr r0.x, r0.x\n"

"add r1.xy00, r0.xw00, r0.0100\n"	// r1 := [x,y+3]

"switch r2.x\n"

"	default\n"
"		sample_resource(0)_sampler(0) r3.x___, r0.xy\n"
"		sample_resource(0)_sampler(0) r4.x___, r0.xz\n"
"		sample_resource(0)_sampler(0) r5.x___, r0.xw\n"
"		sample_resource(0)_sampler(0) r6.x___, r1.xy\n"
"		mov r3.y, r4.x\n"
"		mov r3.z, r5.x\n"
"		mov r3.w, r6.x\n"
"		mov o0, r3\n"
"	break\n"

"	case 1\n"
"		sample_resource(0)_sampler(0) r3._y__, r0.xy\n"
"		sample_resource(0)_sampler(0) r4._y__, r0.xz\n"
"		sample_resource(0)_sampler(0) r5._y__, r0.xw\n"
"		sample_resource(0)_sampler(0) r6._y__, r1.xy\n"
"		mov r4.x, r3.y\n"
"		mov r4.z, r5.y\n"
"		mov r4.w, r6.y\n"
"		mov o0, r4\n"
"	break\n"

"	case 2\n"
"		sample_resource(0)_sampler(0) r3.__z_, r0.xy\n"
"		sample_resource(0)_sampler(0) r4.__z_, r0.xz\n"
"		sample_resource(0)_sampler(0) r5.__z_, r0.xw\n"
"		sample_resource(0)_sampler(0) r6.__z_, r1.xy\n"
"		mov r5.x, r3.z\n"
"		mov r5.y, r4.z\n"
"		mov r5.w, r6.z\n"
"		mov o0, r5\n"
"	break\n"

"	case 3\n"
"		sample_resource(0)_sampler(0) r3.___w, r0.xy\n"
"		sample_resource(0)_sampler(0) r4.___w, r0.xz\n"
"		sample_resource(0)_sampler(0) r5.___w, r0.xw\n"
"		sample_resource(0)_sampler(0) r6.___w, r1.xy\n"
"		mov r6.x, r3.w\n"
"		mov r6.y, r4.w\n"
"		mov r6.z, r5.w\n"
"		mov o0, r6\n"
"	break\n"


"endswitch\n"

"end\n";

/*
	Getting a submatrix from a given matrix without handling left bounds (xleft % 4 == 0)
*/
const char kernelGetSubMat4DWNoLeftBounds_PS[] = 
"il_ps_2_0\n"
"dcl_cb cb0[2]\n"	// [xleft, ytop, xleft+C.physWidth-1, ytop+C.Height], [C.physWidth*C.physNumComponents-C.Width]
"dcl_input_position_interp(linear_noperspective) vWinCoord0.xy__\n"
"dcl_resource_id(0)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"

"flr r0.xy, vWinCoord0.xy\n"
"add r0.xy, r0.xy, cb0[0].xy\n"	// [x+xleft, y+ytop] -> position in the input

"lt r1.x, r0.y, cb0[0].w\n"
"if_logicalnz r1.x\n"			// if y < ytop+C.Height

"	ne r1.x, r0.x, cb0[0].z\n"
"	if_logicalnz r1.x\n"	// if x != xleft+C.physWidth-1
"		sample_resource(0)_sampler(0) o0, r0.xy\n"
"	else\n"

"		ftoi r1.x, cb0[1].x\n"

"		switch r1.x\n"

"			default\n"
"				sample_resource(0)_sampler(0) o0, r0.xy\n"
"			break\n"

"			case 1\n"	
"				sample_resource(0)_sampler(0) o0.xyz0, r0.xy\n"
"			break\n"

"			case 2\n"
"				sample_resource(0)_sampler(0) o0.xy00, r0.xy\n"
"			break\n"

"			case 3\n"
"				sample_resource(0)_sampler(0) o0.x000, r0.xy\n"
"			break\n"

"		endswitch\n"
"	endif\n"
"else\n"
"	mov o0, o0.0000\n"
"endif\n"

"end\n";
/*
	Zeroing array memory
*/
const char kernelZeroMemory_PS[] = 
"il_ps_2_0\n"
"dcl_output_generic o0\n"
"mov o0, r0.0000\n"
"end\n";

/*
	Split a matrix to 4 parts
*/
const char kernelSplitMatrixTo4Parts_PS[] =
"il_ps_2_0\n"
"dcl_input_position_interp(linear_noperspective) vWinCoord0.xy__\n"
"dcl_resource_id(0)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"

"dcl_literal l0, 3.0f, 4.0f, 1.0f, 2.0f\n"

"flr r0.xy, vWinCoord0.xy\n"
"mul r0.y, r0.y, l0.y\n"		// r1.xy := [x,y*4] - 2D position of the first row to copy

"add r0.__zw, r0.00yy, l0.00zw\n"	// r0 := [x,y,y+1,y+2]
"add r1.xy00, r0.xy00, l0.0x00\n"		// r1 := [x,y+3]

"dcl_output_generic o0\n"
"dcl_output_generic o1\n"
"dcl_output_generic o2\n"
"dcl_output_generic o3\n"

"sample_resource(0)_sampler(0) o0, r0.xy\n"
"sample_resource(0)_sampler(0) o1, r0.xz\n"
"sample_resource(0)_sampler(0) o2, r0.xw\n"
"sample_resource(0)_sampler(0) o3, r1.xy\n"

"end\n";

/*
	Split a matrix to 8 parts
*/
const char kernelSplitMatrixTo8Parts_PS[] =
"il_ps_2_0\n"
"dcl_input_position_interp(linear_noperspective) vWinCoord0.xy__\n"
"dcl_resource_id(0)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"

"dcl_literal l0, 3.0f, 8.0f, 1.0f, 2.0f\n"

"flr r0.xy, vWinCoord0.xy\n"
"mul r0.y, r0.y, l0.y\n"				// r1.xy := [x,y*8] - 2D position of the first row to copy

"add r0.__zw, r0.00yy, l0.00zw\n"			// r0 := [x,y,y+1,y+2]
"add r1.xyzw, r0.xyzw, l0.0xxx\n"			// r1 := [x,y+3,y+4,y+5]
"add r2.xyz0, r1.xyz0, l0.0xx0\n"			// r2 := [x,y+6,y+7]

"dcl_output_generic o0\n"
"dcl_output_generic o1\n"
"dcl_output_generic o2\n"
"dcl_output_generic o3\n"
"dcl_output_generic o4\n"
"dcl_output_generic o5\n"
"dcl_output_generic o6\n"
"dcl_output_generic o7\n"

"sample_resource(0)_sampler(0) o0, r0.xy\n"
"sample_resource(0)_sampler(0) o1, r0.xz\n"
"sample_resource(0)_sampler(0) o2, r0.xw\n"
"sample_resource(0)_sampler(0) o3, r1.xy\n"
"sample_resource(0)_sampler(0) o4, r1.xz\n"
"sample_resource(0)_sampler(0) o5, r1.xw\n"
"sample_resource(0)_sampler(0) o6, r2.xy\n"
"sample_resource(0)_sampler(0) o7, r2.xz\n"

"end\n";

class Kernel
{
public:
	Kernel(KernelCode iKernel, CALtarget target, CALresult* err);
	~Kernel(void);	

	KernelCode iKernel;			// kernel code
	CALobject obj;				// CAL kernel object
	CALimage img;				// CAL kernel image

	long nInputs;				// number of kernel inputs
	long nOutputs;				// number of kernel outputs			
	long nConstants;			// number of kernel constants
	long* constSizes;			// size for each constant
	CALformat* constFormats;	// data format for each constant	

	BOOL usesGlobalBuffer;		// TRUE when kernel uses a global buffer
};
