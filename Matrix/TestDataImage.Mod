MODULE TestDataImage; (** AUTHOR "Patrick Hunziker 2019"; PURPOSE "Example of loading using path/name mask, constructing tensors & displaying them"; *)

IMPORT (*MLData, MLDataBasic, MatrixUtilities,*) Commands, Files, MatrixRaster, WMGraphics, WMTensor, WMComponents, WMStandardComponents, WMWindowManager, Rand:=Random;

CONST Random=0;

VAR rand:Rand.Generator;
CONST NSamples=32;
PROCEDURE Test*(context:Commands.Context);
VAR 
	(*data,labels:MLData.Dataset;*)
	(*source:MLDataBasic.Source;*)
	
	dataSetI, labelSetI: ARRAY [?] OF INTEGER;
	nSamples: SIZE;
	i: LONGINT;
	time, date, size: LONGINT;
	enum:MatrixRaster.Enumerator;
	flags: SET;
	name:Files.FileName;
	img: WMGraphics.Image;
	imgPanel: WMStandardComponents.ImagePanel;
	stackWindow: WMTensor.Window;
	window: WMComponents.FormWindow;
BEGIN
	nSamples:=NSamples;

	(** explore a directory path for file names fitting to a mask*)
	NEW(enum);
	enum.Open("*.jpg", flags); (* limit files examined by mask*)
	WHILE enum.HasMoreEntries() & enum.GetEntry(name, flags, time, date, size) DO  
		context.out.String(name); context.out.Ln; context.out.Update;
	END;
	
	enum.Open("Y*.jpg", flags); (* limit extracted images by file name mask*)
	(*can skip some images without loading*)
	(*	FOR i:=0 TO 5 DO res:=enum.GetEntry(name, flags, time, date, size) END; *)
	img:=enum.GetImage(name, flags, time, date, size); 

	(** showing an image as a WMComponents.VisualComponent / WMStandardComponents.ImagePanel *)
	NEW(imgPanel); 
	imgPanel.SetImage(NIL, img);
	NEW(window, MIN(img.height,600), MIN(img.width, 600), FALSE); 
	window.SetContent(imgPanel);
	WMWindowManager.AddWindow(window, 600, 200);
	
	(** extract a RGB stack from one ROI in one image. position in image can be predefined or random *)
	NEW(stackWindow, enum.GetRoiBGR(img, Random, Random), "[3D]scroll mouse/arrows", WMTensor.Frontal);
	stackWindow.AddWindow();
	
	(** extract a stack consisting of multiple randomly sampled ROIs from one image *)
	dataSetI:=enum.GetRoiStackRandom(img, nSamples, 3);
	(*produce a label data structure*)
	NEW(labelSetI, nSamples, 1, 1);
	FOR i:=0 TO LEN(labelSetI,0)-1 DO 
		labelSetI[i,?]:= SHORT(rand.Dice(2));
	END;
	
	(** produce a scrollable window displaying 2D,3D,4D datasets *)
	NEW(stackWindow, dataSetI, "[4D]scroll mouse/arrows", WMTensor.Frontal);
	stackWindow.AddWindow();
	
	(** check some info in data source example used for MLDeepLearning *)
	(*
	NEW(source, dataSetI, labelSetI); 
	source.SetSize([10, 10, 10], [10,1,1]);
	FOR i:=0 TO nSamples DO
		source.GetMiniBatch(nSamples, data,labels);
		MatrixUtilities.Out(LEN(data));
		MatrixUtilities.Out(data[0,0,0, *]);
		MatrixUtilities.Out(LEN(labels));
		MatrixUtilities.Out(labels);
	END;
	*)
END Test;

BEGIN
	NEW(rand);
END TestDataImage.

TestDataImage.Test ~

