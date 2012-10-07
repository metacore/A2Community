MODULE StatisticsBase; (** AUTHOR "Patrick Hunziker"; PURPOSE "tools for statistics"; *)

IMPORT MatrixBase, MathL, MatrixUtilities;

TYPE Matrix=MatrixBase.Matrix;
	Vector=MatrixBase.Vector;
	Datatype=MatrixBase.Datatype;
	
PROCEDURE NormalizeColumns*(VAR A:Matrix); (*normalizing to mean=0 and SD=1*)
VAR onesR, onesC, meanVector,sdVector: Vector; meanMatrix, sdMatrix:Matrix;
BEGIN
	NEW(onesR, LEN(A,0));
	NEW(onesC, LEN(A,1));
	onesR:=1; onesC:=1;
	meanVector:= (onesR * A)/LEN(A,0); 
	meanMatrix:= onesR ** meanVector;
	A:=A-meanMatrix;
	sdVector :=MatrixUtilities.ApplyUnaryVec(onesR * (A.*A), MathL.sqrt) / MathL.sqrt(LEN(A,0));
	sdMatrix:= onesR ** sdVector;	
	A:= A ./ sdMatrix;
END NormalizeColumns;

(*
PROCEDURE TestNormalizeColumns*;
VAR A:Matrix;
BEGIN
	A:=[[1,2,3,4],[2,3,4,8],[3,4,5,12],[4,5,6,16]];
	NormalizeColumns(A);
	MatrixUtilities.OutMatrix(A);
END TestNormalizeColumns;
*)

END StatisticsBase.

SystemTools.FreeDownTo StatisticsBase ~
