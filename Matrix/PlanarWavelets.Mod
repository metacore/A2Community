MODULE PlanarWavelets; (** AUTHOR "Patrick Hunziker"; PURPOSE "2D wavelet decomposition"; *)

IMPORT Wavelets, Statistics:=StatisticsBase, WMArrayPanel;

TYPE Datatype*=Wavelets.Datatype;
	Tensor*=ARRAY [?] OF Datatype;
	Matrix*=ARRAY [*,*] OF Datatype;
	Line*=ARRAY [*] OF Datatype;

TYPE Analyzer*= OBJECT
	VAR data*: Matrix;
		 waveletType, boundary: SIGNED32;
		conv: Wavelets.WaveletConvolver;
		wavelet*:Wavelets.WaveletFamily;
		lineX,resX, lineY,resY: Line;
		child: Analyzer;

		(*choose wavelet family; need to choose compatible boundary conditions - see Wavelets.Mod*)
	PROCEDURE &Init*(waveletType, boundary: SIGNED32; CONST data: Matrix);
	BEGIN
		SELF.waveletType:=waveletType;
		NEW(wavelet, waveletType);
		IF boundary=Wavelets.default THEN SELF.boundary:=wavelet.defaultBoundary ELSE SELF.boundary:=boundary END;
		NEW(conv, wavelet, boundary);
		SetData(data);
	END Init;

	PROCEDURE SetData*(CONST data: Matrix);
	BEGIN
		IF LEN(data)>0 THEN
			IF LEN(data)#LEN(SELF.data) THEN
				NEW(SELF.data, LEN(data));
				NEW(lineY, LEN(data,0)); NEW(resY, LEN(data,0));
				NEW(lineX, LEN(data,1)); NEW(resX, LEN(data,1));
			END;
			SELF.data:=data; (*!copy. could do in-place ?*)
		END;
	END SetData;


	PROCEDURE Analyze*;
	VAR i:SIZE; offset:Datatype; LL: Matrix;
	BEGIN
		FOR i:=0 TO LEN(data,0)-1 DO
			conv.Analyze(data[i], resX);
			data[i]:=resX; (*could do in-place ?*)
		END;
		FOR i:=0 TO LEN(data,1)-1 DO
			conv.Analyze(data[..,i], resY);
			data[..,i]:=resY; (* could do in-place ? *)
		END;
	END Analyze;

	PROCEDURE AnalyzeMultiscale*(levels:SIGNED32);
	VAR i:SIGNED32;
	BEGIN
		Analyze;
		IF levels>1 THEN
			NEW(child, waveletType, boundary, data[..(LEN(data,0)+1)DIV 2-1, ..(LEN(data,1)+1) DIV 2-1]);
			child.AnalyzeMultiscale(levels-1);
			data[..(LEN(data,0)+1)DIV 2-1, ..(LEN(data,1)+1) DIV 2-1]:=child.data;
		END;
	END AnalyzeMultiscale;

	PROCEDURE AnalyzePacket*(levels:SIGNED32);
	VAR i:SIGNED32;
	BEGIN
		Analyze;
		IF levels>1 THEN
			NEW(child, waveletType, boundary, data[..(LEN(data,0)+1)DIV 2-1, ..(LEN(data,1)+1) DIV 2-1]); (*! should use child.SetData for efficiency*)
			child.AnalyzePacket(levels-1);
			data[..(LEN(data,0)+1)DIV 2-1, ..(LEN(data,1)+1) DIV 2-1]:=child.data;

			child.Init(waveletType, boundary, data[(LEN(data,0)+1)DIV 2.., ..(LEN(data,1)+1) DIV 2-1]);
			child.AnalyzePacket(levels-1);
			data[(LEN(data,0)+1)DIV 2.., ..(LEN(data,1)+1) DIV 2-1]:=child.data;

			child.Init(waveletType, boundary, data[..(LEN(data,0)+1)DIV 2-1, (LEN(data,1)+1) DIV 2..]);
			child.AnalyzePacket(levels-1);
			data[..(LEN(data,0)+1)DIV 2-1, (LEN(data,1)+1) DIV 2..]:=child.data;

			child.Init(waveletType, boundary, data[(LEN(data,0)+1)DIV 2.., (LEN(data,1)+1) DIV 2..]);
			child.AnalyzePacket(levels-1);
			data[(LEN(data,0)+1)DIV 2.., (LEN(data,1)+1) DIV 2..]:=child.data;
		END;

	END AnalyzePacket;

	END Analyzer;

