MODULE StatisticsRegression; (** AUTHOR ""; PURPOSE ""; *)

IMPORT MatrixBase, MatrixLeastSquares, Util:=MatrixUtilities, Streams, KernelLog, (* *) ExtraSort (* *);

(* http://en.wikipedia.org/wiki/Linear_regression *)	 
(**

elementwise:  
	y1 = b1 x11+b2 x12 +b3 x13 .. + e1 
	y2 = b2 x21 ...
	
Usually a constant is included as one of the regressors. 
For example we can take xi1 = 1 for i = 1, ..., n. 
The corresponding element of X is called the intercept. 
	
vector form: 
 y= Xb + e  ; with y,b,e: vector; X: matrix (in the simplest case, only  one column)

least squares formulation
 X`X b = X` y 
 
 or
 b= Invert(X`X) * X`y
 *)

TYPE Matrix*=MatrixBase.Matrix; 
	Vector*=MatrixBase.Vector;
	Scalar*=MatrixBase.Datatype;
	
VAR w: Streams.Writer;

(**
y: Response variables
x: regressors = input variables, making up the design matrix X
b: regression coefficients
e: error term
usually, a constant is included in the regressors X, (e.g. all xi1 := 1), and the resulting b is called intercept.
See example in Test() below.
*)
PROCEDURE LinearRegression*(CONST X: Matrix; CONST y: Vector; VAR b, e: Vector);
VAR qr: MatrixLeastSquares.LeastSquaresQR;
BEGIN
	NEW(qr, X); 
	b:=qr.Solve(y);
	e:= y- X*b;
END LinearRegression;

(* no intercept, assumption is that regression line goes through origin *)
PROCEDURE SimpleRegression*(CONST x: Vector; CONST y: Vector; VAR b: Scalar; VAR e: Vector);
VAR X: Matrix; B: Vector;
BEGIN
	(*can be simplified*)
	NEW(X, LEN(x,0), 1); 
	X[..,0]:=x;
	LinearRegression(X,y,B,e);
	b:=B[0];
END SimpleRegression;

PROCEDURE SimpleRegressionIntercept*(CONST x: Vector; CONST y: Vector; VAR b, intercept: Scalar; VAR e: Vector);
VAR X: Matrix; B: Vector;
BEGIN
	(*can be simplified*)
	NEW(X, LEN(x,0), 2); 
	X[..,0]:=1;
	X[..,1]:=x;
	LinearRegression(X,y,B,e);
	intercept:=B[0];
	b:=B[1];
END SimpleRegressionIntercept;

(**
The general linear model (GLM) is a statistical linear model. It may be written as
    Y = XB + U
where Y is a matrix with series of multivariate measurements, 
X is a matrix that might be a design matrix, 
B is a matrix containing parameters that are usually to be estimated and 
U is a matrix containing errors or noise. 

The general linear model incorporates a number of different statistical models: 
ANOVA, ANCOVA, MANOVA, MANCOVA, ordinary linear regression, t-test and F-test. 
The general linear model is a generalization of multiple linear regression model to 
the case of more than one dependent variable.

see http://en.wikipedia.org/wiki/General_linear_model
*)

PROCEDURE GeneralLinearModel*(CONST X: Matrix; CONST Y: Matrix; VAR B, U: Matrix); (** not exhaustively tested *)
	VAR qr: MatrixLeastSquares.LeastSquaresQR;
		y, b,e: Vector; i:LONGINT;
BEGIN
	NEW(qr, X); 
	NEW(B, LEN(X,1), LEN(Y,1));
	NEW(U, LEN(Y,0), LEN(Y,1));
	FOR i:=0 TO LEN(Y,1)-1 DO
		y:=Y[..,i];
		b:=qr.Solve(y);
		e:= y- X*b;
		B[..,i]:=b;
		U[..,i]:=e;
	END;
END GeneralLinearModel;

(*
PROCEDURE SignificanceSimpleRegression(CONST b: Scalar; CONST e: Vector; VAR t,F, SEE, SEb: Scalar);
BEGIN
	SEE:= MathL.sqrt((1-b*b)*((N-2)/(N-1)));
	SEb:= SEE/(Sx*MathL.sqrt(N-1));
	t := b / SEE;
	F := t*t;
END Significance;
*)

(**The Theil-Sen estimator is a simple robust estimation technique that choose the slope of the fit line 
to be the median of the slopes of the lines through pairs of sample points. 
It has similar statistical efficiency properties to simple linear regression but is much less sensitive to outliers.*)
PROCEDURE Sort(VAR v:Vector);
BEGIN
	ExtraSort.QuickSortLR(v);
END Sort;

(* 
The Theil-Sen estimator is a simple robust estimation technique that determine the slope of a dataset 
as the median of the slopes of the lines through pairs of sample points. 
It has similar statistical efficiency properties to simple regression but is much less sensitive to outliers.
**)
PROCEDURE TheilSenEstimator*(CONST x: Vector; CONST y: Vector; VAR b, intercept: Scalar; VAR e: Vector); 
VAR slopes: Vector; i,len:LONGINT; dx, dy: Scalar;
BEGIN
	(*choose an arbitrary number of arbitrary pairs; here the extremal point pairs are used. Random pairs could also be used *)	
	len:=MIN (50, LEN(x,0) DIV 2);
	NEW(slopes, len);
	FOR i:=0 TO len-1 DO
		dx:=x[LEN(x,0)-1-i]-x[i];
		dy:=y[LEN(x,0)-1-i]-y[i];
		IF dx#0 THEN 
			slopes[i]:=dy/dx 
		END; (* dx=0 not yet handled properly, but has usually only  a minor impact *)
	END;
	Sort(slopes);
	b:=slopes[len DIV 2];
	e:=y-b*x;
	intercept:=SUM(e)/LEN(x,0);
	e:=e-intercept;
END TheilSenEstimator;

PROCEDURE Test*;
VAR X: Matrix; x, y, B,e: Vector; b, intercept: Scalar;
BEGIN
	y:=[1.0,2.1,2.9, 4.1, 5.0, 5.9]+2; (*note the intercept*)

	w.String("Simple Regression: regression coefficient, error vector, sum of square errors"); w.Ln; w.Update;
	x:=[1.0,2,3,4,5,6];
	SimpleRegression(x,y,b,e);
	w.FloatFix(b, 4, 10, 0); w.Ln; w.Update;
	Util.OutVector(e);
	w.FloatFix(e+*e, 4, 10, 0); w.Ln; w.Ln; w.Update;	

	w.String("Simple Regression with intercept: regression coefficient, intercept, error vector, sum of square errors"); w.Ln; w.Update;
	x:=[1.0,2,3,4,5,6];
	SimpleRegressionIntercept(x,y,b,intercept, e);
	w.FloatFix(b, 4, 10, 0); w.FloatFix(intercept, 4, 10, 0); w.Ln; w.Update;
	Util.OutVector(e);
	w.FloatFix(e+*e, 4, 10, 0); w.Ln; w.Ln; w.Update;	

	w.String("Linear Regression"); w.Ln; w.Update;
	X:=[[1.0,1.1],[2,1.9],[3,2.8],[4,4.1],[5,5.3],[6,5.8]];
	LinearRegression(X,y,B,e);
	Util.OutVector(B);
	Util.OutVector(e);
	w.FloatFix(e+*e, 4, 10, 0); w.Ln; w.Ln; w.Update;
	
	w.String("Linear Regression with intercept"); w.Ln; w.Update;
	X:=[[1.0,1.1],[1.0,1.9],[1,2.8],[1,4.1],[1,5.3],[1,5.8]];
	LinearRegression(X,y,B,e);
	Util.OutVector(B);
	Util.OutVector(e);
	w.FloatFix(e+*e, 4, 10, 0); w.Ln; w.Ln; w.Update;
	
	w.String("Theil Sen Estimator: robust slope"); w.Ln; w.Update;
	x:=[1.0,2,3,4,5,6];
	TheilSenEstimator(x,y,b,intercept, e);
	w.FloatFix(b, 4, 10, 0); w.FloatFix(intercept, 4, 10, 0); w.Ln;w.Update;
	Util.OutVector(e);
	w.FloatFix(e+*e, 4, 10, 0); w.Ln; w.Update;	
END Test;

PROCEDURE TestGLM*;
VAR X,Y, B,U: Matrix;
BEGIN
	Y:=[[1.0,10],[2.1,21],[2.9,29],[ 4.1,41], [5.0,50], [5.9,59]]; (* dependent variables/measurements *)
	X:=[[1.0,1.1],[2,1.9],[3,2.8],[4,4.1],[5,5.3],[6,5.8]]; (* *)
	GeneralLinearModel(X,Y,B,U);
	w.String("General Linear Model: B, U, sum of squared error"); w.Ln; w.Update;
	Util.OutMatrix(B); w.Ln; w.Update; (* regression coefficients*)
	Util.OutMatrix(U); (* error matrix *)
	w.FloatFix(U+*U, 4, 10, 0); w.Ln; w.Ln; w.Update;
END TestGLM;

BEGIN
	Streams.OpenWriter(w, KernelLog.Send)
END StatisticsRegression.

StatisticsLinearRegression.Test~
StatisticsLinearRegression.TestGLM~
SystemTools.FreeDownTo StatisticsLinearRegression ~ 
