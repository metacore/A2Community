MODULE VolumeMorphology; (** AUTHOR "Patrick Hunziker, Dima Shulga"; PURPOSE "Mathematical Morphology operators in 3¦D"; *)

(** Mathematical Morphology operators, see wikipedia "Mathematical Morphology".
They work on either binary or floating point datasets, have concise interfaces and are suited for high performance,
by making use of suitable implementation features of MathArrays etcs.

Applications include edge detection with noise elimination.
*)

(* the 'simple' operator variants operate on voxel in 3*3* domain only.  
the other variants use an arbitrary structuring element. 
operation can be restricted to certain dimensions; the empty set parameter indicates all dimensions. (not yet implemented)
*)

IMPORT MatrixBase, WMStack, Commands, MatrixUtilities, Random;

TYPE BinaryVolume*=ARRAY [*,*,*] OF BOOLEAN;
TYPE Volume*=ARRAY [*,*,*] OF MatrixBase.Datatype;

VAR rand: Random.Generator;

(**
Number of nonzero elements in volume
*)	
PROCEDURE NNZ(s: BinaryVolume): LONGINT;
VAR
	k0,k1,k2,n: LONGINT;
BEGIN
	n := 0;
	FOR k0:=0 TO LEN(s,0)-1 DO
		FOR k1:=0 TO LEN(s,1)-1 DO
			FOR k2:=0 TO LEN(s,2)-1 DO
				IF s[k0,k1,k2] = TRUE THEN
					n := n + 1;
				END;	
			END;	
		END;	
	END;
	RETURN n;
END NNZ;

PROCEDURE BinarySimpleErosion*(CONST t:BinaryVolume; directions:SET):BinaryVolume;
VAR res:BinaryVolume;
BEGIN
	IF (DIM(res)=0) OR (LEN(res,0)=0) THEN NEW(res, LEN(t)) END;
	res[1.., ..,..]:= t[1.., ..,..] & t[..LEN(t,0)-2, ..,..]; 
	res[..LEN(res,0)-2, ..,..]:= res[..LEN(res,0)-2, ..,..] & res[1.., ..,..]; 
	res[.., 1.., ..]:= res[.., 1.., ..] & res[.., ..LEN(res,1)-2, ..]; 
	res[.., ..LEN(res,1)-2, ..]:= res[.., ..LEN(res,1)-2, ..] & res[.., 1.., ..]; 
	res[.., .., 1..]:= res[.., .., 1..] & res[.., .., ..LEN(res,2)-2]; 
	res[.., .., ..LEN(res,2)-2]:= res[.., .., ..LEN(res,2)-2] & res[.., .., 1..]; 
	RETURN res
END BinarySimpleErosion;



(**
	Erosion of 3D volume t with structuring element se. 
	Dima Shulga 2015
*)
PROCEDURE BinaryErosion*(CONST t,se:BinaryVolume):BinaryVolume;
VAR 
	e:BinaryVolume;
	k0,k1,k2,m0,m1,m2: LONGINT;
BEGIN
	NEW(e, LEN(t));
	m0 := LEN(se,0) DIV 2;
	m1 := LEN(se,1) DIV 2;
	m2 := LEN(se,2) DIV 2;
	FOR k0 := 0 TO LEN(t,0)-1 DO	
		FOR k1 := 0 TO LEN(t,1)-1 DO	
			FOR k2 := 0 TO LEN(t,2)-1 DO
				IF t[k0,k1,k2] = TRUE THEN
					IF NNZ( t[k0-m0..k0+m0, k1-m1..k1+m1, k2-m2..k2+m2] & se) = NNZ(se) THEN
						e[k0,k1,k2] := TRUE;				
					END;
				END;
			END;
		END;
	END;
	RETURN e;	
END BinaryErosion;


PROCEDURE SimpleErosion*(CONST t:Volume; directions:SET):Volume;
VAR res:Volume; len0, len1: ARRAY [*] OF LONGINT;
BEGIN
	IF (DIM(res)=0) OR (LEN(res,0)=0) THEN NEW(res, LEN(t)) END;
	len0:=LEN(t[1.., ..,..]);
	len1:=LEN(t[..LEN(t,0)-2, ..,..]);
	TRACE(LEN(t[1.., ..,..],0), LEN(t[1.., ..,..],1), LEN(t[1.., ..,..],2));
	TRACE(LEN(t[..LEN(t,0)-2, ..,..],0),LEN(t[..LEN(t,0)-2, ..,..],1),LEN(t[..LEN(t,0)-2, ..,..],2));
	res[1.., ..,..]:= MIN(t[1.., ..,..], t[..LEN(t,0)-2, ..,..]); 
	res[..LEN(res,0)-2, ..,..]:= MIN(res[..LEN(res,0)-2, ..,..], res[1.., ..,..]); 
	res[.., 1.., ..]:= MIN(res[.., 1.., ..], res[.., ..LEN(res,1)-2, ..]); 
	res[.., ..LEN(res,1)-2, ..]:= MIN(res[.., ..LEN(res,1)-2, ..], res[.., 1.., ..]); 
	res[.., .., 1..]:= MIN(res[.., .., 1..], res[.., .., ..LEN(res,2)-2]); 
	res[.., .., ..LEN(res,2)-2]:= MIN(res[.., .., ..LEN(res,2)-2], res[.., .., 1..]); 
	RETURN res
