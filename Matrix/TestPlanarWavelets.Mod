MODULE TestPlanarWavelets; (** AUTHOR ""; PURPOSE ""; *)

IMPORT Wavelets, PlanarWavelets, Commands, WMMatrix, Files, MatrixUtilities;
	

PROCEDURE Do*(context:Commands.Context);
VAR data,result: PlanarWavelets.Matrix;
	analyzer: PlanarWavelets.Analyzer;
	window: WMMatrix.Window;
BEGIN
	NEW(data,256,256);
	data[100..110,150..160]:=1;
	NEW(result,256,256);
	NEW(analyzer, Wavelets.Haar, Wavelets.default, data); 
	analyzer.Analyze;
	result:=analyzer.data;
	NEW(window, data, "data"); window.AddWindow;
	NEW(window, result, "result"); window.AddWindow;
END Do;

PROCEDURE Do1*(context:Commands.Context);
VAR data,result: PlanarWavelets.Matrix;
	analyzer: PlanarWavelets.Analyzer;
	window: WMMatrix.Window;
BEGIN
	NEW(data,256,256);
	data[100..110,150..160]:=1;
	NEW(result,256,256);
	NEW(analyzer, Wavelets.Haar, Wavelets.default, data); 
	analyzer.AnalyzeMultiscale(3);
	result:=analyzer.data;
	NEW(window, data, "data"); window.AddWindow;
	NEW(window, result, "result"); window.AddWindow;
END Do1;


PROCEDURE Do2*(context:Commands.Context);
VAR data,result: PlanarWavelets.Matrix;
	analyzer: PlanarWavelets.Analyzer;
	window: WMMatrix.Window;
BEGIN
	NEW(data,256,256);
	data[100..110,150..160]:=1;
	NEW(result,256,256);
	NEW(analyzer, Wavelets.Haar, Wavelets.default, data); 
	analyzer.Analyze;
	result:=analyzer.data;
	NEW(window, data, "data"); window.AddWindow;
	NEW(window, result, "result"); window.AddWindow;
END Do2;

PROCEDURE Do3*(context:Commands.Context);
VAR 
	raw: ARRAY [?] OF INTEGER;
	data,result,result1,result2,result3: PlanarWavelets.Matrix;
	analyzer: PlanarWavelets.Analyzer;
	window: WMMatrix.Window;
	filename: Files.FileName;
	w,h: LONGINT;
	f:Files.File; r:Files.Reader;
BEGIN
	IF context.arg.GetString(filename) & context.arg.GetInteger(h, FALSE) & context.arg.GetInteger(w,FALSE) THEN
		f:=Files.Old(filename); Files.OpenReader(r,f,0);
		NEW(raw,w,h);
		MatrixUtilities.ReadInt8(r, raw);
		data:=raw[..,..];
		(*NEW(result,w,h);*)
		
		NEW(analyzer, Wavelets.Haar, Wavelets.undefined, data); 
		analyzer.Analyze;
		result:=analyzer.data;
		
		NEW(analyzer, Wavelets.Haar, Wavelets.undefined, result[..LEN(result,0) DIV 2+1, ..LEN(result,1) DIV 2+1]); 
		analyzer.Analyze;
		result1:=analyzer.data;
		
		NEW(analyzer, Wavelets.Haar, Wavelets.undefined, result1[..LEN(result1,0) DIV 2+1, ..LEN(result1,1) DIV 2+1]); 
		analyzer.Analyze;
		result2:=analyzer.data;
		
		NEW(analyzer, Wavelets.Haar, Wavelets.undefined, result2[..LEN(result2,0) DIV 2+1, ..LEN(result2,1) DIV 2+1]); 
		analyzer.Analyze;
		result3:=analyzer.data;
		
		NEW(window, data, "data"); window.AddWindow;
		NEW(window, result, "result"); window.AddWindow;
		NEW(window, result1, "result1"); window.AddWindow;
		NEW(window, result2, "result2"); window.AddWindow;
		NEW(window, result3, "result3"); window.AddWindow;
	END;
END Do3;

PROCEDURE Do4*(context:Commands.Context);
VAR 
	raw: ARRAY [?] OF INTEGER;
	data,result,result1,result2,result3: PlanarWavelets.Matrix;
	analyzer: PlanarWavelets.Analyzer;
	window: WMMatrix.Window;
	filename: Files.FileName;
	w,h: LONGINT;
	f:Files.File; r:Files.Reader;
BEGIN
	IF context.arg.GetString(filename) & context.arg.GetInteger(h, FALSE) & context.arg.GetInteger(w,FALSE) THEN
		f:=Files.Old(filename); Files.OpenReader(r,f,0);
		NEW(raw,w,h);
		MatrixUtilities.ReadInt8(r, raw);
		data:=raw[..,..];
		(*NEW(result,w,h);*)
		
		NEW(analyzer, Wavelets.Haar, Wavelets.undefined, data); 
		analyzer.AnalyzeMultiscale(3);
		result:=analyzer.data;
		NEW(window, result, "result"); window.AddWindow;
	END;
END Do4;


END TestPlanarWavelets.

TestPlanarWavelets.Do ~
TestPlanarWavelets.Do1 ~
TestPlanarWavelets.Do2~
TestPlanarWavelets.Do3 E:/Manuscripts/Polymers/Kegang_13Sept2016/Kegang_CM200KV_14102016/Kegang_CM200KV_14102016/PIP17_HSA_200KV_015.8bit.raw 4096 4096~
TestPlanarWavelets.Do4 E:/Manuscripts/Polymers/Kegang_13Sept2016/Kegang_CM200KV_14102016/Kegang_CM200KV_14102016/PIP17_HSA_200KV_015.8bit.raw 4096 4096~

SystemTools.FreeDownTo MatrixBase Wavelets~
