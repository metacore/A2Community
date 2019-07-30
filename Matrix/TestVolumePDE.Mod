MODULE TestVolumePDE;   (**  AUTHOR "Patrick Hunziker"; PURPOSE "Tests PDE computations for 3D";  **)

IMPORT VolumePDE, Out:=KernelLog, Utilities:=Strings, WMMatrix;

TYPE
	Datatype = VolumePDE.Datatype;
	Grid = VolumePDE.Grid;

	PROCEDURE outrealfix(x:LONGREAL);
	VAR s: ARRAY 64 OF CHAR;
	BEGIN
		Utilities.FloatToStr(x,6,3,0,s);
		Out.String(s);
	END outrealfix;

PROCEDURE TestDiffusion*;
	CONST size = 64;
	VAR d, p: Grid;  i: LONGINT;  nu: Datatype;
		D,P:WMMatrix.Window;
		diffusion: VolumePDE.Diffusion;
	BEGIN
		NEW( d, size, size, size );  d[..,..,20..30] := 1;  d[.. , 20..30] := 1;
		NEW( p, size, size, size);
		nu := 0.5;

		NEW(diffusion);
		FOR i := 0 TO 0 DO diffusion.SolveMultigrid( d, p, nu, 1,  1, 1, 16, 30, 10,  NIL );  END;

		NEW( D, d[25], "d" );  D.AddWindow;
		NEW( P, p[25], "p" );  P.AddWindow;
	END TestDiffusion;

PROCEDURE TestWave*;
	CONST size = 65;
	VAR d,dm1, p: Grid;  i: LONGINT;  c: Datatype;
		D,P:WMMatrix.Window;
		wave: VolumePDE.Wave;
	BEGIN
		NEW( dm1, size, size, size );  dm1[..,..,15..25] := 1;  dm1[.. , 15..25] := 1;
		NEW( d, size, size, size );  d[..,..,20..30] := 1;  d[.. , 20..30] := 1;
		NEW( p, size, size, size);
		c := 1;

		NEW(wave);
		NEW( D, d[25], "d" );  D.AddWindow;
		NEW( P, p[25], "p" );  P.AddWindow;
		FOR i := 0 TO 200 DO
			wave.SolveMultigrid( dm1,d, p, c, 1,  1, 1, 16, 30, 10,  NIL );
			P.SetImage( p[25]);
			dm1:=d; d:=p;
		END;
	END TestWave;

	PROCEDURE TestPoisson*;
	CONST size = 64;
	VAR d, p: Grid;  i: LONGINT;
		D,P:WMMatrix.Window;
		poisson: VolumePDE.Poisson;
	BEGIN
		NEW( d, size, size, size );  d[..,..,25..35] := 1;  d[.. , 25..35,..] := 1;
		NEW( p, size, size, size );
		NEW(poisson);
		FOR i := 0 TO 0 DO poisson.SolveMultigrid( d, p, 1, 1, 20, 10,4, NIL );  END;
		Out.String("Min,Max "); outrealfix(MIN(d)); outrealfix(MAX(d)); outrealfix(MIN(p)); outrealfix(MAX(p)); Out.Ln;
		NEW( D, d[30], "d" );  D.AddWindow;
		NEW( P, p[30], "p" );  P.AddWindow;
	END TestPoisson;

PROCEDURE TestAdvection*;
CONST size=64;
VAR d,u,v,w,p, p1: Grid; 	D,P:WMMatrix.Window;  i:LONGINT;
BEGIN
	NEW(d,size,size,size); (*original data*)
	NEW(u,size,size,size); NEW(v,size,size,size); NEW(w,size,size,size);  (*3D advection vector*)
	NEW(p,size,size,size);NEW(p1,size,size,size);
	d[25..35,25..35,25..35] := 1;
	u:=1; v:=-1; w:=1;
	p:=d;
	NEW( D, d[30], "d" );  D.AddWindow;
	NEW(P, p1[30],"p"); P.AddWindow;
	FOR i:=0 TO 7 DO
		VolumePDE.Advect(p,u,v,w,p1,1,1,TRUE);
		P.SetImage( p1[30]);
		p:=p1;
	END;
END TestAdvection;

END TestVolumePDE.


SystemTools.Free OFormatter TestVolumePDE PlanarNavierStokes VolumePDE PlanarDoppler PlanarNabla WMMatrix MatrixRaster MatrixPictures.Mod MatrixFigures PlanarTransform.Mod PlanarBase SignalConvolve MatrixAVI MatrixPictures~
OFormatter.Format *
fofPC.Compile \f *

TestVolumePDE.Test
TestVolumePDE.TestwSource
TestVolumePDE.TestAVI
TestVolumePDE.TestPoisson
TestVolumePDE.TestPoissonSource
TestVolumePDE.TestDiffusion
TestVolumePDE.TestWave
TestVolumePDE.TestAdvection

TestPlanarPDE.TestDiffusion

TestVolumePDE.TestTomography