END SimpleErosion;

(*
PROCEDURE Erosion(CONST t:Volume; CONST structure:Volume):Volume;
BEGIN
END Erosion;
*)

PROCEDURE BinarySimpleDilation*(CONST t:BinaryVolume; directions:SET):BinaryVolume;
VAR res:BinaryVolume;
BEGIN
	IF (DIM(res)=0) OR (LEN(res,0)=0) THEN NEW(res, LEN(t)) END;
	res[1.., ..,..]:= t[1.., ..,..] OR t[..LEN(t,0)-2, ..,..]; 
	res[..LEN(res,0)-2, ..,..]:= res[..LEN(res,0)-2, ..,..] OR res[1.., ..,..]; 
	res[.., 1.., ..]:= res[.., 1.., ..] OR res[.., ..LEN(res,1)-2, ..]; 
	res[.., ..LEN(res,1)-2, ..]:= res[.., ..LEN(res,1)-2, ..] OR res[.., 1.., ..]; 
	res[.., .., 1..]:= res[.., .., 1..] OR res[.., .., ..LEN(res,2)-2]; 
	res[.., .., ..LEN(res,2)-2]:= res[.., .., ..LEN(res,2)-2] OR res[.., .., 1..]; 
	RETURN res
END BinarySimpleDilation;

(**
	Dilation of 3D volume t with structuring element se
*)
PROCEDURE BinaryDilation*(CONST t,se:BinaryVolume):BinaryVolume;
VAR 
	d:BinaryVolume;
	k0,k1,k2,m0,m1,m2: LONGINT;
BEGIN
	NEW(d, LEN(t));
	m0 := LEN(se,0) DIV 2;
	m1 := LEN(se,1) DIV 2;
	m2 := LEN(se,2) DIV 2;
	FOR k0 := 0 TO LEN(t,0)-1 DO	
		FOR k1 := 0 TO LEN(t,1)-1 DO	
			FOR k2 := 0 TO LEN(t,2)-1 DO
				IF t[k0,k1,k2] = TRUE THEN
					d[k0-m0..k0+m0, k1-m1..k1+m1, k2-m2..k2+m2] := d[k0-m0..k0+m0, k1-m1..k1+m1, k2-m2..k2+m2] OR se;
				END;
			END;
		END;
	END;
	RETURN d;	
END BinaryDilation;


PROCEDURE SimpleDilation*(CONST t:Volume; directions:SET):Volume;
VAR res:Volume;
BEGIN
	IF (DIM(res)=0) OR (LEN(res,0)=0) THEN NEW(res, LEN(t)) END;
	res[1.., ..,..]:= MAX(t[1.., ..,..], t[..LEN(t,0)-2, ..,..]); 
	res[..LEN(res,0)-2, ..,..]:= MAX(res[..LEN(res,0)-2, ..,..], res[1.., ..,..]); 
	res[.., 1.., ..]:= MAX(res[.., 1.., ..], res[.., ..LEN(res,1)-2, ..]); 
	res[.., ..LEN(res,1)-2, ..]:= MAX(res[.., ..LEN(res,1)-2, ..], res[.., 1.., ..]); 
	res[.., .., 1..]:= MAX(res[.., .., 1..], res[.., .., ..LEN(res,2)-2]); 
	res[.., .., ..LEN(res,2)-2]:= MAX(res[.., .., ..LEN(res,2)-2], res[.., .., 1..]); 
	RETURN res
END SimpleDilation;
(*
PROCEDURE Dilation(CONST t:Volume; CONST structure:Volume):Volume;
BEGIN
END Dilation;
*)
PROCEDURE BinarySimpleOpening*(CONST t:BinaryVolume; directions:SET):BinaryVolume;
BEGIN
	RETURN BinarySimpleDilation(BinarySimpleErosion(t,{}),{});
END BinarySimpleOpening;

PROCEDURE BinaryOpening*(CONST t, se: BinaryVolume):BinaryVolume;
BEGIN
	RETURN BinaryDilation(BinaryErosion(t,se),se);
END BinaryOpening;

PROCEDURE SimpleOpening*(CONST t:Volume; directions:SET):Volume;
BEGIN
	RETURN SimpleDilation(SimpleErosion(t,{}),{});
END SimpleOpening;

PROCEDURE BinarySimpleClosure*(CONST t:BinaryVolume; directions:SET):BinaryVolume;
BEGIN
	RETURN BinarySimpleErosion(BinarySimpleDilation(t,{}),{});
END BinarySimpleClosure;

PROCEDURE BinaryClosure*(CONST t, se: BinaryVolume):BinaryVolume;
BEGIN
	RETURN BinaryErosion(BinaryDilation(t,se),se);
END BinaryClosure;

PROCEDURE SimpleClosure*(CONST t:Volume; directions:SET):Volume;
BEGIN
	RETURN SimpleErosion(SimpleDilation(t,{}),{});
