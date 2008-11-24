
#define KernAdd1DR				0	// addition of 1D streams
#define KernAdd2DR				1	// addition of 2D streams
#define KernSub1DR				2	// subtraction of 1D streams
#define KernSub2DR				3	// subtraction of 2D streams
#define KernNaiveMatMulR		4	// naive matrix multiply
#define KernEwMul1DR			5	// elementwise multiply on 1D streams
#define KernEwMul2DR			6	// elementwise multiply on 2D streams
#define KernEwDiv1DR			7	// elementwise divide on 1D streams
#define KernEwDiv2DR			8	// elementwise divide on 2D streams
#define KernDotProd1DR			9	// dot product on 1D streams
#define KernDotProd2DR			10	// dot product on 2D streams

#define NKernels				11	// total number of kernels

// add 1D streams
const char kernelAdd1DR[] =
"il_ps_2_0\n"
"dcl_resource_id(0)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_input_generic_interp(linear) v0.xy__\n"
"dcl_resource_id(1)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_input_generic_interp(linear) v1.xy__\n"
"sample_resource(0)_sampler(0) r0.x, v0.xy00\n"
"sample_resource(1)_sampler(1) r1.x, v1.xy00\n"
"mov r2.x, r0.xxxx\n"
"mov r3.x, r1.xxxx\n"
"call 0\n"
"mov r4.x, r5.xxxx\n"
"dcl_output_generic o0\n"
"mov o0, r4.xxxx\n"
"ret\n"
"func 0\n"
"add r6.x, r2.xxxx, r3.xxxx\n"
"mov r7.x, r6.xxxx\n"
"mov r5.x, r7.xxxx\n"
"ret\n"
"end;\n";

// add 2D streams
const char kernelAdd2DR[] =
"il_ps_2_0\n"
"dcl_resource_id(0)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_input_generic_interp(linear) v0.xy__\n"
"dcl_resource_id(1)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_input_generic_interp(linear) v1.xy__\n"
"sample_resource(0)_sampler(0) r0.x, v0.xy00\n"
"sample_resource(1)_sampler(1) r1.x, v1.xy00\n"
"mov r2.x, r0.xxxx\n"
"mov r3.x, r1.xxxx\n"
"call 0\n"
"mov r4.x, r5.xxxx\n"
"dcl_output_generic o0\n"
"mov o0, r4.xxxx\n"
"ret\n"
"func 0\n"
"add r6.x, r2.xxxx, r3.xxxx\n"
"mov r7.x, r6.xxxx\n"
"mov r5.x, r7.xxxx\n"
"ret\n"
"end;\n";


// subtract 1D streams
const char kernelSub1DR[] =
"il_ps_2_0\n"
"dcl_resource_id(0)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_input_generic_interp(linear) v0.xy__\n"
"dcl_resource_id(1)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_input_generic_interp(linear) v1.xy__\n"
"sample_resource(0)_sampler(0) r0.x, v0.xy00\n"
"sample_resource(1)_sampler(1) r1.x, v1.xy00\n"
"mov r2.x, r0.xxxx\n"
"mov r3.x, r1.xxxx\n"
"call 0\n"
"mov r4.x, r5.xxxx\n"
"dcl_output_generic o0\n"
"mov o0, r4.xxxx\n"
"ret\n"
"func 0\n"
"add r6.x, r2.xxxx, r3.xxxx\n"
"mov r7.x, r6.xxxx\n"
"mov r5.x, r7.xxxx\n"
"ret\n"
"end;\n";

// subtract 2D streams
const char kernelSub2DR[] =
"il_ps_2_0\n"
"dcl_resource_id(0)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_input_generic_interp(linear) v0.xy__\n"
"dcl_resource_id(1)_type(2d,unnorm)_fmtx(float)_fmty(float)_fmtz(float)_fmtw(float)\n"
"dcl_input_generic_interp(linear) v1.xy__\n"
"sample_resource(0)_sampler(0) r0.x, v0.xy00\n"
"sample_resource(1)_sampler(1) r1.x, v1.xy00\n"
"mov r2.x, r0.xxxx\n"
"mov r3.x, r1.xxxx\n"
"call 0\n"
"mov r4.x, r5.xxxx\n"
"dcl_output_generic o0\n"
"mov o0, r4.xxxx\n"
"ret\n"
"func 0\n"
"add r6.x, r2.xxxx, r3.xxxx\n"
"mov r7.x, r6.xxxx\n"
"mov r5.x, r7.xxxx\n"
"ret\n"
"end;\n";

// naive matrix multiply: C{2D stream} := A{2D stream} * B{2D stream}
const char kernelNaiveMatMulR[] =
"\n";

// elementwise multiply on 1D streams
const char kernelEwMul1DR[] =
"\n";

// elementwise multiply on 2D streams
const char kernelEwMul2DR[] =
"\n";

// elementwise divide on 1D streams
const char kernelEwDiv1DR[] =
"\n";

// elementwise divide on 2D streams
const char kernelEwDiv2DR[] =
"\n";

// dot product on 1D streams
const char kernelDotProd1DR[] =
"\n";

// dot product on 2D streams
const char kernelDotProd2DR[] =
"\n";