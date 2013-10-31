MODULE PlanarEdgeDetectors; (** AUTHOR "Patrick Hunziker"; PURPOSE " various edge detectors"; **)

(* see also http://en.wikipedia.org/wiki/Scale_space and http://en.wikipedia.org/wiki/Edge_detection*)

IMPORT PlanarBase, PlanarNabla, PlanarMath, Mathe:=MathL, WMMatrix;

TYPE 
	Datatype=PlanarBase.Datatype;
	Line=PlanarBase.OneD;
	ScalarField*=PlanarNabla.ScalarField;
	VectorField*=PlanarNabla.VectorField;

(* nabla-based edge detector. For choice of 'sampling' parameters, see PlanarNabla.Mod *)
PROCEDURE DifferentialEdgeMagnitude*(CONST p:ScalarField; sampling: LONGINT):ScalarField;
BEGIN
	RETURN PlanarMath.Sqrt(PlanarMath.Sqr(PlanarNabla.dx(p,sampling)) + PlanarMath.Sqr(PlanarNabla.dy(p,sampling)));
END DifferentialEdgeMagnitude;

PROCEDURE DifferentialEdgeDirection*(CONST p:ScalarField; sampling:LONGINT):VectorField;
BEGIN
	RETURN PlanarNabla.Grad(p, sampling);
END DifferentialEdgeDirection;

PROCEDURE arctan2(x,y:LONGREAL):LONGREAL; (*arctan in range 0..2pi*)
BEGIN
	IF (x>0) & (y>=0) THEN RETURN Mathe.arctan(y/x)
	ELSIF (x>0) & (y<0) THEN RETURN Mathe.arctan(y/x)+2*Mathe.pi
	ELSIF x<0 THEN RETURN Mathe.arctan(y/x)+Mathe.pi
	ELSIF (x=0) & (y>0) THEN RETURN Mathe.pi/2
	ELSIF (x=0) & (y<0) THEN RETURN 3*Mathe.pi/2
	ELSE (*( x=0) & (y=0) *) RETURN 0 (*or RETURN NaN ?*) 
	END
END arctan2;

PROCEDURE DifferentialEdgeAngle*(CONST p:ScalarField; sampling:LONGINT):ScalarField; (*! needs speedup*)
VAR vec:VectorField; x,y:LONGINT;
BEGIN
	vec:=DifferentialEdgeDirection(p, sampling);
	IF LEN(RESULT,0)=0 THEN NEW(RESULT, LEN(p,0), LEN(p,1)) END;
	FOR y:=0 TO LEN(p,0)-1 DO
		FOR x:=0 TO LEN(p,1)-1 DO
			RESULT[y,x]:=arctan2(vec.x[y,x], vec.y[y,x]);
		END;
	END;
	RETURN RESULT
END DifferentialEdgeAngle;

(*Canny Edge Detector, with or without non-maximum suppression. Based on Code from TrueColorSnakes. In noisy data, needs pre-smoothing for best result *)
PROCEDURE Canny* (CONST in: ScalarField; NonMaxSuppression:BOOLEAN): ScalarField;
VAR line: Line;
	lines:ARRAY [*] OF Line;
	i,j,j2,i1,i2,iM1,iM2,h,hM2,hM1,h1,h2,dir, width, height: LONGINT;
	d1,deriv, pix: Datatype;
	InvSqrt2: Datatype;
	nil: ScalarField;
BEGIN
	InvSqrt2:=1/Mathe.sqrt(2);
	width:=LEN(in,1); height:=LEN(in,0);
	IF height=0  THEN RETURN nil END;
	IF LEN(RESULT,0)=0 THEN NEW(RESULT, LEN(in,0), LEN(in,1)); END;
	NEW(line, LEN(in,1)); 
	NEW(lines, 5, LEN(in,1));
	lines[0..2]:=in[0..2];
	lines[3]:= in[0];
	lines[4]:=in[0];
	h:=0;
	FOR j:=0 TO LEN(RESULT,0)-1 DO
		hM2:=(h-2) MOD 5; 
		hM1:=(h-1) MOD 5;
		h1:=(h+1) MOD 5; 
		h2:=(h+2) MOD 5;
		FOR i:=0 TO LEN(in,1)-1 DO
			iM1:=(i-1) MOD width; 
			i1:=(i+1) MOD width;
			iM2:=(i-2) MOD width; 
			i2:=(i+2) MOD width;
			deriv:=ABS(lines[h,i1]-lines[h,iM1]); dir:=0;
			d1:=ABS(lines[h1,i1]-lines[hM1,iM1]); 
			IF InvSqrt2*d1>deriv THEN deriv:=SHORT(ENTIER(InvSqrt2*d1)); dir:=1 END;
			d1:=ABS(lines[h1,i]-lines[hM1,i]); 
			IF d1>deriv THEN deriv:=d1; dir:=2 END;
			d1:=ABS(lines[h1,iM1]-lines[hM1,i1]); 
			IF InvSqrt2*d1>deriv THEN deriv:=SHORT(ENTIER(InvSqrt2*d1)); dir:=3 END;
			line[i]:=deriv;
			(*
			IF deriv>255 THEN line[i]:=255 (* 8 bit case *)
			ELSIF deriv<0 THEN line[i]:=0
			ELSE line[i]:=deriv
			END;
			*)
			IF NonMaxSuppression THEN 
				pix:=lines[h,i];
				CASE dir OF
					0: IF (ABS(lines[h,i2]-pix)>deriv) OR (ABS(lines[h,iM2]-pix)>deriv) THEN line[i]:=0 END;
					|1:IF (ABS(lines[h2,i2]-pix)>deriv) OR (ABS(lines[hM2,iM2]-pix)>deriv) THEN line[i]:=0 END;	
					|2:IF (ABS(lines[h2,i]-pix)>deriv) OR (ABS(lines[hM2,i]-pix)>deriv) THEN line[i]:=0 END;
					|3:IF (ABS(lines[h2,iM2]-pix)>deriv) OR (ABS(lines[hM2,i2]-pix)>deriv) THEN line[i]:=0 END;	
				END;
			END;
		END;
		RESULT[j]:=line;
		h:=(h+1) MOD 5;
		j2:=j+2;
		IF j2>=height THEN j2:=height-1 END;
		lines[(h+2) MOD 5]:= in[j2];
	END;
	RETURN RESULT
END Canny;

PROCEDURE Test*;
VAR rect: ScalarField; vec: VectorField; window: WMMatrix.Window;
BEGIN
	NEW(rect, 100, 100); 
	rect[45..55,..]:=1; 
	rect[..,45..56]:=1; 
	rect[..50, 41..59]:=0.2;
	rect[..50, 42..58]:=0.5;
	rect[..50, 43..57]:=0.9;
	rect[..50, 44..56]:=1.4;
	rect[..50, 45..55]:=2;
	rect[..50, 46..54]:=3.1;
	rect[..50, 47..53]:=4;
	rect[..50, 48..52]:=4.5;
	rect[..50, 49..51]:=5;
	rect[..50, 50]:=5.4;
	NEW(window, rect, "original"); window.AddWindow;
	
	NEW(window, Canny(rect, FALSE), "Canny, plain"); window.AddWindow;
	NEW(window, Canny(rect, TRUE), "Canny suppresing non-maxima"); window.AddWindow;
	NEW(window, DifferentialEdgeMagnitude(rect, PlanarNabla.centered), "differential edge magnitude"); window.AddWindow;
	
	vec:= DifferentialEdgeDirection(rect, PlanarNabla.centered);
	NEW(window, vec.x, "edge direction x"); window.AddWindow;
	NEW(window, vec.y, "edge direction y"); window.AddWindow;
END Test;


END PlanarEdgeDetectors.


PlanarEdgeDetectors.Test
