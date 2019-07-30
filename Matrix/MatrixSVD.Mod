MODULE MatrixSVD;   (** AUTHOR "Patrick Hunziker"; PURPOSE "Solves a linear system of equations using SVD."; *)  (*TO DO: sorting by magnitude of eigenvectors may have a problem; small matrices *)
(*Version: 12.3.2008*)

IMPORT Base := MatrixBase, Math := MathL,  (*Out  := AosOut, Oberon, *) MatrixUtilities;

CONST
	Tiny = 1.0D-10;  DefaultIterations = 30;

TYPE
	(** on initialization NEW(s,A) the matrix A of size m*n is subjected to the singular value decomposition A= u * w *  v ;     *)
	Real = Base.Datatype;  Vector* = Base.Vector;  Matrix* = Base.Matrix;  IntVector*=ARRAY [*] OF LONGINT;
	Solver* = OBJECT (Base.Solver);
	VAR u-, w-, vt-, tmp, tmp2: Matrix;   (**  result matrices; u is size m*n, w is size n*n; note that the algorithm returns the transpose  vT(size n*n) instead of v *)
		uSorted-,wSorted-,vtSorted-:Matrix;
		tv, tv2, tv3, tv4, tv5: Vector;
		isSorted-:BOOLEAN;
		threshold*: Real;   (** for level of accuracy; default = 1.0D-10*)
		iterations*: LONGINT;   (** for detection of non-convergence; default = 30*)
		zero, mag: Real;
		index-,null: IntVector; (* ordering of diagonal matrix w with descending magnitude *)

		PROCEDURE & Init*( CONST A: Matrix );
		BEGIN
			handleError := Base.HandleError;  res := Base.OK;  isSorted:=FALSE; index:=null;
			IF LEN( A ) = 0 THEN RETURN END;
			IF (LEN( u, 0 ) # LEN( A, 0 )) OR (LEN( u, 1 ) # LEN( A, 1 )) THEN NEW( u, LEN( A, 0 ), LEN( A, 1 ) );  END;
			u := A;  mag := MaxAbs( u );  u := u / mag;  zero := 0.0D0;  iterations := DefaultIterations;  threshold := Tiny;  decompose;  w := w * mag;
		END Init;

		PROCEDURE decompose;
		VAR m, n: SIZE;  rv1: Vector;  anorm, scale, c, f, g, h, s, x, y, z: Real;  i, its, j, jj, k, l, nm: SIZE;  flag: BOOLEAN;
		BEGIN
			isSorted:=FALSE;
			IF LEN( u ) = 0 THEN res := Base.SIZEMISMATCH;  handleError( Base.SIZEMISMATCH, "An zero size matrix was supplied." );  RETURN END;
			n := LEN( u, 1 );  m := LEN( u, 0 );
			IF LEN( rv1 ) # n THEN NEW( rv1, n ) ELSE rv1 := 0 END;
			IF (LEN( w, 0 ) # n) OR (LEN( w, 1 ) # n) THEN NEW( w, n, n ) ELSE w := 0 END;
			IF (LEN( vt, 0 ) # n) OR (LEN( vt, 1 ) # n) THEN NEW( vt, n, n ) ELSE vt := 0 END;
			g := 0;  scale := 0;  anorm := 0;
			FOR i := 0 TO n - 1 DO
				l := i + 1;  rv1[i] := scale * g;  g := 0;  s := 0;  scale := 0.0;
				IF (i < m) THEN
				(*scale := SUM(ABS(u[i..m-1,i]));*)  (* overhead: allocation of temp array behind the scenes*)
					scale := MatrixUtilities.SumAbs( u[i..m - 1, i] );
					IF (scale # 0.0) THEN
						u[i..m - 1, i] := u[i..m - 1, i] / scale;  s := s + u[i..m - 1, i] +* u[i..m - 1, i];  f := u[i, i];
						IF f >= 0 THEN g := -Math.sqrt( s ) ELSE g := Math.sqrt( s ) END;
						h := f * g - s;  u[i, i] := (f - g);
						FOR j := l TO n - 1 DO
							s := u[i..m - 1, i] +* u[i..m - 1, j];
							f := s / h;
							tv3 := f * u[i..m - 1, i];
							u[i..m - 1, j] := u[i..m - 1, j] + tv3 (*+ f*u[i..m-1,i]*)
						END;
						u[i..m - 1, i] := u[i..m - 1, i] * scale
					END
				END;
				w[i, i] := (scale * g);  g := 0;  s := 0;  scale := 0.0;
				IF (i < m) & (i # (n - 1)) THEN
				(*scale := SUM(ABS( u[i, l..n-1]) );*)  (* overhead: allocation of temp array behind the scenes*)
					scale := MatrixUtilities.SumAbs( u[i, l..n - 1] );
					IF (scale # 0.0) THEN
						u[i, l..n - 1] := u[i, l..n - 1] / scale;  s := s + u[i, l..n - 1] +* u[i, l..n - 1];  f := u[i, l];
						IF f >= 0 THEN g := -Math.sqrt( s ) ELSE g := Math.sqrt( s ) END;
						h := f * g - s;  u[i, l] := (f - g);  rv1[l..n - 1] := u[i, l..n - 1] / h;
						FOR j := l TO m - 1 DO
							s := u[j, l..n - 1] +* u[i, l..n - 1];
							tv4 := s * rv1[l..n - 1];
							u[j, l..n - 1] := u[j, l..n - 1] + tv4;   (*+ s*rv1[l..n-1] ) *)
						END;
						u[i, l..n - 1] := (u[i, l..n - 1] * scale)
					END;
				END;
				anorm := Max( anorm, ABS( w[i, i] ) + ABS( rv1[i] ) )
			END;
			FOR i := n - 1 TO 0 BY -1 DO
				IF (i < (n - 1)) THEN
					IF g # 0.0 THEN
						vt[l..n - 1, i] := (u[i, l..n - 1] / (u[i, l] * g));
						FOR j := l TO n - 1 DO
							s := u[i, l..n - 1] +* vt[l..n - 1, j];
							IF s # 0 THEN tv4 := s * vt[l..n - 1, i];  vt[l..n - 1, j] := vt[l..n - 1, j] + tv4;   (*+ s*vt[l..n-1, i]) *) ;  END;
						END;
					END;
					vt[i, l..n - 1] := zero;  vt[l..n - 1, i] := zero;
				END;
				vt[i, i] := (1.0);  g := rv1[i];  l := i;
			END;
			FOR i := MinI( m, n ) - 1 TO 0 BY -1 DO
				l := i + 1;  g := w[i, i];
				u[i, l..n - 1] := zero;
				(*FOR j := l TO n - 1 DO u[i, j] := zero  END;  *)
				IF (g # 0.0) THEN
					g := 1.0 / g;
					FOR j := l TO n - 1 DO
						s := 0.0;
						FOR k := l TO m - 1 DO s := s + u[k, i] * u[k, j] END;
						f := s * g / u[i, i];
						IF f # 0 THEN
							tv4 := f * u[i..m - 1, i];
							u[i..m - 1, j] := u[i..m - 1, j] + tv4;   (*+ f*u[i..m-1, i]) *)
						END;
					END;
					u[i..m - 1, i] := (u[i..m - 1, i] * g)
				ELSE u[i..m - 1, i] := zero
				END;
				u[i, i] := (u[i, i] + 1.0);
			END;
			FOR k := n - 1 TO 0 BY -1 DO
				its := 0;
				LOOP
					INC( its );
					IF its > iterations THEN EXIT END;
					flag := TRUE;  l := k;
					LOOP
						nm := l - 1;
						IF ABS( rv1[l] ) + anorm = anorm THEN flag := FALSE;  EXIT
						ELSIF ABS( w[nm, nm] ) + anorm = anorm THEN EXIT
						END;
						DEC( l );
						IF l < 0 THEN EXIT END;
					END;
					IF flag THEN
						c := 0.0;  s := 1.0;  i := l;
						LOOP
							f := s * rv1[i];  rv1[i] := rv1[i] * c;
							IF ABS( f ) + anorm = anorm THEN EXIT END;
							g := w[i, i];  h := pythag( f, g );  w[i, i] := (h);  h := 1.0 / h;  c := g * h;  s := -f * h;

							FOR j := 0 TO m - 1 DO y := u[j, nm];  z := u[j, i];  u[j, nm] := (y * c + z * s);  u[j, i] := (z * c - y * s);  END;
							(*  u[0..m-1, nm] := u[0..m-1, nm] *c + u[0..m-1, i] * s;  (*wait for compiler compatibility of [[c,s],[c,-s]] *)
									u[0..m-1, i] := u[0..m-1, i]*c - u[0..m-1, nm] * s; (*not independent, not vectorizable ? but maybe vectorizable ...*)
									*)
							IF i = k THEN EXIT END;
							INC( i )
						END;
					END;
					z := w[k, k];
					IF (l = k) THEN
						IF (z < 0.0) THEN w[k, k] := (-z);  vt[.. n - 1, k] := (-vt[.. n - 1, k]);  END;
						EXIT;
					END;
					IF (its = iterations) THEN
						res := Base.NONCONVERGENCE;  handleError( Base.NONCONVERGENCE, "Singular value decomposition iterations do not converge" );  u := 0;  w := 0;  vt := 0;
						RETURN;
					END;
					x := w[l, l];  nm := k - 1;  y := w[nm, nm];  g := rv1[nm];  h := rv1[k];  f := ((y - z) * (y + z) + (g - h) * (g + h)) / (2.0 * h * y);  g := pythag( f, zero + 1 );
					f := ((x - z) * (x + z) + h * ((y / (f + sign( f ) * ABS( g ))) - h)) / x;  c := 1.0;  s := 1.0;
					FOR j := l TO nm DO
						i := j + 1;  g := rv1[i];  y := w[i, i];  h := s * g;  g := c * g;  z := pythag( f, h );
						rv1[j] := z;  c := f / z;  s := h / z;  f := x * c + g * s;  g := g * c - x * s;  h := y * s;  y := y * c;
						FOR jj := 0 TO n - 1 DO x := vt[jj, j];  z := vt[jj, i];  vt[jj, j] := (x * c + z * s);  vt[jj, i] := (z * c - x * s);  END;
						(*  vt[..n-1, j] := ( vt[..n-1, j]*c + vt[..n-1, i]*s);  (*wait for compiler compatibility of [[c,s],[c,-s]] *)
								vt[..n-1, i] := (  vt[..n-1, i]*c - vt[..n-1, j]*s); (*not independent, not vectorizable ? rather not*)
								*)
						z := pythag( f, h );  w[j, j] := (z);
						IF (z # 0.0) THEN z := 1.0 / z;  c := f * z;  s := h * z;  END;
						f := c * g + s * y;  x := c * y - s * g;
						FOR jj := 0 TO m - 1 DO y := u[jj, j];  z := u[jj, i];  u[jj, j] := (y * c + z * s);  u[jj, i] := (z * c - y * s);  END;
						(*  u[..m-1, j] := (  u[..m-1, j]*c + u[..m-1, i]*s);  (*wait for compiler compatibility of [[c,s],[c,-s]] *)
								u[..m-1, i] := (  u[..m-1, i]*c - u[..m-1, j]*s);  (*not independent, not vectorizable ? rather not*)
								*)
					END;
					rv1[l] := 0.0;  rv1[k] := f;  w[k, k] := (x);
				END
			END;
			RETURN;
		END decompose;

		PROCEDURE Solve*( CONST b: Vector ): Vector;
		VAR val: LONGREAL;  i: SIZE;
		BEGIN
			IF (LEN( tmp, 0 ) # LEN( w, 0 )) OR (LEN( tmp, 1 ) # LEN( w, 1 )) THEN NEW( tmp, LEN( w, 0 ), LEN( w, 1 ) );  ELSE tmp := 0 END;
			IF LEN( tv ) # LEN( u, 0 ) THEN NEW( tv, LEN( u, 0 ) ) ELSE tv := 0 END;
			IF LEN( tv2 ) # LEN( u, 0 ) THEN NEW( tv2, LEN( u, 0 ) ) ELSE tv2 := 0 END;
			FOR i := 0 TO LEN( w,0 ) - 1 DO
				val := w[i, i];
				IF ABS( val ) < Tiny THEN tmp[i, i] := 0 ELSE tmp[i, i] := 1 / val END;
			END;
			tv := u` * b;  tv2 := tmp * tv;  RETURN vt * tv2
		END Solve;

		PROCEDURE SortDescending*;
		VAR sorted:Vector;
		BEGIN
			index:=null;
			MatrixUtilities.GetDiagonalOrder(w, sorted,index,FALSE);
			wSorted:=MatrixUtilities.ReorderMatrix(w,index, FALSE); (* reorder diagonal matrix w in columns and rows*)
			wSorted:=MatrixUtilities.ReorderMatrix(wSorted, index,TRUE);
			uSorted:=MatrixUtilities.ReorderMatrix(u,index, FALSE); (* reorder u by columns*)
			vtSorted:=MatrixUtilities.ReorderMatrix(vt, index, FALSE); (* reorder v by rows (i.e. reorder vt by columns)*)
			isSorted:=TRUE;
		END SortDescending;


		PROCEDURE PseudoInverse*( ): Matrix;
		VAR val: LONGREAL;  i: SIZE;
		BEGIN
			IF (LEN( tmp, 0 ) # LEN( w, 0 )) OR (LEN( tmp, 1 ) # LEN( w, 1 )) THEN NEW( tmp, LEN( w, 0 ), LEN( w, 1 ) );  ELSE tmp := 0 END;
			tmp2 := 0;
			FOR i := 0 TO LEN( w,0 ) - 1 DO
				val := w[i, i];
				IF ABS( val ) < Tiny THEN tmp[i, i] := 0 ELSE tmp[i, i] := 1 / val END;
			END;
			tmp2 := tmp * (u`);  RETURN vt * tmp2;
		END PseudoInverse;

	END Solver;

	PROCEDURE All( VAR M: Matrix;  f: PROCEDURE ( x: LONGREAL ): LONGREAL ): Matrix;
	VAR i, j: SIZE;
	BEGIN
		FOR i := 0 TO LEN( M, 0 ) - 1 DO
			FOR j := 0 TO LEN( M, 1 ) - 1 DO M[i, j] := f( M[i, j] );  END;
		END;
		RETURN M
	END All;

	PROCEDURE reciprocal( x: Real ): Real;
	BEGIN
		IF ABS( x ) < Tiny THEN x := 0.0D0 ELSE x := 1.0D0 / x END;
		IF ABS( x ) < Tiny THEN x := 0.0D0 END;
		RETURN x
	END reciprocal;

(******************************************************************)

	PROCEDURE pythag( a, b: Real ): Real;
	VAR absa, absb, zero: Real;
	BEGIN
		zero := 0;  absa := ABS( a );  absb := ABS( b );
		IF absa > absb THEN RETURN absa * Math.sqrt( 1.0 + absb / absa * absb / absa );
		ELSIF absb = 0 THEN RETURN zero
		ELSE RETURN absb * Math.sqrt( 1.0 + absa / absb * absa / absb )
		END;
	END pythag;

	PROCEDURE Max( x, y: Real ): Real;
	BEGIN
		IF x > y THEN RETURN x ELSE RETURN y END;
	END Max;

	PROCEDURE MaxAbs( CONST m: Matrix ): Real;
	BEGIN
		RETURN MAX( MAX( m ), -MIN( m ) );   (*non-copying ABS(MAX(m))*)
	END MaxAbs;

	PROCEDURE MinI( i, j: SIZE ): SIZE;
	BEGIN
		IF i < j THEN RETURN i ELSE RETURN j;  END;
	END MinI;

	PROCEDURE sign( x: Real ): LONGINT;
	BEGIN
		IF x >= 0 THEN RETURN 1 ELSE RETURN -1 END;
	END sign;

	(* 2*2 SVD:
	analytic solution: see http://en.wikipedia.org/wiki/Singular_value_decomposition :
	"Analytic solution"
	*)

	(* 3*3 SVD for simd: see http://pages.cs.wisc.edu/~sifakis/papers/SVD_TR1690.pdf *)

	(* 2*2 SVD
	/// See http://metamerist.blogspot.com/2006/10/linear-algebra-for-graphics-geeks-svd.html

(*! do to: speed up by inlining *)

PROCEDURE SVD_AbsScaleOnly(CONST in: Matrix2x2): Vector2;
BEGIN
	Q:= in +* in;
	R:= in[0,0] * in[1,1] - in[0,1] * in[1,0]; (*R:=Determinant(in);*)
	discriminant:=Mathe.sqrt(Q*Q-4*R*R );
	RETURN [Mathe.sqrt(Q+discriminant), Mathe.sqrt(Q-discriminant)]
END SVD_AbsScaleOnly;

PROCEDURE SVD_EigenvectorGivenEigenvalue(CONST in: Matrix2x2; CONST eigenvalue: Vector2);
VAR M00,M01: Datatype; Numerator,Denominator,Fraction: ARRAY [2] OF Datatype;
BEGIN
	M00:= in[0] +* in[0];
	M01:= in[0] +* in[1];
	Numerator:=[M01,M01];
	Denominator:=eigenvalue.*eigenvalue - [M00,M00];
	Fraction:= Numerator ./ Denominator;
	eigenMatrix:= [normalize(Fraction[0],1), normalize(Fraction[1],1)];
	RETURN eigenMatrix`
END SVD_EigenvectorGivenEigenvalue;

PROCEDURE SVD_Decompose(in: Matrix2x2);
VAR E, U,V: Matrix2x2; scale: Vector2;
BEGIN
	scale:=SVD_AbsScaleOnly(in);
	U := SVD_EigenvectorGivenEigenvalue(in,scale);
	E:=[[reciprocal(scale[0]), 0],[0, reciprocal(scale[1])]];
	V := E * ( U`* in);
END SVD_Decompose;
*)

(*
	PROCEDURE LogV( CONST m: Vector );
	VAR i, j: LONGINT;
	BEGIN
		IF LEN(m)=0 THEN Out.String("zero size matrix"); Out.Ln; RETURN; END;
			FOR i := 0 TO LEN(m) - 1 DO
				IF m[i]<0 THEN Out.Char("-"); END; Out.Int(ENTIER(ABS(m[i]+0.005)),0); Out.Char("."); Out.Int(ENTIER(ABS(m[i]*100+0.5)) MOD 100,0); Out.String("   ");
			END;
			Out.Ln;
	END LogV;


	PROCEDURE Log( CONST m: Matrix );
	VAR i, j: LONGINT;
	BEGIN
		IF LEN(m)=0 THEN Out.String("zero size matrix"); Out.Ln; RETURN; END;
		FOR j := 0 TO LEN(m,0) - 1 DO
			FOR i := 0 TO LEN(m,1) - 1 DO
				IF m[j,i]<0 THEN Out.Char("-"); END; Out.Int(ENTIER(ABS(m[j,i]+0.005)),0); Out.Char("."); Out.Int(ENTIER(ABS(m[j,i]*100+0.5)) MOD 100,0); Out.String("   ");
			END;
			Out.Ln;
		END;
		Out.Ln;
	END Log;

	PROCEDURE Test*;
	VAR a, U, W, V, VT: Matrix;  b,x: Vector; scale, zero: Real;  s: Solver;  i,t0,t1:LONGINT;
	BEGIN
		Out.Enter;
		Out.Ln;  Out.String( "-------Singular Value Decomposition Test-------------" );
		Out.String( " Singular Value Decomposition of Matrix A; " );  Out.Ln;
		Out.String( " should yield eigenvalues w (in diagonal matrix) and " );  Out.Ln;
		Out.String( " orthonormal matrices u & vT which, " );  Out.Ln;
		Out.String( " multiplied by itself, should give unit matrices; " );  Out.Ln;
		Out.String( " Finally, PseudoInverse of A is calculated, " );  Out.Ln;
		Out.String( " and Pseudoinverse of Pseudoinverse should lead back to A (least square approximation of..) " );  Out.Ln;
		Out.Exit;

		NEW( a, 8, 10 );

		(*arbitrary matrix fill *)
		zero := 0;   (* hack to initialize matrix easier *)
		a[ 0, 0] := zero + 1 ;  a[ 1, 0] := zero + 2 ;   (* ' type casting', not very elegant *)
		a[ 3, 0] := zero + 3 ;  a[ 0, 2] := zero + 2 ;  a[ 2, 1] := zero + 3 ;  a[ 3, 1] := zero + 2 ;
		a[ 3, 4] := zero + 4 ;


		NEW( s, a );		(* at this point, solver is initialized with matrix m and SVD already performed in the background *)
		t0:=Oberon.Time();
		FOR i:=0 TO 10000 DO
			s.Init(a );   (* at this point, solver is initialized with matrix m and SVD already performed in the background *)
		END;
		t1:=Oberon.Time();
		Out.Enter;

		Out.String("time [ms]: "); Out.Int (t1-t0,0); Out.Ln;


		b:=[1,5,4,8,7,3,4,7,0,4,3,2,6,7,8];

		t0:=Oberon.Time();
		FOR i:=0 TO 10000 * 100 DO
			scale := SUM(ABS(b));
		END;
		t1:=Oberon.Time();
		Out.String("SUM(ABS()) versus MatrixUtilities.SumAbs() "); Out.String("time [ms]: "); Out.Int (t1-t0,0);

		t0:=Oberon.Time();
		FOR i:=0 TO 10000* 100 DO
			scale := MatrixUtilities.SumAbs(b);
		END;
		t1:=Oberon.Time();
		Out.String("  time [ms]: "); Out.Int (t1-t0,0); Out.Ln;

		Out.String( "a:" );  Out.Ln;  Log( a );  Out.String( "w:" );  Out.Ln;  Log( s.w );

		Out.String( "v,vt,v*vt:" );  Out.Ln;
		Log( s.vt );  (*V := s.vt`;*)  Log( s.vt` );  (*V := s.vt*V;*)  Log( s.vt*(s.vt`) );  Out.String( "u,ut,u*ut:" );  Out.Ln;
		Log( s.u );  (*U := s.u`;*)  Log( s.u` );  (*U := s.u*U;*)  Log( s.u * (s.u`) );  Out.String( "u*w*v:" );  Out.Ln;
		Log( s.u * (s.w*(s.vt`)) );
		Out.Exit;


		(*
		Out.String( "a, PseudoInverse(a):" );  Out.Ln;
		Log( a );
		Log ( s.vt * ALL(s.w,reciprocal) * (s.u`) );
		s.Initialize ( s.vt * ALL(s.w,reciprocal) * (s.u`) );
		Out.String( "PseudoInverse(PseudoInverse(a)):" );  Out.Ln;
		Log ( s.vt * ALL(s.w,reciprocal) * (s.u`) );
		*)
		Out.Enter;
		Out.String( "a, PseudoInverse(a), PseudoInverse(PseudoInverse(a)):" );  Out.Ln;  Log( a );
		Log( s.PseudoInverse() );  s.Init( s.PseudoInverse() );  Log( s.PseudoInverse() );
		Out.Exit;

		(*SVD as solver*)
		NEW( a, 5, 5 );
		NEW(x,5);
		(*arbitrary matrix fill *)
		zero := 0;   (* hack to initialize matrix easier *)
		a[ 0, 0] := zero + 5.1 ; a[ 0, 1] := zero + 4.1 ; a[ 0, 3] := zero + 5.3 ;  a[ 0, 4] := zero + 2 ;
		a[ 1, 1] := zero + 4.2 ; a[ 2, 2] := zero + 2.5 ;
		a[ 1, 0] := zero + 2.3 ; a[ 2, 0] := zero + 5.3 ; a[ 4, 0] := zero + 2 ;  (* ' type casting', not very elegant *)
		a[ 3, 0] := zero + 3.4 ;  a[ 0, 2] := zero + 2.2 ;  a[ 2, 1] := zero + 3 ; a[ 1, 3] := zero + 3 ; a[ 3, 1] := zero + 2 ;
		a[ 2, 3] := zero + 3.6 ; a[ 3, 2] := zero + 2.1 ;
		a[3,3]:= zero+1; a[4,2]:= zero+4; a[4,3]:= zero+2; a[ 3, 4] := zero + 4 ;   a[ 4, 4] := zero + 1 ;

		b:=[5,4,3,1,4];

		Out.Enter;
		Out.String( "A, b, x, A*x:" );  Out.Ln;  Log( a );
		LogV( b);    Out.Ln;
		s.Init(a);
		x:=s.Solve(b);
		LogV(x);  Out.Ln;
		LogV(a*x);Out.Ln;
		Out.Exit;



	END Test;
*)

BEGIN
END MatrixSVD.
System.Time ~
MatrixSVD.Test
LinEqSVD.Test

SystemTools.FreeDownTo MatrixSVD  ~

OFormatter.Format *
fofPC.Compile \s *
fofPC.Compile \f *

History:
-on Aug 9, 2006 (no SIMD yet) the fofPC.Compiled MatrixSVD.Mod runs somewhat faster than the PC.Compiled LinEqSVD.Mod
-most inner loops can be parallelized.
-in contrast, MatrixSVD.Mod produces more object code (12668 versus 8004 Bytes);
-some translation problems are shown in red above.

- on Oct, 2006, this module (no SIMD yet) runs about twice as fast as PC compiled LinEqSVD.Mod
- on March 2008, with SIMD in compiler, 4x faster than LinEqSVD.Mod
