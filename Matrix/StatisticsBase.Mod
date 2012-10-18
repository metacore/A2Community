MODULE StatisticsBase; (** AUTHOR "Patrick Hunziker"; PURPOSE "tools for statistics"; *)

IMPORT MatrixBase, MathL, MatrixUtilities;

TYPE Matrix=MatrixBase.Matrix;
	Vector=MatrixBase.Vector;
	Datatype=MatrixBase.Datatype;

PROCEDURE Mean*(CONST X: Vector): Datatype;
BEGIN
	IF LEN(X,0)>0 THEN RETURN SUM(X)/LEN(X,0) ELSE RETURN 0 END;
END Mean;

PROCEDURE QSort*(VAR X : Vector);
	PROCEDURE Sort(l, r : LONGINT);
	VAR
		i, j : LONGINT;
		u, v : Datatype;
	BEGIN
		i := l;
		j := r;
		u := X[(l+r) DIV 2];
		REPEAT
			WHILE X[i] < u DO INC(i) END;
			WHILE u < X[j] DO DEC(j) END;
			IF i <= j THEN
				v := X[i]; X[i] := X[j]; X[j] := v; 
				INC(i); DEC(j);
			 END;
		UNTIL i > j;
		IF l < j THEN Sort(l, j) END;
		IF i < r THEN Sort(i, r) END;
	END Sort;
 BEGIN
	Sort(0, LEN(X,0)-1);
 END QSort;
 
 PROCEDURE Median*(CONST v:Vector):Datatype;
 VAR v1:Vector; len:LONGINT;
 BEGIN
 	v1:=v;(* leave original data intact*)
 	len:=LEN(v1,0);
 	QSort(v1);
 	IF ODD(len) THEN RETURN v1[len DIV 2]
 	ELSE RETURN (v1[len DIV 2] + v1[len DIV 2 +1])/2
 	END;
 END Median;

PROCEDURE NormalizeColumns*(VAR A:Matrix); (*normalizing to mean=0 and SD=1*)
VAR onesR, onesC, meanVector,sdVector: Vector; meanMatrix, sdMatrix:Matrix;
BEGIN
	NEW(onesR, LEN(A,0));
	NEW(onesC, LEN(A,1));
	onesR:=1; onesC:=1;
	meanVector := (onesR * A)/LEN(A,0); 
	meanMatrix := onesR ** meanVector;
	A:=A-meanMatrix;
	sdVector := MatrixUtilities.ApplyUnaryVec(onesR * (A.*A), MathL.sqrt) / MathL.sqrt(LEN(A,0));
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
