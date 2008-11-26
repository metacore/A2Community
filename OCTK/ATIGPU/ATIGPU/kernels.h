
#define KernAddR				0	// addition
#define KernSubR				1	// subtraction
#define KernNaiveMatMulR		2	// naive matrix multiply
#define KernEwMulR				3	// elementwise multiply
#define KernEwDivR				4	// elementwise divide
#define KernDotProdR			5	// dot product

#define NKernels				6	// total number of kernels

// add
const char kernelAddR[] =
/*
"il_ps_2_0\n"
"dcl_input_position_interp(linear_noperspective) vWinCoord0.xy__\n"
"dcl_output_generic o0\n"
"dcl_resource_id(0)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_resource_id(1)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"sample_resource(0)_sampler(0) r0, vWinCoord0\n"
"sample_resource(1)_sampler(1) r1, vWinCoord0\n"
"add o0, r0, r1\n"
"end\n";
*/

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

// subtract
const char kernelSubR[] =
"il_ps_2_0\n"
"dcl_input_position_interp(linear_noperspective) vWinCoord0.xy__\n"
"dcl_output_generic o0\n"
"dcl_resource_id(0)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_resource_id(1)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"sample_resource(0)_sampler(0) r0, vWinCoord0\n"
"sample_resource(1)_sampler(1) r1, vWinCoord0\n"
"add o0, r0, r1\n"
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