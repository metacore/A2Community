MODULE WMMatrixLoader; (** AUTHOR "Patrick Hunziker"; PURPOSE "Glue for transparent visualization of matrix data files"; *)

(*
Visualize Matrices in GUI Windows.
to enable direct opening from File List Window, add this to the FileHandler section in Configuration.XML:
			<Section name="mta">
				<Setting name="Open" value="WMMatrixLoader.Open"/>
			</Section>
*)

IMPORT WMWindowManager, WMMatrix, WMStack, Files, Streams, MatrixBase, MatrixUtilities, Commands;
	
PROCEDURE Load*(CONST name:Files.FileName): WMWindowManager.Window;
VAR d: ARRAY [?] OF MatrixBase.Datatype;
	f:Files.File;
	r:Files.Reader;
	mWindow:WMMatrix.Window;
	sWindow:WMStack.Window;
BEGIN
	f:=Files.Old(name);
	IF f#NIL THEN Files.OpenReader(r,f,0);
		d:=MatrixUtilities.LoadLR(r);
		IF DIM(d)=2 THEN 
			NEW(mWindow, d, name);
			mWindow.AddWindow;
			RETURN mWindow;
		ELSIF DIM(d)=3 THEN
			NEW(sWindow, d, name,0);
			sWindow.AddWindow;
			RETURN sWindow;
		END;
	END;
END Load;

PROCEDURE Open*(context:Commands.Context);
VAR name: Files.FileName; w:WMWindowManager.Window;
BEGIN
	IF (context#NIL) & context.arg.GetString(name) THEN
		w:=Load(name);
	END;
END Open;


END WMMatrixLoader.

WMMatrixLoader.Open A.MtA ~ (* matrix example *)
WMMatrixLoader.Open BraidVolume64.MtA~ (* volume example *)
