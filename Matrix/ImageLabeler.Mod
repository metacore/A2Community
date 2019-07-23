MODULE ImageLabeler; (** AUTHOR "Patrick Hunziker 2019"; PURPOSE "Interactively loading files, defining labels, storing them as file"; *)

IMPORT Commands, Files, Streams, Strings, Options, Raster, Rand:=Random, MatrixRaster, 
			WMGraphics, WMRasterScale, WMRectangles, WMTensor, WMComponents, WMMenus, WMTrees, WMStandardComponents, WMWindowManager;

CONST Random=MatrixRaster.Random;
		 Tab=09X;

VAR 	rand:Rand.Generator;
		globalContextMenu*:ContextMenu;

TYPE StringObject=OBJECT 
			VAR 
				s:Strings.String;
				id:LONGINT;
		END StringObject;

TYPE Command=OBJECT 
			VAR s:Strings.String;
		END Command;

TYPE Location=POINTER TO RECORD
		x,y: LONGINT;
		id:LONGINT;
		s:Strings.String;
		next:Location;
	END;

TYPE	ContextMenu* = OBJECT 
	VAR x,y, nItems: LONGINT;
		w:Streams.Writer;
		name: Files.FileName;
		menu: WMTrees.Tree; 
		nextImage, stop: PROCEDURE{DELEGATE}();
		locations:Location; (*list of locations, is per image*)
		
	PROCEDURE &Init*(w:Streams.Writer);
	BEGIN
		SELF.w:=w;
		NEW(menu); 
		nItems:=0;
	END Init;
	
	PROCEDURE AddItem*(CONST popupLabel: ARRAY OF CHAR; item: ANY);
	VAR node: WMTrees.TreeNode;
	BEGIN
		node := WMMenus.AddItemNode(popupLabel, menu);
		IF (item#NIL) & (item IS StringObject) THEN item(StringObject).id:=nItems; INC(nItems) END;
		menu.Acquire;
		menu.SetNodeData(node, item); 
		menu.Release;
	END AddItem;
	
	PROCEDURE Handle* (sender : ANY; x, y: LONGINT);
	VAR gx,gy: LONGINT;
	BEGIN
		SELF.x:=x; SELF.y:=y;	
		sender(WMComponents.VisualComponent).ToWMCoordinates(x,y,gx,gy);
		WMMenus.Show(menu, gx, gy, HandleItemSelected);
	END Handle;
	
	PROCEDURE HandleItemSelected*(sender, data : ANY);
	VAR l:Location;
	BEGIN
		IF data # NIL THEN
			IF data IS StringObject THEN
				NEW(l); l.s:=data(StringObject).s; l.x:=x; l.y:=y; l.id:=data(StringObject).id; l.next:=locations; locations:=l;				
				w.Char('"'); w.String(name); w.Char('"'); w.Char(Tab);	w.String(l.s^); w.Char(Tab); 
				w.Int(l.id,0); w.Char(Tab); w.Int(l.x,0); w.Char(Tab); w.Int(l.y,0); w.Ln; w.Update;
			ELSIF data IS Command THEN
				IF data(Command).s^ = "Stop" THEN stop();
				ELSIF data(Command).s^ = "NextImage" THEN	nextImage();
				END;
			END;
		END;
	END HandleItemSelected;

	END ContextMenu;
	
PROCEDURE Distance2(dx,dy: LONGINT):LONGINT; (*squared distance*)
BEGIN
	RETURN dx*dx+dy*dy
END Distance2;

PROCEDURE NewStringObject(CONST str: ARRAY OF CHAR): ANY;
	VAR string:StringObject;
	BEGIN
		NEW(string); 
		string.s:=Strings.NewString(str);
		RETURN string;
	END NewStringObject;

PROCEDURE NewCommand(CONST str: ARRAY OF CHAR): ANY;
	VAR command:Command;
	BEGIN
		NEW(command); 
		command.s:=Strings.NewString(str);
		RETURN command;
	END NewCommand;

TYPE Labeler*=OBJECT
	VAR 
		dataSetI, labelSetI: ARRAY [?] OF INTEGER;
		positions: ARRAY [*,*] OF LONGINT;
		nSamples: LONGINT(*SIZE*);
		i: LONGINT;
		time, date, size: LONGINT;
		enum:MatrixRaster.Enumerator;
		flags: SET;
		name, mask:Files.FileName;
		img: WMGraphics.Image;
		imgPanel: WMStandardComponents.ImagePanel;
		(*imgPanel: WMStandardComponents.Image;*)
		stackWindow, oldStackWindow, labelWindow: WMTensor.Window;
		window: WMComponents.FormWindow;
		contextMenu:ContextMenu;
		w:Streams.Writer;
		dead, hasNewImage, hit, scale:BOOLEAN;
		minWidth,minHeight:LONGINT;
		l:Location;
		threshold2:LONGINT; (*squared threshold*)
	
	PROCEDURE &Init*(CONST mask: ARRAY OF CHAR; w: Streams.Writer);
	BEGIN
		SELF.w:=w;
		COPY(mask,SELF.mask);
		minWidth:=100; minHeight:=100;
		nSamples:=32;
		dead:=FALSE;
		
		contextMenu:=globalContextMenu;
		contextMenu.w:=w;
		contextMenu.nextImage:=NextImage;
		contextMenu.stop:=Finish;
		
		NEW(enum); enum.Open(mask, flags); (* can limit extracted images by file name mask*)
		(*	FOR i:=0 TO 5 DO res:=enum.GetEntry(name, flags, time, date, size) END; *)(*can skip some images without loading*)
		threshold2:=(enum.w DIV 3)*(enum.h DIV 3);

		NEW(positions,nSamples,2);
		positions[*,*]:=Random;
	END Init;
	
	PROCEDURE NextImage*();
	VAR newImg:WMGraphics.Image; bounds, bounds1: WMRectangles.Rectangle;
	BEGIN
		newImg:=enum.GetImage(name, flags, time, date, size); 
		BEGIN {EXCLUSIVE} hasNewImage:= (newImg#NIL) & (newImg.width>=minWidth) & (newImg.height>=minHeight)  END;
		IF scale THEN
			NEW(img); Raster.Create(img, 600, ENTIER(600/newImg.width*newImg.height), Raster.BGRA8888);
			bounds.l:=0; bounds.t:=0; bounds.r:=newImg.width; bounds.b:=newImg.height;
			bounds1.l:=0; bounds1.t:=0; bounds1.r:=img.width; bounds1.b:=img.height;
			WMRasterScale.Scale(newImg,bounds ,img, bounds1, bounds1, WMRasterScale.ModeCopy, WMRasterScale.ScaleBox);
		ELSE
			img:=newImg;
		END;
	END NextImage;
	
	PROCEDURE Finish*;
	BEGIN{EXCLUSIVE} 
		dead:=TRUE
	END Finish;
	
BEGIN
	(** explore a directory path for file names fitting to a mask*)
	(* NEW(enum); enum.Open(mask, flags); 
	WHILE enum.HasMoreEntries() & enum.GetEntry(name, flags, time, date, size) DO  
		w.String(name); w.Ln; w.Update;
	END; *)
	
	NextImage(); 
	LOOP
		IF (window#NIL)&(window.GetManager()#NIL) THEN window.GetManager().Remove(window) END;
		IF (oldStackWindow#NIL)&(oldStackWindow.GetManager()#NIL) THEN oldStackWindow.GetManager().Remove(oldStackWindow) END;
		
		(** showing an image as a WMComponents.VisualComponent / WMStandardComponents.ImagePanel *)
		COPY(name, contextMenu.name);
		NEW(imgPanel); 
		imgPanel.SetExtContextMenuHandler(contextMenu.Handle);
		imgPanel.bounds.SetWidth(img.width);
		imgPanel.bounds.SetHeight(img.height);
		(*imgPanel.imgName.SetAOC(name);*)(* named loading does not fit well to rescaling ..*)
		imgPanel.SetImage(NIL, img); (*can also set image directly, anonymously*)

		NEW(window, img.width, img.height, FALSE); 
		window.SetContent(imgPanel);
		window.SetTitle(Strings.NewString(name));
		
		(** extract a stack consisting of multiple randomly sampled ROIs from one image *)
		positions[*,*]:=Random;
		dataSetI:=enum.GetRoiStackRandom(img, nSamples, 3, positions);

		WMWindowManager.AddWindow(window, 600, 200);		
		(** produce a scrollable window displaying 2D,3D,4D datasets *)
		oldStackWindow:=stackWindow;
		NEW(stackWindow, dataSetI, "[4D]scroll mouse/arrows", WMTensor.Frontal);
		stackWindow.AddWindow();
		
		hasNewImage:=FALSE;
		BEGIN{EXCLUSIVE} AWAIT(dead OR hasNewImage) END;
		IF (labelWindow#NIL)&(labelWindow.GetManager()#NIL) THEN labelWindow.GetManager().Remove(labelWindow) END;
		
		(** example for producing a label data structure *)
		NEW(labelSetI, nSamples, 1, contextMenu.nItems);
		FOR i:=0 TO LEN(labelSetI,0)-1 DO 
			l:=contextMenu.locations;
			hit:=FALSE;
			WHILE l#NIL DO 
				IF Distance2(l.x-positions[i,0]-enum.w DIV 2, l.y-positions[i,1]-enum.h DIV 2)< threshold2 THEN 
					hit:=TRUE;
					labelSetI[i,?,l.id]:=1;
				END;
				l:=l.next;
			END;
		END;
		contextMenu.locations:=NIL; (*list of locations is per image*)

		NEW(labelWindow, labelSetI, "labels", WMTensor.Frontal);
		labelWindow.AddWindow();

		IF dead THEN EXIT END;
	END;
END Labeler;

(*open a labeler object for labeling list of images, according to file name mask. 
Can use the default or an interactively prepared label list contained in a popup menu. 
optionally stores a list of fn,label,id,coord to result file *)
PROCEDURE Open*(context:Commands.Context);
VAR labeler: Labeler; options: Options.Options; 
	f:Files.File; s,mask:Files.FileName; fw:Files.Writer; w:Streams.Writer;
BEGIN
	NEW(options); 
	options.Add("f","resultFile",Options.String);
	options.Add("m","mask",Options.String); 
	options.Add("t","threshold",Options.Integer); (* distance of image center from label that is still considered a hit *)
	options.Add("s","scale",Options.Flag); (* scale image to manageable size *)
	(*options.Add("n","nSamples", Options.Integer); *)
	IF options.Parse(context.arg, context.error) THEN
		IF options.GetString("resultFile", s) THEN 
			f:=Files.New(s); Files.Register(f); Files.OpenWriter(fw,f,0); w:=fw;
			context.out.String("writing result file: "); context.out.String(s); context.out.Ln; context.out.Update;
		ELSE w:=context.out 
		END;
		IF options.GetString("mask",mask) THEN
			context.out.String("file mask: "); context.out.String(mask); context.out.Ln; context.out.Update;
		ELSE mask:="*" 
		END;
	END;
	NEW(labeler,mask, w); 
	labeler.scale:=options.GetFlag("scale");
	IF options.GetInteger("threshold",labeler.threshold2) THEN END; (*? labeler active object has already started, this may come late*)
END Open;

(*create context menu with label-name pairs for popup menu. <sourceFile, labelName, id, coordinates, Ln>  will be written to tab-separated text stream including their mouse click coordinates*)
PROCEDURE NewMenu*(context:Commands.Context);
VAR label,string:ARRAY 256 OF CHAR;
BEGIN
	NEW(globalContextMenu, context.out);
	WHILE context.arg.GetString(label) & context.arg.GetString(string) DO
		globalContextMenu.AddItem(label, NewStringObject(string));
	END;
	globalContextMenu.AddItem("------", NIL);
	globalContextMenu.AddItem("nextImage", NewCommand("NextImage"));
	globalContextMenu.AddItem("stop", NewCommand("Stop"));
	context.out.String("context menu read"); context.out.Ln; context.out.Update;
END NewMenu;

BEGIN
	NEW(rand);
	NEW(globalContextMenu, NIL);
		globalContextMenu.AddItem("0", NewStringObject("0"));
		globalContextMenu.AddItem("1", NewStringObject("1"));
		globalContextMenu.AddItem("2", NewStringObject("2"));
		globalContextMenu.AddItem("3", NewStringObject("3"));
		globalContextMenu.AddItem("----", NIL);		
		globalContextMenu.AddItem("nextImage", NewCommand("NextImage"));
		globalContextMenu.AddItem("stop", NewCommand("Stop"));
END ImageLabeler.

(*create label-name pairs for popup menu *)
ImageLabeler.NewMenu
	mouth Mouth
	nose	Nose
	eye	Eye
	ear	Ear
	chin	Chin
 ~
 
ImageLabeler.Open -m="*.jpg" -f=Labeler1.txt ~
ImageLabeler.Open -m="C:/Program Files (x86)/A2/HighDim/Code/EyeTracker/EyeDB_Internet/*.jpg" -f=Eyes.txt --scale ~

System.Free ImageLabeler ~

