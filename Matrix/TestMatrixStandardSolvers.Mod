MODULE TestMatrixStandardSolvers; (** AUTHOR ""; PURPOSE ""; *)

IMPORT Base:=MatrixBase, Solvers:=MatrixStandardSolvers, MatrixTransforms, Util:= MatrixUtilities, Out:=KernelLog;

PROCEDURE DoQR*;
VAR QR: Solvers.QR; A,B,R, Ainv:Base.Matrix; b,x:Base.Vector; res:LONGINT;
BEGIN
	A:=[[1,2,3,4],[4,3,3,1],[1,2,4,3],[2,2,2,3]]; b:=[2,3,4,5];

	NEW(QR,A);
	x:=QR.Solve(b);

	(*x:=MatrixSolvers.SolveQR(A,b,res);*)

	Out.String("b:"); Out.Ln;
	Util.OutVector(b); Out.Ln;

	Out.String("x:"); Out.Ln;
	Util.OutVector(x);Out.Ln;

	Out.String("A:"); Out.Ln;
	Util.OutMatrix(A);Out.Ln;


	Out.String("A*x"); Out.Ln;
	Util.OutVector(A * x); Out.Ln;

	Out.String("Q*R"); Out.Ln;
	Util.OutMatrix(QR.Q*QR.R); Out.Ln;

	Out.String("orthogonality of Q: by checking Q*Q`"); Out.Ln;
	Util.OutMatrix(QR.Q*QR.Q`);Out.Ln;

	Out.String("upper diagonal R"); Out.Ln;
	Util.OutMatrix(QR.R); Out.Ln;
END DoQR;

PROCEDURE DoGaussJordan*;
VAR GJ: Solvers.GaussJordan; A,B,R, Ainv:Base.Matrix; b,x:Base.Vector; res:LONGINT;
BEGIN
	A:=[[1,2,3,4],[4,3,3,1],[1,2,4,3],[2,2,2,3]]; b:=[2,3,4,5];

	NEW(GJ,A);
	x:=GJ.Solve(b);

	Out.String("b:"); Out.Ln;
	Util.OutVector(b); Out.Ln;

	Out.String("x:"); Out.Ln;
	Util.OutVector(x);Out.Ln;

	Out.String("A:"); Out.Ln;
	Util.OutMatrix(A);Out.Ln;

	Out.String("A*Ainv"); Out.Ln;
	Util.OutMatrix(A * GJ.Ainv); Out.Ln;

	Out.String("A*x"); Out.Ln;
	Util.OutVector(A * x); Out.Ln;
END DoGaussJordan;

PROCEDURE DoLU*;
VAR LU: Solvers.LU; A,B,R, Ainv:Base.Matrix; b,x:Base.Vector; res:LONGINT;
BEGIN
	A:=[[1,2,3,4],[4,3,3,1],[1,2,4,3],[2,2,2,3]]; b:=[2,3,4,5];

	NEW(LU,A);
	x:=LU.Solve(b);

	Out.String("b:"); Out.Ln;
	Util.OutVector(b); Out.Ln;

	Out.String("x:"); Out.Ln;
	Util.OutVector(x);Out.Ln;

	Out.String("A:"); Out.Ln;
	Util.OutMatrix(A);Out.Ln;

	Out.String("A*Ainv"); Out.Ln;
	Util.OutMatrix(A * LU.Inverse()); Out.Ln;

	Out.String("A*x"); Out.Ln;
	Util.OutVector(A * x); Out.Ln;
END DoLU;


PROCEDURE DoGauss*;
VAR G: Solvers.Gauss; A,B,R, Ainv:Base.Matrix; b,x:Base.Vector; res:LONGINT;
BEGIN
	A:=[[1,2,3,4],[4,3,3,1],[1,2,4,3],[2,2,2,3]]; b:=[2,3,4,5];

	NEW(G,A);
	x:=G.Solve(b);

	Out.String("b:"); Out.Ln;
	Util.OutVector(b); Out.Ln;

	Out.String("x:"); Out.Ln;
	Util.OutVector(x);Out.Ln;

	Out.String("A:"); Out.Ln;
	Util.OutMatrix(A);Out.Ln;

	Out.String("A*x"); Out.Ln;
	Util.OutVector(A * x); Out.Ln;
END DoGauss;

PROCEDURE DoCholesky*;
VAR C: Solvers.Cholesky; A,B,R, Ainv:Base.Matrix; b,x:Base.Vector; res:LONGINT;
BEGIN
	A:=[[1,2,3,4],[4,3,3,1],[1,2,4,3],[2,2,2,3]]; b:=[2,3,4,5]; (*NOT POSITIVE DEFINITE*)
	(* TRY NOW WITH POSITIVE DEFINITE MATRIX !! *)

	NEW(C,A);

	Out.String("L:"); Out.Ln;
	Util.OutMatrix(C.L);Out.Ln;

	Out.String("L*C.L`"); Out.Ln;
	Util.OutMatrix(C.L * C.L`); Out.Ln;
END DoCholesky;
(*
PROCEDURE DoGaussAugmented*;
VAR A,B: Base.Matrix; v:Base.Vector; res,i,j:LONGINT;
BEGIN
	A:=[[1,2,3,4,2],[4,3,3,1,3],[1,2,4,3,4],[2,2,2,3,5]];;
	Util.OutMatrix(A);
	MatrixTransforms.GaussAugmented(A);
	Util.OutMatrix(A);
END DoGaussAugmented;*)


PROCEDURE DoGaussElim*;
VAR A,B: Base.Matrix; v:Base.Vector; res,i,j:LONGINT;
BEGIN
	A:=[[1,2,3,4],[4,3,3,1],[1,2,4,3],[2,2,2,3]];
	Util.OutMatrix(A);
	MatrixTransforms.Gauss(A);
	Util.OutMatrix(A);
END DoGaussElim;

(*
PROCEDURE DoQR2*;
VAR A,B,Ainv:Matrix; b,x:Vector; res:LONGINT; index: IntVector;
BEGIN
	A:=[[1,2,3,4],[4,3,3,1],[1,2,4,3],[2,2,2,3]]; b:=[2,3,4,5];
	B:=A;

	x:=MatrixSolvers.QR(A,b,res);

	Out.Int(res,6);Out.Ln;
	out(b); Out.Ln;
	out(x);Out.Ln;
	out(index); Out.Ln;
	outM(B);Out.Ln;
	out(B*x); Out.Ln;
END DoQR2;
*)
END TestMatrixStandardSolvers.

SystemTools.Free
TestMatrixStandardSolvers
MatrixStandardSolvers
MatrixTransforms~
TestMatrixStandardSolvers.DoLU
TestMatrixStandardSolvers.DoQR
TestMatrixStandardSolvers.DoGaussJordan
TestMatrixStandardSolvers.DoGauss
TestMatrixStandardSolvers.DoGaussAugmented~
TestMatrixStandardSolvers.DoGaussElim~
TestMatrixStandardSolvers.DoCholesky
MatrixStandardSolvers MatrixUtilities~
