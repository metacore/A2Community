MODULE MatrixRaster ;	(**  AUTHOR "Patrick Hunziker"; PURPOSE "visualize Matrix contents";  **)
IMPORT Raster , Reals, SYSTEM, WM:=WMWindowManager, Strings, RasterPixelFormats;

PROCEDURE SIntToImage*(CONST data:ARRAY [*,*] OF SHORTINT; VAR palette: ARRAY [*,*] OF LONGINT; im:Raster.Image); (*palette values in range 0..10000H*)
VAR F:Raster.Format; pal:Raster.Palette; i,x,y:LONGINT;
BEGIN
	IF (LEN(data,0)=0) OR (LEN(data,1)=0) THEN RETURN END;
	NEW(pal);
	(*NEW(pal.col,256);*)
	IF LEN(palette,0)=0 THEN
		FOR i:=0 TO LEN(pal.col)-1 DO
			pal.col[i,0]:=CHR(i);
			pal.col[i,1]:=CHR(i);
			pal.col[i,2]:=CHR(i);
			pal.col[i,3]:=0FFX;
		END;
	ELSE 
		FOR i:=0 TO LEN(palette,0)-1 DO
			pal.col[i,0]:= CHR(SHORT(palette[i,2] MOD 10000H DIV 256));
			pal.col[i,1]:=CHR(SHORT(palette[i,1] MOD 10000H DIV 256));
			pal.col[i,2]:=CHR(SHORT(palette[i,0] MOD 10000H DIV 256));
			pal.col[i,3]:=0FFX;
		END;
	END;
	Raster.InitPaletteFormat(F,pal);
	Raster.Create(im,LEN(data,1),LEN(data,0),F);	(*TO DO: reuse if fitting ...*)
	FOR y:=0 TO LEN(data,0)-1 DO
		FOR x:=0 TO LEN(data,1)-1 DO
			im.mem[y*im.bpr+x]:= CHR(data[y,x] MOD 256); 
		END;
	END;
END SIntToImage;

PROCEDURE SIntRGBToImage*(CONST data:ARRAY [*,*,*] OF SHORTINT; im:Raster.Image); 
VAR F:Raster.Format; pal:Raster.Palette; i,x,y:LONGINT;
BEGIN
	IF (LEN(data,0)=0) OR (LEN(data,1)=0) THEN RETURN END;
	F:=Raster.BGR888;
	Raster.Create(im,LEN(data,1),LEN(data,0),F);
	FOR y:=0 TO LEN(data,0)-1 DO
		FOR x:=0 TO LEN(data,1)-1 DO
			im.mem[y*im.bpr+3*x+0]:= CHR(data[y,x,2] MOD 256); 
			im.mem[y*im.bpr+3*x+1]:= CHR(data[y,x,1] MOD 256);
			im.mem[y*im.bpr+3*x+2]:= CHR(data[y,x,0] MOD 256);
		END;
	END;
END SIntRGBToImage;


PROCEDURE IntToImage*(CONST data:ARRAY [*,*] OF INTEGER; VAR palette: ARRAY [*,*] OF LONGINT; im:Raster.Image);  (*data >=0; palette values in range 0..10000H*)
VAR F:Raster.Format; pal:Raster.Palette; max,valI,i,col,x,y:LONGINT;
BEGIN
	IF (LEN(data,0)=0) OR (LEN(data,1)=0) THEN RETURN END;
	F:=Raster.BGR888; 
	max:=MAX(data MOD 10000H);(*!to do: avoid temp allocation*)
	Raster.Create(im,LEN(data,1),LEN(data,0),F);
	IF LEN(palette)=0 THEN 
		NEW(palette, max+1,3); 
		FOR col:=0 TO LEN(palette,0)-1 DO 
			valI:=col*10000H DIV LEN(palette,0); palette[col,0]:=valI; palette[col,1]:=valI; palette[col,2]:=valI
		END;
	END;
	FOR y:=0 TO LEN(data,0)-1 DO
		FOR x:=0 TO LEN(data,1)-1 DO
			valI:=LONG(data[y,x]) MOD 10000H;
			im.mem[y*im.bpr+3*x+0]:= CHR(palette[valI,2] DIV 256); (*variant for Format BGR888 - compress palette to 8 bit depth *)
			im.mem[y*im.bpr+3*x+1]:=CHR(palette[valI,1] DIV 256);
			im.mem[y*im.bpr+3*x+2]:=CHR(palette[valI,0] DIV 256);
		END;
	END;
