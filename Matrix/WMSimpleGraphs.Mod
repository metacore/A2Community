MODULE WMSimpleGraphs;	(** AUTHOR "Patrick Hunziker"; PURPOSE "Minimum-overhead graph drawing"; *)
(*  
note: WMNavigate thumbnail right-click allows window storage as .bmp files
*)


IMPORT WMWindowManager, Strings, WMGraphics, WMRectangles, Modules;


TYPE
	Histogram* = OBJECT (WMWindowManager.Window);
	VAR 
		data:ARRAY [*] OF LONGREAL;
		width,height:LONGINT;

		PROCEDURE &New*(CONST data: ARRAY [*] OF LONGREAL; CONST title: ARRAY OF CHAR);
		VAR max:LONGREAL; 
		BEGIN
			SELF.data:=data;
			max:=MAX(data);
			width:=LEN(data,0); height:=ENTIER(max)+1;
			Init(10*width, 10*height, FALSE);
			manager := WMWindowManager.GetDefaultManager();
			manager.Add(100, 100, SELF, {WMWindowManager.FlagFrame,WMWindowManager.FlagClose});
			SetTitle(Strings.NewString(title));
			SetPointerInfo(manager.pointerCrosshair);
		END New;
		
		PROCEDURE Draw*(canvas : WMGraphics.Canvas; w, h, q : LONGINT);
		VAR i:LONGINT;
		BEGIN
			canvas.Fill(WMRectangles.MakeRect(0, 0, w, h), WMGraphics.White, WMGraphics.ModeCopy);
			FOR i:=0 TO LEN(data,0)-1 DO
				canvas.Fill(WMRectangles.MakeRect(i*w DIV width , h-ENTIER(data[i]*h / height), (i+1)*w DIV width , h), WMGraphics.Black, WMGraphics.ModeCopy);
			END;
			(*INC(timestamp);*)(*un-comment on next release*)
		END Draw;
	END Histogram;


	Graph* = OBJECT (WMWindowManager.Window);
	VAR 
		data:ARRAY [*] OF LONGREAL;
		width,height:LONGINT;
		max,min:LONGREAL;

		PROCEDURE &New*(CONST data: ARRAY [*] OF LONGREAL; CONST title: ARRAY OF CHAR);
		BEGIN
			SELF.data:=data;
			max:=MAX(data);
			min:=MIN(0, MIN(data)); 
			width:=LEN(data,0); height:=ENTIER(max-min)+1;
			Init(10*width, 10*height, FALSE);
			manager := WMWindowManager.GetDefaultManager();
			manager.Add(150, 150, SELF, {WMWindowManager.FlagFrame,WMWindowManager.FlagClose});
			SetTitle(Strings.NewString(title));
			SetPointerInfo(manager.pointerCrosshair);
		END New;
		
		PROCEDURE Draw*(canvas : WMGraphics.Canvas; w, h, q : LONGINT);
		VAR i:LONGINT; mn,mx:LONGINT;
		BEGIN
			canvas.Fill(WMRectangles.MakeRect(0, 0, w, h), WMGraphics.White, WMGraphics.ModeCopy);
			mn:=ENTIER(0.5+min*h / height);
			mx:=ENTIER(0.5+max*h / height);
			FOR i:=0 TO LEN(data,0)-2 DO
				canvas.Line(i*w DIV width, 	h+mn-ENTIER(0.5+data[i]*h / height),  
							(i+1)*w DIV width, h+mn-ENTIER(0.5+data[i+1]*h / height), 
							WMGraphics.Black, WMGraphics.ModeCopy);
			END;
			IF mn#0 THEN 
				canvas.Line(0, h+mn, w, h+mn, WMGraphics.Black, WMGraphics.ModeCopy);
			END;
			(*INC(timestamp);*)(*un-comment on next release*)
		END Draw;
END Graph;