TYPE Reconstructor*= OBJECT
	VAR data*: Matrix;
		 waveletType, boundary: SIGNED32;
		conv: Wavelets.WaveletConvolver;
		wavelet*:Wavelets.WaveletFamily;
		lineX,resX, lineY,resY: Line;
		child: Reconstructor;

		(*choose wavelet family; need to choose compatible boundary conditions - see Wavelets.Mod*)
	PROCEDURE &Init*(waveletType, boundary: SIGNED32; CONST data: Matrix);
	BEGIN
		SELF.waveletType:=waveletType;
		NEW(wavelet, waveletType);
		IF boundary=Wavelets.default THEN SELF.boundary:=wavelet.defaultBoundary ELSE SELF.boundary:=boundary END;
		NEW(conv, wavelet, boundary);
		SetData(data);
	END Init;

	PROCEDURE SetData*(CONST data: Matrix);
	BEGIN
		IF LEN(data)>0 THEN
			IF LEN(data)#LEN(SELF.data) THEN
				NEW(SELF.data, LEN(data));
				NEW(lineY, LEN(data,0)); NEW(resY, LEN(data,0));
				NEW(lineX, LEN(data,1)); NEW(resX, LEN(data,1));
			END;
			SELF.data:=data; (*!copy. could do in-place ?*)
		END;
	END SetData;


	PROCEDURE Reconstruct*;
	VAR i:SIZE; offset:Datatype; LL: Matrix;
	BEGIN
		FOR i:=0 TO LEN(data,0)-1 DO
			conv.Reconstruct(data[i], resX);
			data[i]:=resX; (*could do in-place ?*)
		END;
		FOR i:=0 TO LEN(data,1)-1 DO
			conv.Reconstruct(data[..,i], resY);
			data[..,i]:=resY; (* could do in-place ? *)
		END;
	END Reconstruct;

	PROCEDURE ReconstructMultiscale*(levels:SIGNED32);
	VAR i:SIGNED32;
	BEGIN
		IF levels>1 THEN
			NEW(child, waveletType, boundary, data[..(LEN(data,0)+1)DIV 2-1, ..(LEN(data,1)+1) DIV 2-1]);
			child.ReconstructMultiscale(levels-1);
			data[..(LEN(data,0)+1)DIV 2-1, ..(LEN(data,1)+1) DIV 2-1]:=child.data;
		END;
		Reconstruct;
	END ReconstructMultiscale;

	PROCEDURE ReconstructPacket*(levels:SIGNED32);
	VAR i:SIGNED32;
	BEGIN
		IF levels>1 THEN
			NEW(child, waveletType, boundary, data[..(LEN(data,0)+1)DIV 2-1, ..(LEN(data,1)+1) DIV 2-1]); (*! should use child.SetData for efficiency*)
			child.ReconstructPacket(levels-1);
			data[..(LEN(data,0)+1)DIV 2-1, ..(LEN(data,1)+1) DIV 2-1]:=child.data;

			child.Init(waveletType, boundary, data[(LEN(data,0)+1)DIV 2.., ..(LEN(data,1)+1) DIV 2-1]);
			child.ReconstructPacket(levels-1);
			data[(LEN(data,0)+1)DIV 2.., ..(LEN(data,1)+1) DIV 2-1]:=child.data;

			child.Init(waveletType, boundary, data[..(LEN(data,0)+1)DIV 2-1, (LEN(data,1)+1) DIV 2..]);
			child.ReconstructPacket(levels-1);
			data[..(LEN(data,0)+1)DIV 2-1, (LEN(data,1)+1) DIV 2..]:=child.data;

			child.Init(waveletType, boundary, data[(LEN(data,0)+1)DIV 2.., (LEN(data,1)+1) DIV 2..]);
			child.ReconstructPacket(levels-1);
			data[(LEN(data,0)+1)DIV 2.., (LEN(data,1)+1) DIV 2..]:=child.data;
		END;
		Reconstruct;
	END ReconstructPacket;

	END Reconstructor;

PROCEDURE Test*;
VAR a,b,c: Matrix;
	an:Analyzer;
	rec:Reconstructor;
	
BEGIN
	NEW(a,200,200); a[50..100,50..100]:=1.0;
	WMArrayPanel.AddWindow(a,"data");
	NEW(an, Wavelets.Haar, Wavelets.finite, a);
	an.AnalyzePacket(3);
	WMArrayPanel.AddWindow(an.data,"analysis");
	NEW(rec, Wavelets.Haar, Wavelets.finite, an.data);
	rec.ReconstructPacket(3);
	WMArrayPanel.AddWindow(rec.data,"reconstruction");
END Test;


END PlanarWavelets.

PlanarWavelets.Test~

System.FreeDownTo PlanarWavelets ~