END IntToImage;

PROCEDURE LIntToImage*(CONST data:ARRAY [*,*] OF LONGINT; VAR palette: ARRAY [*,*] OF LONGINT; im:Raster.Image); (*palette values in range 0..10000H*)
VAR F:Raster.Format; pal:Raster.Palette; max,valI,i,col,x,y:LONGINT;
BEGIN
	IF (LEN(data,0)=0) OR (LEN(data,1)=0) THEN RETURN END;
	F:=Raster.BGR888; 
	max:=MAX(data);
	IF im=NIL THEN NEW(im); END;
	Raster.Create(im,LEN(data,1),LEN(data,0),F);
	IF LEN(palette)=0 THEN 
		NEW(palette, max+1,3); 
		FOR col:=0 TO LEN(palette,0)-1 DO 
			valI:=col*10000H DIV LEN(palette,0); palette[col,0]:=valI; palette[col,1]:=valI; palette[col,2]:=valI
		END;
	END;
	FOR y:=0 TO LEN(data,0)-1 DO
		FOR x:=0 TO LEN(data,1)-1 DO
			valI:=data[y,x] MOD 10000H;
			im.mem[y*im.bpr+3*x+0]:= CHR(palette[valI,2] DIV 256); (*variant for Format BGR888 - compress palette to 8 bit depth *)
			im.mem[y*im.bpr+3*x+1]:=CHR(palette[valI,1] DIV 256);
			im.mem[y*im.bpr+3*x+2]:=CHR(palette[valI,0] DIV 256);
		END;
	END;
END LIntToImage;

