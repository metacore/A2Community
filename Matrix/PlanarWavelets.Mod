MODULE PlanarWavelets; (** AUTHOR "Patrick Hunziker"; PURPOSE "2D wavelet decomposition"; *)

IMPORT Wavelets;

TYPE Datatype*=Wavelets.Datatype;
	Matrix*=ARRAY [*,*] OF Datatype;
	Line*=ARRAY [*] OF Datatype;

TYPE Analyzer*= OBJECT
	VAR data*: Matrix;
		conv: Wavelets.WaveletConvolver;
		wavelet*:Wavelets.WaveletFamily;
		lineX,resX, lineY,resY: Line;
		
		(*choose wavelet family; need to choose compatible boundary conditions - see Wavelets.Mod*)
	PROCEDURE &Init*(waveletType, boundary: LONGINT; CONST data: Matrix);
	BEGIN
		SELF.data:=data; (*copy*)
		NEW(wavelet, waveletType);
		NEW(conv, wavelet, Wavelets.undefined);
		NEW(lineY, LEN(data,0)); NEW(resY, LEN(data,0)); 
		NEW(lineX, LEN(data,1)); NEW(resX, LEN(data,1)); 
	END Init;
	
	PROCEDURE Analyze*;
	VAR i:LONGINT;
	BEGIN
		FOR i:=0 TO LEN(data,0)-1 DO
			conv.Analyze(data[i], resX);
			data[i]:=resX; (*could do in-place ?*)
		END;
		FOR i:=0 TO LEN(data,1)-1 DO
			conv.Analyze(data[..,i], resY);
			data[..,i]:=resY; (*could do in-place ?*)
		END;
	END Analyze;
	
	END Analyzer;

	

END PlanarWavelets.


