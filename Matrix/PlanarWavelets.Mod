MODULE PlanarWavelets; (** AUTHOR "Patrick Hunziker"; PURPOSE "2D wavelet decomposition"; *)

IMPORT Wavelets;

TYPE Datatype*=Wavelets.Datatype;
	Matrix*=ARRAY [*,*] OF Datatype;
	Line*=ARRAY [*] OF Datatype;

TYPE Analyzer*= OBJECT
	VAR data*: Matrix;
		 waveletType, boundary: LONGINT;
		conv: Wavelets.WaveletConvolver;
		wavelet*:Wavelets.WaveletFamily;
		lineX,resX, lineY,resY: Line;
		child: Analyzer;
		
		(*choose wavelet family; need to choose compatible boundary conditions - see Wavelets.Mod*)
	PROCEDURE &Init*(waveletType, boundary: LONGINT; CONST data: Matrix);
	BEGIN
		SELF.data:=data; (*copy*)
		SELF.waveletType:=waveletType;
		SELF.boundary:=boundary;
		NEW(wavelet, waveletType);
		NEW(conv, wavelet, boundary);
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
	
	PROCEDURE AnalyzeMultiscale*(levels:LONGINT);
	VAR i:LONGINT;
	BEGIN
		Analyze;
		IF levels>1 THEN
			NEW(child, waveletType, boundary, data[..(LEN(data,0)+1)DIV 2, ..(LEN(data,1)+1) DIV 2]);
			child.AnalyzeMultiscale(levels-1);
			data[..(LEN(data,0)+1)DIV 2, ..(LEN(data,1)+1) DIV 2]:=child.data;
		END;
	END AnalyzeMultiscale;
	
	PROCEDURE AnalyzePacket*(levels:LONGINT);(*!? questionable implementation of hierarch ?*)
	VAR i:LONGINT;
	BEGIN
		Analyze;
		IF levels>1 THEN
			NEW(child, waveletType, boundary, data[..LEN(data,0)-1, ..LEN(data,1)-1]);
			child.AnalyzeMultiscale(levels-1);
			data[..LEN(data,0)-1, ..LEN(data,1)-1]:=child.data;
		END;
	END AnalyzePacket;
	
	END Analyzer;

	

END PlanarWavelets.