GraphXY* = OBJECT (WMWindowManager.Window);
	VAR 
		data:ARRAY [*,*] OF LONGREAL;
		width,height:LONGINT;
		max,min:LONGREAL;

		PROCEDURE &New*(CONST data: ARRAY [*,*] OF LONGREAL; CONST title: ARRAY OF CHAR);
		BEGIN
			SELF.data:=data;
			max:=MAX(0,MAX(data));
			min:=MIN(0, MIN(data)); 
			width:=ENTIER(max-min)+1; height:=ENTIER(max-min)+1;
			Init(10*width, 10*height, FALSE);
			manager := WMWindowManager.GetDefaultManager();
			manager.Add(150, 150, SELF, {WMWindowManager.FlagFrame,WMWindowManager.FlagClose});
			SetTitle(Strings.NewString(title));
			SetPointerInfo(manager.pointerCrosshair);
		END New;
		
		PROCEDURE Draw*(canvas : WMGraphics.Canvas; w, h, q : LONGINT);
		VAR i:LONGINT; mnw,mnh,mxw,mxh:LONGINT; scalex,scaley:REAL;
		BEGIN
			canvas.Fill(WMRectangles.MakeRect(0, 0, w, h), WMGraphics.White, WMGraphics.ModeCopy);
			scalex:=w/width; scaley:=h/height;
			mnw:=ENTIER(0.5+min* scalex);	mxw:=ENTIER(0.5+max* scalex);
			mnh:=ENTIER(0.5+min* scaley);	mxh:=ENTIER(0.5+max* scaley);
			FOR i:=0 TO LEN(data,1)-2 DO
				canvas.Line(-mnw+ENTIER(0.5+data[0,i]*scalex), 	h+mnh-ENTIER(0.5+data[1,i]*scaley),  
							-mnw+ENTIER(0.5+data[0,i+1]*scalex), h+mnh-ENTIER(0.5+data[1,i+1]*scaley), 
							WMGraphics.Blue, WMGraphics.ModeCopy);
			END;
			IF mnh#0 THEN 
				canvas.Line(0, h+mnh, w, h+mnh, WMGraphics.Black, WMGraphics.ModeCopy);
			END;
			IF mnw#0 THEN 
				canvas.Line(-mnw, 0, -mnw, h, WMGraphics.Black, WMGraphics.ModeCopy);
			END;
			(*INC(timestamp);*)(*un-comment on next release*)
		END Draw;
END GraphXY;

Graphs* = OBJECT (WMWindowManager.Window);
	VAR 
		data:ARRAY [*,*] OF LONGREAL;
		width,height:LONGINT;
		max,min:LONGREAL;

		PROCEDURE &New*(CONST data: ARRAY [*,*] OF LONGREAL; CONST title: ARRAY OF CHAR);
		BEGIN
			SELF.data:=data;
			max:=MAX(data);
			min:=MIN(0, MIN(data)); 
			width:=LEN(data,1); height:=ENTIER(max-min)+1;
			Init(10*width, 10*height, FALSE);
			manager := WMWindowManager.GetDefaultManager();
			manager.Add(200, 200, SELF, {WMWindowManager.FlagFrame,WMWindowManager.FlagClose});
			SetTitle(Strings.NewString(title));
			SetPointerInfo(manager.pointerCrosshair);
		END New;
		
		PROCEDURE Draw*(canvas : WMGraphics.Canvas; w, h, q : LONGINT);
		VAR i,j:LONGINT; mn,mx:LONGINT;
		BEGIN
			canvas.Fill(WMRectangles.MakeRect(0, 0, w, h), WMGraphics.White, WMGraphics.ModeCopy);
			mn:=ENTIER(0.5+min*h / height);
			mx:=ENTIER(0.5+max*h / height);
			FOR j:=0 TO LEN(data,0)-1 DO
				FOR i:=0 TO LEN(data,1)-2 DO
					canvas.Line(i*w DIV width, 	h+mn-ENTIER(0.5+data[j,i]*h / height),  
								(i+1)*w DIV width, h+mn-ENTIER(0.5+data[j,i+1]*h / height), 
								Colors[j MOD LEN(Colors,0)], WMGraphics.ModeCopy);
				END;
			END;
			IF mn#0 THEN 
				canvas.Line(0, h+mn, w, h+mn, WMGraphics.Black, WMGraphics.ModeCopy);
			END;
			(*INC(timestamp);*)(*un-comment on next release*)
		END Draw;
END Graphs;

VAR Colors: ARRAY [*] OF WMGraphics.Color;

PROCEDURE Demo*;
VAR h:Histogram; g:Graph; k: Graphs; m:GraphXY;
BEGIN {EXCLUSIVE}
	NEW(h,[4,7,8,4,5,9,6,5,3,2,12,17,3,0,2], "Histogram"); 
	NEW(g,[4,7,8,4,5,9,6,5,3,2,12,17,3,-3,2], "Graph"); 
	NEW(k,[[-2,7,8,4,5,9,6,4,7,8,4,5,9,6],
			[5,3,2,12,21,3,0,5,3,-2,12,17,3,1]], "MultiGraph"); 
	NEW(m,[	[-2,-1,0,1,5,9,6,4,7,3,4,5,9,6],
				[1,3,4,7,12,3,0,5,3,-2,12,17,3,1]], "GraphXY"); 
END Demo;

PROCEDURE Cleanup;

END Cleanup;

BEGIN
	Modules.InstallTermHandler(Cleanup);
	Colors:=[WMGraphics.Red,WMGraphics.Blue,WMGraphics.Green,WMGraphics.Yellow, WMGraphics.Magenta, WMGraphics.Cyan, WMGraphics.Gray]
END WMSimpleGraphs.

SystemTools.Free WMSimpleGraphs ~
WMSimpleGraphs.Demo ~

