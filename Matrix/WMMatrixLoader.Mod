MODULE WMMatrixLoader; (** AUTHOR "Patrick Hunziker"; PURPOSE "Glue for transparent visualization of matrix data files"; *)

(*
Visualize Matrices in GUI Windows.
to enable direct opening from File List Window, add this to the FileHandler section in Configuration.XML:
			<Section name="mta">
				<Setting name="Open" value="WMMatrixLoader.Open"/>
			</Section>
*)

IMPORT WMWindowManager, WMMatrix, WMStack, Files, Streams, Strings, Options, MatrixBase, MatrixUtilities, Commands;
	
CONST
	(* display options *)
	MaxIntensity*=1;
	SumIntensity*=2;
	
PROCEDURE Load*(CONST name:Files.FileName; orientation:LONGINT; options:Options.Options): WMWindowManager.Window;
VAR d: ARRAY [?] OF MatrixBase.Datatype;
	d2: ARRAY [*,*] OF MatrixBase.Datatype;
	f:Files.File;
	r:Files.Reader;
	mWindow:WMMatrix.Window;
	sWindow:WMStack.Window;
	title: Files.FileName;
	i,x,y:LONGINT;
BEGIN
	f:=Files.Old(name);
	IF f#NIL THEN Files.OpenReader(r,f,0);
		d:=MatrixUtilities.LoadLR(r);
		IF DIM(d)=2 THEN 
			NEW(mWindow, d, name);
			mWindow.AddWindow;
			RETURN mWindow;
		ELSIF DIM(d)=3 THEN
			IF (options#NIL)&options.GetFlag("max") THEN
				IF orientation=0 THEN
					d2:=d[0,..,..]; 
					FOR x:=0 TO LEN(d,1)-1 DO
						FOR y:=0 TO LEN(d,2)-1 DO
							d2[x,y]:=MAX(d[..,x,y]);
						END;
					END;
				ELSIF orientation=1 THEN
					d2:=d[..,0,..]; 
					FOR x:=0 TO LEN(d,0)-1 DO
						FOR y:=0 TO LEN(d,2)-1 DO
							d2[x,y]:=MAX(d[x,..,y]);
						END;
					END;
				ELSIF orientation=2 THEN
					d2:=d[..,..,0]; 
					FOR x:=0 TO LEN(d,0)-1 DO
						FOR y:=0 TO LEN(d,1)-1 DO
							d2[x,y]:=MAX(d[x,y,..]);
						END;
					END;
				END;
				title:="Max "; Strings.Append(title,name);
				NEW(mWindow, d2, title);
				mWindow.AddWindow;
				RETURN mWindow;
			ELSIF (options#NIL)&options.GetFlag("sum") THEN
				IF orientation=0 THEN
					d2:=d[0,..,..]; 
					FOR i:=1 TO LEN(d,0)-1 DO d2:=d2+d[i,..,..] END;
				ELSIF orientation=1 THEN
					d2:=d[..,0,..]; 
					FOR i:=1 TO LEN(d,1)-1 DO d2:=d2+d[..,i,..] END;
				ELSIF orientation=2 THEN
					d2:=d[..,..,0]; 
					FOR i:=1 TO LEN(d,2)-1 DO d2:=d2+d[..,..,i] END;
				END;
				title:="Sum "; Strings.Append(title,name);
				NEW(mWindow, d2, title);
				mWindow.AddWindow;
				RETURN mWindow;
			ELSE
				NEW(sWindow, d, name,orientation);
				sWindow.AddWindow;
				RETURN sWindow;
			END;
		ELSE RETURN NIL
		END;
	ELSE RETURN NIL
	END;
END Load;

PROCEDURE Open*(context:Commands.Context);
VAR name: Files.FileName; w:WMWindowManager.Window; orientation:LONGINT;
VAR options : Options.Options; 
BEGIN
	NEW(options);
	options.Add("m", "max", Options.Flag);
	options.Add("s", "sum", Options.Flag);
	IF (context#NIL) & options.Parse(context.arg, context.error) & context.arg.GetString(name) THEN
		IF ~context.arg.GetInteger(orientation ,FALSE) THEN orientation:=0 END;
		w:=Load(name, orientation,options);
	END;
END Open;


END WMMatrixLoader.

WMMatrixLoader.Open A.MtA ~ (* matrix example *)
WMMatrixLoader.Open -s BraidVolume16.MtA ~ (* sum projection, volume example *)
WMMatrixLoader.Open -m BraidVolume16.MtA 0 ~ (* max projection, volume example *)
WMMatrixLoader.Open -m BraidVolume16.MtA 1 ~ (* max projection, volume example *)
WMMatrixLoader.Open -m BraidVolume16.MtA 2 ~ (* max projection, volume example *)



WMMatrixLoader.Open BraidVolume16.MtA 1~ (* volume example *)
WMMatrixLoader.Open BraidVolume16.MtA 2~ (* volume example *)
