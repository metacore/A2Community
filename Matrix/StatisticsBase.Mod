MODULE StatisticsBase; (** AUTHOR "Patrick Hunziker"; PURPOSE "tools for statistics"; *)

IMPORT MatrixBase, MathL, MatrixUtilities, Reals;

TYPE Matrix=MatrixBase.Matrix;
	Vector=MatrixBase.Vector;
	Datatype=MatrixBase.Datatype;

PROCEDURE Mean*(CONST X: Vector): Datatype;
BEGIN
	RETURN SUM(X)/LEN(X,0)
END Mean;

PROCEDURE KSmallest( VAR a: Vector;  n, k: LONGINT ): Datatype;
(** caution: modifies X , Algorithm by N.Wirth / Hoare, cf. N. Wirth: Algorithms & Datastructures. *)
VAR i, j, l, m: LONGINT;  x: Datatype;

	PROCEDURE swap( VAR x, y: Datatype );
	VAR z: LONGREAL;
	BEGIN
		z := x;  x := y;  y := z
	END swap;

BEGIN
	l := 0;  m := n - 1;
	WHILE (l < m) DO
		x := a[k];  i := l;  j := m;
		REPEAT
			WHILE (a[i] < x) DO INC( i ) END;
			WHILE (x < a[j]) DO DEC( j ) END;
			IF i <= j THEN swap( a[i], a[j] );  INC( i );  DEC( j ) END
		UNTIL i > j;
		IF j < k THEN l := i END;
		IF k < i THEN m := j END
	END;
	RETURN a[k]
END KSmallest;

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
			WHILE  (X[i] < u) DO INC(i) END;
			WHILE (u < X[j]) DO DEC(j) END;
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

 PROCEDURE DestructiveMedian*(VAR v1:Vector):Datatype;
 VAR len:LONGINT;
 BEGIN
 	len:=LEN(v1,0);
	IF ODD( len ) THEN RETURN KSmallest( v1, len, len DIV 2 )
	ELSE RETURN (KSmallest( v1, len, len DIV 2 - 1 ) + KSmallest( v1, len, len DIV 2 )) / 2
	END
 END DestructiveMedian;

 PROCEDURE Median*(CONST v:Vector):Datatype;
 VAR v1:Vector;
 BEGIN
 	v1:=v;(* leave original data intact*)
 	RETURN DestructiveMedian(v1)
 END Median;

 (* variance of dataset *)
 PROCEDURE Variance*(CONST v:Vector):Datatype;
 VAR diff:Vector;
 BEGIN
 	 diff:=v-Mean(v);
 	 RETURN (diff+*diff) / LEN(v,0)
 END Variance;

 (* full data *)
 PROCEDURE StandardDeviation*(CONST v:Vector): Datatype;
 BEGIN
 	RETURN MathL.sqrt(Variance(v))
 END StandardDeviation;

 (* subset of data *)
 PROCEDURE EstimatedStandardDeviation*(CONST v:Vector): Datatype;
 BEGIN
 	RETURN MathL.sqrt(EstimatedVariance(v))
 END EstimatedStandardDeviation;

	(* variance estimated from subset of data *)
 PROCEDURE EstimatedVariance*(CONST v:Vector):Datatype;
 VAR diff:Vector;
 BEGIN
 	 diff:=v-Mean(v);
 	 RETURN (diff+*diff) / (LEN(v,0)-1)
 END EstimatedVariance;

 PROCEDURE Skewness*(CONST X : Vector) : Datatype;
	VAR
		sigma : Datatype;
		x1: Vector;
	BEGIN
		sigma:=MathL.sqrt(Variance(X));
		MatrixUtilities.OutVector([sigma]);
		x1:=X-Mean(X);
		MatrixUtilities.OutVector(x1);
		MatrixUtilities.OutVector(x1.*x1);
		MatrixUtilities.OutVector([(x1.*x1)+* x1]);
		RETURN  ((x1 .* x1) +* x1) / (sigma*sigma*sigma)/ LEN(X,0)
	END Skewness;

PROCEDURE Kurtosis*(CONST X : Vector) : Datatype;
	VAR
		variance: Datatype;
		x1,x2:Vector;
	BEGIN
		variance:=Variance(X);
		x1:=X-Mean(X);
		x2:=x1.*x1;
		RETURN (x2 +* x2) / (variance*variance) / LEN(X,0) - 3;
	END Kurtosis;

PROCEDURE NormalizeColumns*(VAR A:Matrix); (*normalizing to mean=0 and SD=1*)
VAR onesR, meanVector,sdVector: Vector; meanMatrix, sdMatrix:Matrix;
BEGIN
	NEW(onesR, LEN(A,0));
	onesR:=1; 
	meanVector := (onesR * A)/LEN(A,0);
	meanMatrix := onesR ** meanVector;
	A:=A-meanMatrix;
	sdVector := MatrixUtilities.ApplyUnaryVec(onesR * (A.*A), MathL.sqrt) / MathL.sqrt(LEN(A,0));
	sdMatrix:= onesR ** sdVector;
	A:= A ./ sdMatrix;
END NormalizeColumns;

(* subtract column mean from each column *)
PROCEDURE ZeroMeanColumns*(VAR A:Matrix);
	VAR onesR, meanVector: Vector; 
BEGIN
	NEW(onesR, LEN(A,0));
	onesR:=1;
	meanVector := (onesR * A)/LEN(A,0);
	A:=A - onesR ** meanVector;
END ZeroMeanColumns;

(*
PROCEDURE Test*;
CONST a=[1,2,3,4]; b=[1,2,2,1]; c=[1,2,3,2]; d=[1,1,2,3,1]
BEGIN
	MatrixUtilities.OutVector([Skewness(a)]);
	MatrixUtilities.OutVector([Skewness(b)]);
	MatrixUtilities.OutVector([Skewness(c)]);
	MatrixUtilities.OutVector([Skewness(d)]);
	MatrixUtilities.OutVector([Kurtosis(a)]);
	MatrixUtilities.OutVector([Kurtosis(b)]);
	MatrixUtilities.OutVector([Kurtosis(c)]);
	MatrixUtilities.OutVector([Kurtosis(d)]);
END Test;
*)

(*
PROCEDURE TestNormalizeColumns*;
VAR A:Matrix;
BEGIN
	A:=[[1,2,3,4],[2,3,4,8],[3,4,5,12],[4,5,6,16]];
	NormalizeColumns(A);
	MatrixUtilities.OutMatrix(A);
END TestNormalizeColumns;
*)

PROCEDURE TestSort*;
VAR v:Vector; zero: Datatype;
BEGIN
	v:=[0, 1, -1/zero, 1/zero, 4,3,2,3,4,5];
	QSort(v);
	MatrixUtilities.OutVector(v);
END TestSort;

PROCEDURE TestMedian*;
VAR v:Vector; zero: Datatype;
BEGIN
	v:=[0, 1, -1/zero, 1/zero, 4,3,2,3,4,5];
	MatrixUtilities.OutVector(v);
	MatrixUtilities.OutVector([Median(v)])
END TestMedian;


END StatisticsBase.

StatisticsBase.TestSort ~
StatisticsBase.TestMedian ~

SystemTools.FreeDownTo StatisticsBase ~