PROCEDURE CombineLIntToImage*(CONST data,data1:ARRAY [*,*] OF LONGINT; VAR palette, palette1: ARRAY [*,*] OF LONGINT; threshold:LONGINT; im:Raster.Image); (*palette values in range 0..10000H; threshold indicates minimum value of data1 to take precedence over data*)
VAR F:Raster.Format; pal:Raster.Palette; max,valI, valI1,i,col,x,y:LONGINT;
BEGIN
	IF (LEN(data,0)=0) OR (LEN(data,1)=0) OR (LEN(data,0)#LEN(data1,0)) OR (LEN(data,1)#LEN(data1,1)) THEN RETURN END;
	F:=Raster.BGR888; 
	max:=MAX(data);
	IF im=NIL THEN NEW(im); END;
	Raster.Create(im,LEN(data,1),LEN(data,0),F);
	IF LEN(palette)=0 THEN 
		NEW(palette, max+1,3); 
		FOR col:=0 TO LEN(palette,0)-1 DO 
			valI:=col*10000H DIV LEN(palette,0); palette[col,0]:=valI; palette[col,1]:=valI; palette[col,2]:=valI
		END;
	END;
	IF LEN(palette1)=0 THEN 
		NEW(palette1, max+1,3); 
		FOR col:=0 TO LEN(palette1,0)-1 DO 
			valI:=col*10000H DIV LEN(palette1,0); palette1[col,0]:=valI;  palette1[col,1]:=10000H - valI-1; palette1[col,2]:=10000H - valI-1
		END;
	END;
	FOR y:=0 TO LEN(data,0)-1 DO
		FOR x:=0 TO LEN(data,1)-1 DO
			valI:=data[y,x] MOD 10000H; 
			valI1:=data[y,x] MOD 10000H; 
			IF valI1>= threshold THEN (* display overlay*)
				im.mem[y*im.bpr+3*x+0]:= CHR(palette1[valI1,2] DIV 256); (*variant for Format BGR888 - compress palette to 8 bit depth *)
				im.mem[y*im.bpr+3*x+1]:=CHR(palette1[valI1,1] DIV 256);
				im.mem[y*im.bpr+3*x+2]:=CHR(palette1[valI1,0] DIV 256);
			ELSE
				im.mem[y*im.bpr+3*x+0]:= CHR(palette[valI,2] DIV 256); (*variant for Format BGR888 - compress palette to 8 bit depth *)
				im.mem[y*im.bpr+3*x+1]:=CHR(palette[valI,1] DIV 256);
				im.mem[y*im.bpr+3*x+2]:=CHR(palette[valI,0] DIV 256);
			END;
		END;
	END;
END CombineLIntToImage;

PROCEDURE LIntBGRAToImage*(CONST data:ARRAY [*,*,*] OF SHORTINT; im:Raster.Image); 
VAR F:Raster.Format; pal:Raster.Palette; i,col,x,y:LONGINT; putMode:Raster.Mode;
BEGIN
	IF (LEN(data,0)=0) OR (LEN(data,1)=0) THEN RETURN END;
	Raster.InitMode(putMode, Raster.srcCopy);
	F:=Raster.BGRA8888;
	Raster.Create(im,LEN(data,1),LEN(data,0),F);
	FOR y:=0 TO LEN(data,0)-1 DO
		FOR x:=0 TO LEN(data,1)-1 DO
			Raster.Put(im,x,y, SYSTEM.VAL(Raster.Pixel,data[y,x]),putMode);
		END;
	END;
END LIntBGRAToImage;


PROCEDURE RealToImage*(CONST data:ARRAY [*,*] OF REAL; offset:LONGINT; gain:LONGREAL; im:Raster.Image); 
VAR F:Raster.Format; pal:Raster.Palette; max,valI,i,col,x,y:LONGINT; val:REAL; palette:ARRAY [*,*] OF LONGINT;
BEGIN
	IF (LEN(data,0)=0) OR (LEN(data,1)=0) THEN RETURN END;
	F:=Raster.BGR888; 
	Raster.Create(im,LEN(data,1),LEN(data,0),F);
	FOR y:=0 TO LEN(data,0)-1 DO
		FOR x:=0 TO LEN(data,1)-1 DO
			val:=data[y,x]; IF Reals.IsNaN(val) THEN val:=0 END;
			valI:=ENTIER(offset+gain*data[y,x]);
			im.mem[y*im.bpr+3*x+0]:= CHR(Clamp(valI,0,255)); (*variant for Format BGR888 - compress palette to 8 bit depth *)
			im.mem[y*im.bpr+3*x+1]:=CHR(Clamp(valI,0,255));
			im.mem[y*im.bpr+3*x+2]:=CHR(Clamp(valI,0,255));
		END;
	END;
END RealToImage;

PROCEDURE LRealToImage*(CONST data:ARRAY [*,*] OF LONGREAL; offset:LONGINT; gain:LONGREAL; im:Raster.Image); 
VAR F:Raster.Format; pal:Raster.Palette; max,valI,i,col,x,y:LONGINT; val:LONGREAL; palette:ARRAY [*,*] OF LONGINT;
BEGIN
	IF (LEN(data,0)=0) OR (LEN(data,1)=0) THEN RETURN END;
	F:=Raster.BGR888; 
	Raster.Create(im,LEN(data,1),LEN(data,0),F);
	FOR y:=0 TO LEN(data,0)-1 DO
		FOR x:=0 TO LEN(data,1)-1 DO
			val:=data[y,x]; IF Reals.IsNaNL(val) THEN val:=0 END;
			valI:=ENTIER(0.5+offset+gain*val);
			im.mem[y*im.bpr+3*x+0]:= CHR(Clamp(valI,0,255)); (*variant for Format BGR888 - compress palette to 8 bit depth *)
			im.mem[y*im.bpr+3*x+1]:=CHR(Clamp(valI,0,255));
			im.mem[y*im.bpr+3*x+2]:=CHR(Clamp(valI,0,255));
		END;
	END;
END LRealToImage;


PROCEDURE LRealToImageBR*(CONST data:ARRAY [*,*] OF LONGREAL; offset:LONGINT; gain:LONGREAL; im:Raster.Image); 
VAR F:Raster.Format; pal:Raster.Palette; max,valI,i,col,x,y:LONGINT; val:LONGREAL; palette:ARRAY [*,*] OF LONGINT;
BEGIN
	IF (LEN(data,0)=0) OR (LEN(data,1)=0) THEN RETURN END;
	F:=Raster.BGR888; 
	Raster.Create(im,LEN(data,1),LEN(data,0),F);
	FOR y:=0 TO LEN(data,0)-1 DO
		FOR x:=0 TO LEN(data,1)-1 DO
			val:=data[y,x]; IF Reals.IsNaNL(val) THEN val:=0 END;
			valI:=ENTIER(0.5+offset+gain*val);
			IF valI<0 THEN
				im.mem[y*im.bpr+3*x+0]:= CHR(-Clamp(valI,-255,0)); 
				im.mem[y*im.bpr+3*x+1]:= 0X;
				im.mem[y*im.bpr+3*x+2]:= 0X;
			ELSE
				im.mem[y*im.bpr+3*x+0]:= 0X;
				im.mem[y*im.bpr+3*x+1]:= 0X;
				im.mem[y*im.bpr+3*x+2]:=CHR(Clamp(valI,0,255));
			END;
		END;
	END;
END LRealToImageBR;

PROCEDURE LRealToImageHeat*(CONST data:ARRAY [*,*] OF LONGREAL; offset:LONGINT; gain:LONGREAL; im:Raster.Image); 
VAR F:Raster.Format; pal:Raster.Palette; max,valI,i,col,x,y:LONGINT; val:LONGREAL; palette:ARRAY [*,*] OF LONGINT;
BEGIN
	IF (LEN(data,0)=0) OR (LEN(data,1)=0) THEN RETURN END;
	F:=Raster.BGR888; 
	Raster.Create(im,LEN(data,1),LEN(data,0),F);
	FOR y:=0 TO LEN(data,0)-1 DO
		FOR x:=0 TO LEN(data,1)-1 DO
			val:=data[y,x]; 
			IF ~Reals.IsNaNL(val) THEN 
				valI:=ENTIER(0.5+offset+gain*val)
			END;
			IF Reals.IsNaNL(val) THEN
				im.mem[y*im.bpr+3*x+0]:= 0X; 
				im.mem[y*im.bpr+3*x+1]:= 0X;
				im.mem[y*im.bpr+3*x+2]:= 0X;
			ELSIF valI<0 THEN
				im.mem[y*im.bpr+3*x+0]:= CHR(-Clamp(valI,-255,0)); 
				im.mem[y*im.bpr+3*x+1]:= CHR(255+Clamp(valI DIV 2,-255,0));(*! TO DO: make nicer colors*)
				im.mem[y*im.bpr+3*x+2]:= 0X;
			ELSE
				im.mem[y*im.bpr+3*x+0]:= 0X;
				im.mem[y*im.bpr+3*x+1]:= CHR(255-Clamp(valI DIV 2,0,255));
				im.mem[y*im.bpr+3*x+2]:=CHR(Clamp(valI,0,255));
			END;
		END;
	END;
END LRealToImageHeat;

PROCEDURE LRealToImageLUT*(CONST data:ARRAY [*,*] OF LONGREAL; offset:LONGINT; gain:LONGREAL; im:Raster.Image); 
VAR F:Raster.Format; max,valI,i,col,x,y:LONGINT; val:LONGREAL; palette:ARRAY [*,*] OF LONGINT;
BEGIN
	IF (LEN(data,0)=0) OR (LEN(data,1)=0) THEN RETURN END;
	
	
	FOR y:=0 TO LEN(data,0)-1 DO
		FOR x:=0 TO LEN(data,1)-1 DO
			val:=data[y,x]; 
			IF ~Reals.IsNaNL(val) THEN 
				valI:=ENTIER(0.5+offset+gain*val);
				im.mem[y*im.bpr+x(*  *im.fmt.bpp*)]:=CHR(Clamp(valI,0,255));
			ELSE
				im.mem[y*im.bpr+x(*  *im.fmt.bpp*)]:= 0X; 
			END;
		END;
	END;
END LRealToImageLUT;



PROCEDURE LRealRGBToImage*(CONST R,G,B:ARRAY [*,*] OF LONGREAL; im:Raster.Image); 
VAR x,y, w,h:LONGINT; 
	gain, r,g,b :LONGREAL; 
BEGIN
	w:=LEN(R,1); h:=LEN(R,0);
	r:=MAX(R); IF Reals.IsNaNL(r) THEN r:=0 END;
	g:=MAX(G); IF Reals.IsNaNL(g) THEN g:=0 END;
	b:=MAX(B); IF Reals.IsNaNL(b) THEN b:=0 END;
	gain:=255/MAX(r, MAX(g,b)); 
	Raster.Create(im,w,h,Raster.BGR888);
	FOR y:=0 TO h-1 DO
		FOR x:=0 TO w-1 DO
			im.mem[y*im.bpr+3*x+0]:= CHR(ENTIER(gain*B[y,x])); 
			im.mem[y*im.bpr+3*x+1]:= CHR(ENTIER(gain*G[y,x]));
			im.mem[y*im.bpr+3*x+2]:= CHR(ENTIER(gain*R[y,x]));
		END;
	END;
END LRealRGBToImage;

PROCEDURE LRealRGBToImageB*(CONST R,G,B:ARRAY [*,*] OF LONGREAL;  offset, gain:LONGREAL; im:Raster.Image); 
VAR x,y, w,h:LONGINT; 
BEGIN
	w:=LEN(R,1); h:=LEN(R,0);
	Raster.Create(im,w,h,Raster.BGR888);
	FOR y:=0 TO h-1 DO
		FOR x:=0 TO w-1 DO
			im.mem[y*im.bpr+3*x+0]:= CHR(ENTIER(offset+gain*B[y,x])); 
			im.mem[y*im.bpr+3*x+1]:= CHR(ENTIER(offset+gain*G[y,x]));
			im.mem[y*im.bpr+3*x+2]:= CHR(ENTIER(offset+gain*R[y,x]));
		END;
	END;
END LRealRGBToImageB;

PROCEDURE BoolToImage*(CONST data:ARRAY [*,*] OF BOOLEAN; im:Raster.Image); 
VAR y,x:LONGINT; val:REAL; SIntData: ARRAY [*,*] OF SHORTINT; palette: ARRAY [*,*] OF LONGINT;
BEGIN
	NEW(SIntData,LEN(data,0),LEN(data,1));
	FOR y:=0 TO LEN(data,0)-1 DO
		FOR x:=0 TO LEN(data,1)-1 DO
			IF data[y,x] THEN SIntData[y,x]:=127 ELSE SIntData[y,x]:=0 END;
		END;
	END;
	SIntToImage(SIntData, palette, im);
END BoolToImage;

PROCEDURE ImageToArray*(img:Raster.Image; VAR data: ARRAY [?] OF INTEGER);
VAR row,col,p: LONGINT;
BEGIN
	p:=0;
	IF img.fmt.code=Raster.bgr888 THEN 
		NEW(data, 3, img.height, img.width) ;
		FOR row:=0 TO img.height-1 DO
			FOR col:=0 TO img.width-1 DO
				data[0,row,col]:= ORD(img.mem[p+2]);
				data[1,row,col]:= ORD(img.mem[p+1]);
				data[2,row,col]:= ORD(img.mem[p]);
				INC(p,3);
			END;
		END;
	ELSIF img.fmt.code=RasterPixelFormats.yuv422 THEN 
		NEW(data, 3, img.height, img.width) ;
		FOR row:=0 TO img.height-1 DO
			FOR col:=0 TO img.width-1 BY 2 DO
				data[0,row,col]:= ORD(img.mem[p]);
				data[1,row,col]:= ORD(img.mem[p+1]);
				data[2,row,col]:= ORD(img.mem[p+3]);
				
				data[0,row,col+1]:= ORD(img.mem[p+2]);
				data[1,row,col+1]:= ORD(img.mem[p+1]);
				data[2,row,col+1]:= ORD(img.mem[p+3]);
				INC(p,4);
			END;
		END;
	ELSIF img.fmt.code=Raster.bgra8888 THEN 
		NEW(data, 4, img.height, img.width) ;
		FOR row:=0 TO img.height-1 DO
			FOR col:=0 TO img.width-1 DO
				data[0,row,col]:= ORD(img.mem[p+2]);
				data[1,row,col]:= ORD(img.mem[p+1]);
				data[2,row,col]:= ORD(img.mem[p]);
				data[3,row,col]:= ORD(img.mem[p+3]);
				INC(p,4);
			END;
		END;
	END;
END ImageToArray;


(*
PROCEDURE IntegrateLReal(CONST m: ARRAY OF LONGREAL);
VAR max:LONGREAL;
BEGIN
	max:=MAX(m); min:=MIN(m);
	
END IntegrateLReal;
*)

PROCEDURE Clamp(val:LONGINT; min,max:LONGINT):LONGINT;
BEGIN
	IF val>max THEN RETURN max
	ELSIF val<min THEN RETURN min
	ELSE RETURN val
	END;
END Clamp;


PROCEDURE Test*;
VAR 
	s:ARRAY [*,*] OF SHORTINT;
	i:ARRAY [*,*] OF INTEGER;
	l:ARRAY [*,*] OF LONGINT;
	r:ARRAY [*,*] OF REAL;
	lr:ARRAY [*,*] OF LONGREAL;
	p:ARRAY [*,*] OF LONGINT;
	ind:LONGINT;
	pw, pw1, pw2, pw3, pw4, pw5 : WM.BufferWindow;
	res, w, h, x : LONGINT;
	
BEGIN
	
	NEW(s,100,100); s[50..80,40..90]:=100;
	NEW(i,100,100); i[50..80,40..90]:=100; 
	NEW(l,100,100); l[50..80,40..90]:=100; 
	NEW(r,100,100); r[50..80,40..90]:=100; 
	NEW(lr,100,100); lr[50..80,40..90]:=100; 

	NEW(p,256,3);
	FOR ind:=0 TO 255 DO
		p[ind,0]:=ind*256; p[ind,2]:=(255-ind)*256
	END;
	
	w:=100; h:=100; x:=50;
	NEW(pw, w, h, TRUE); pw.SetTitle(Strings.NewString("pw"));
	NEW(pw1, w, h, TRUE);
	NEW(pw2, w, h, TRUE);
	NEW(pw3, w, h, TRUE);
	NEW(pw4, w, h, TRUE);
	NEW(pw5, w, h, TRUE);
	
	SIntToImage(s,p,pw.img);
	IntToImage(i,p,pw1.img);
	LIntToImage(l,p,pw2.img);
	RealToImage(r,128,1,pw3.img);
	LRealToImage(lr,128,1,pw4.img);
	LRealToImageHeat(lr,128,1,pw5.img);
	
	WM.DefaultAddWindow(pw);
	WM.DefaultAddWindow(pw1);
	WM.DefaultAddWindow(pw2);
	WM.DefaultAddWindow(pw3);
	WM.DefaultAddWindow(pw4);
	WM.DefaultAddWindow(pw5);

	(*
	NEW(p,256,3);
	FOR ind:=0 TO 255 DO
		p[ind,0]:=ind*256; p[ind,2]:=(255-ind)*256
	END;
	
	NEW(l,100,100); l[50..80,40..90]:=80; l[30..60,20..50]:=l[30..60,20..50]+120;  Integrate(LIntToImage(l,p),"color"); (* integrate as Gadgets Frame*)
	
	ToWindow(LIntToImage(l,p),"Hello.Pict"); (* show as separate Windows document window. use postfix ".Pict" or similar to allow storage*)
	
	NEW(imF); ImageGadgets.Init(imF,LIntToImage(l,p)); 
	ShowGadget("holla.Pict",imF); (* integrate as Gadgets Document in Oberon GUI. use postfix ".Pict" or similar to allow storage*)
	*)
END Test;


END MatrixRaster.

System.FreeDownTo
MatrixRaster~
MatrixRaster.Test ~