END SimpleClosure;
(*
PROCEDURE Closure(t:CONST Volume; CONST structure:Volume):Volume;
BEGIN
END Closure;
*)
PROCEDURE BinaryOuterEdge*(CONST t:BinaryVolume; directions:SET):BinaryVolume;
BEGIN
	RETURN BinarySimpleDilation(t,{}) & ~t;
END BinaryOuterEdge;

PROCEDURE BinaryInnerEdge*(CONST t:BinaryVolume; directions:SET):BinaryVolume;
BEGIN
	RETURN t & ~BinarySimpleErosion(t,{});
END BinaryInnerEdge;

PROCEDURE TestBinary*(context:Commands.Context);
VAR imgB,imgB1,imgB2,imgB3,imgB4,imgB5,imgB6: ARRAY [*,*,*] OF BOOLEAN;
	img,img1,img2,img3,img4,img5,img6: ARRAY [*,*,*] OF MatrixBase.Datatype;
	window: WMStack.Window;
BEGIN
	IF TRUE THEN
		NEW(imgB, 50,50,100); 
		imgB[10,..,..]:=TRUE;
		imgB[20..21,..,..]:=TRUE;
		imgB[30..33,..,..]:=TRUE;
		imgB[..,10,..]:=TRUE;
		imgB[..,20..21,..]:=TRUE;
		imgB[..,30..33,..]:=TRUE;
		imgB[..,..,10]:=TRUE;
		imgB[..,..,20..21]:=TRUE;
		imgB[..,..,30..33]:=TRUE;
		NEW(img, LEN(imgB));
		img:=MatrixUtilities.BoolToFloat(imgB);
		NEW(window, img, ""); window.AddWindow;
		
		imgB1:=BinarySimpleErosion(imgB,{});
		NEW(img1, LEN(imgB));
		img1:=MatrixUtilities.BoolToFloat(imgB1);
		NEW(window, img1, "Erosion"); window.AddWindow;
		
		imgB2:=BinarySimpleDilation(imgB,{});
		NEW(img2, LEN(imgB));
		img2:=MatrixUtilities.BoolToFloat(imgB2);
		NEW(window, img2, "Dilation"); window.AddWindow;
		
		imgB3:=BinarySimpleOpening(imgB,{});
		NEW(img3, LEN(imgB));
		img3:=MatrixUtilities.BoolToFloat(imgB3);
		NEW(window, img3, "Opening"); window.AddWindow;
		
		imgB4:=BinarySimpleClosure(imgB,{});
		NEW(img4, LEN(imgB));
		img4:=MatrixUtilities.BoolToFloat(imgB4);
		NEW(window, img4, "Closure"); window.AddWindow;
		
		imgB5:=BinarySimpleDilation(imgB,{}) & ~imgB;
		NEW(img5, LEN(imgB));
		img5:=MatrixUtilities.BoolToFloat(imgB5);
		NEW(window, img5, "OuterEdge"); window.AddWindow;
		
		imgB6:=imgB & ~BinarySimpleErosion(imgB,{}) ;
		NEW(img6, LEN(imgB));
		img6:=MatrixUtilities.BoolToFloat(imgB6);
		NEW(window, img6, "InnerEdge"); window.AddWindow;
	END;
END TestBinary;

PROCEDURE Test*(context:Commands.Context);
VAR imgB, imgB1, imgB2, imgB3, imgB4: Volume;
	img, img1, img2, img3, img4, img5, img6: Volume;
	window: WMStack.Window;
BEGIN
	IF TRUE THEN
		NEW(imgB, 50,50,100); 
		imgB[10,..,..]:=rand.Uniform();
		imgB[20..21,..,..]:=rand.Uniform();
		imgB[30..33,..,..]:=rand.Uniform();
		imgB[..,10,..]:=rand.Uniform();
		imgB[..,20..21,..]:=rand.Uniform();
		imgB[..,30..33,..]:=rand.Uniform();
		imgB[..,..,10]:=rand.Uniform();
		imgB[..,..,20..21]:=rand.Uniform();
		imgB[..,..,30..33]:=rand.Uniform();
		NEW(img, LEN(imgB));
		img:=imgB;
		NEW(window, img, ""); window.AddWindow;
		
		imgB1:=SimpleErosion(imgB,{});
		NEW(img1, LEN(imgB));
		img1:=imgB1;
		NEW(window, img1, "Erosion"); window.AddWindow;
		
		imgB2:=SimpleDilation(imgB,{});
		NEW(img2, LEN(imgB));
		img2:=imgB2;
		NEW(window, img2, "Dilation"); window.AddWindow;
		
		imgB3:=SimpleOpening(imgB,{});
		NEW(img3, LEN(imgB));
		img3:=imgB3;
		NEW(window, img3, "Opening"); window.AddWindow;
		
		imgB4:=SimpleClosure(imgB,{});
		NEW(img4, LEN(imgB));
		img4:=imgB4;
		NEW(window, img4, "Closure"); window.AddWindow;
	END;
END Test;

BEGIN
	NEW(rand)
END VolumeMorphology.

VolumeMorphology.Test ~
VolumeMorphology.TestBinary ~