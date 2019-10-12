MODULE ModuleTestingSym; (** AUTHOR "Patrick Hunziker"; PURPOSE "automated module testing of modules and procedures with {TEST} flag"; *)
(*can also do without TestSuite if standalone is necessary*)

IMPORT Strings, Modules, Compiler, Files, Streams, Commands, Options, Diagnostics, TestSuite;

CONST 
	LabeledProcTest* =2;

TYPE FileTestProcedure=PROCEDURE (context:Commands.Context;tester: TestSuite.Tester; CONST modName,procName:ARRAY OF CHAR);
TYPE AddItemProcedure=	PROCEDURE {DELEGATE}(itemType, testType: INTEGER;  CONST name: ARRAY OF CHAR; success: BOOLEAN);

VAR tester: TestSuite.Tester;

PROCEDURE ModuleTest*(context:Commands.Context);
VAR path, extension, testerName: Files.FileName;
	options:Options.Options;
	diag:Diagnostics.Diagnostics;
BEGIN
	NEW(options); options.Add("t","Tester",Options.String);
	IF options.Parse(context.arg, context.error) & options.GetString("Tester",testerName) THEN 
		NEW(diag);
		NEW(tester,diag);
		(* ... *)
	END;
	IF context.arg.GetString(path) & context.arg.GetString(extension) THEN
		IF tester#NIL THEN	EnumerateSymbolFileList(context, tester.AddItem, path, extension, FileTestProc);
		ELSE EnumerateSymbolFileList(context, NIL, path, extension, FileTestProc);
		END;
		
	ELSE
		HALT(200)
	END;
END ModuleTest;

PROCEDURE FileTestProc(context:Commands.Context; tester:TestSuite.Tester; CONST modName,procName:ARRAY OF CHAR);
VAR fullName, msg: ARRAY 256 OF CHAR; res:INTEGER;
BEGIN
	COPY(modName, fullName); Strings.Append(fullName, "."); Strings.Append(fullName, procName);
	context.out.String("testing "); context.out.String(fullName); context.out.String(": "); context.out.Update;
	Commands.Activate(fullName,NIL,{Commands.Wait},res,msg);
	context.out.String(msg); context.out.Int(res,6); context.out.Ln; context.out.Update;
	
	IF tester#NIL THEN tester.AddItem(TestSuite.Test, LabeledProcTest, fullName, res=0) END;
END FileTestProc;


PROCEDURE EnumerateSymbolFileList(context:Commands.Context; addItem: AddItemProcedure; CONST path,extension:ARRAY OF CHAR; testProcEnum: FileTestProcedure);
VAR e:Files.Enumerator; size:Files.Size; flags:SET; time, date: SIGNED32; pos:SIZE;
	mask, fileName:Files.FileName; 
	f:Files.File; r:Files.Reader;
BEGIN
	COPY(path,mask); Strings.Append(mask,extension);
	NEW(e); e.Open(mask, {});
	WHILE e.HasMoreEntries() & e.GetEntry(fileName,flags,time,date,size) DO
		pos:=Strings.Pos(extension,fileName); 
		f:=Files.Old(fileName);
		Files.OpenReader(r,f,0);
		EnumerateSymbolFileTestProcs(context, addItem, r, testProcEnum);
	END;
END EnumerateSymbolFileList;


PROCEDURE EnumerateSymbolFileTestProcs(context:Commands.Context; addItem:AddItemProcedure; r:Streams.Reader; testProcEnum: FileTestProcedure);
VAR line, keyword, modName, procName, arrow: ARRAY 256 OF CHAR;
	leftbracket, rightbracket, modifier, pos: SIZE;
BEGIN
	WHILE r.GetString(keyword) & (r.res#Streams.Ok) & (keyword#"MODULE")DO END;
	IF r.res#Streams.Ok THEN 
		RETURN
	ELSE
		IGNORE r.GetString(modName);
		pos:=Strings.Pos(";",modName); IF pos>0 THEN modName[pos]:=0X END;
		WHILE r.res=Streams.Ok DO
			r.SkipWhitespace();
			IF r.GetString(keyword) & (keyword="PROCEDURE") & r.GetString(arrow)  THEN (*disentangle this: 	PROCEDURE ^ {TEST} Test1*; *)
				r.Ln(line);
				leftbracket:= Strings.GenericPos("{", 0, line, FALSE,FALSE);
				IF leftbracket>=0 THEN
					rightbracket:= Strings.GenericPos("}", leftbracket, line, FALSE,FALSE);
					modifier:= Strings.GenericPos("TEST", leftbracket, line, FALSE,FALSE);
					IF (modifier>leftbracket) &(modifier<rightbracket) THEN
						Strings.Delete(line,0,rightbracket+2);
						pos:=Strings.Pos("*", line); line[pos]:=0X;
						COPY(line,procName);
						testProcEnum(context, tester, modName,procName);
					END;
				END;
			END;
		END;	
	END;
END EnumerateSymbolFileTestProcs;

(*
PROCEDURE Install*;
VAR f: Files.File; w:Files.Writer;
BEGIN
	NEW(registry); 
	f:=Files.Old(ModuleTestingDB);
	IF f=NIL THEN f:=Files.New(ModuleTestingDB); Files.Register(f); Files.OpenWriter(w,f,0); w.String("(* database for ModuleTesting.Mod *)"); w.Ln; w.Update; END;
	Compiler.TestModule:=registry.Register
END Install;
*)

PROCEDURE log(type:INTEGER; CONST name:ARRAY OF CHAR; success:BOOLEAN);
VAR c:Commands.Context;
BEGIN
	c:=Commands.GetContext();
	c.out.Int(type,0); c.out.String(" "); c.out.String(name);
	IF success THEN c.out.String(" success "); ELSE c.out.String(" failure "); END;
	c.out.Ln; c.out.Update;
END log;

PROCEDURE ReportResults*(context:Commands.Context);
VAR item: TestSuite.TestResult;
BEGIN
	IF tester#NIL THEN
		context.out.String("tests: "); context.out.Ln;
		tester.Enumerate(0, log);
		context.out.String("results: "); context.out.Ln;
		tester.Enumerate(1, log);
	END;
END ReportResults;


PROCEDURE Uninstall*;
BEGIN
	(*Compiler.TestModule:=NIL*)
END Uninstall;

BEGIN
	Modules.InstallTermHandler(Uninstall);
END ModuleTestingSym. 

System.FreeDownTo  ModuleTestingSym~
ModuleTestingSym.Install ~
ModuleTestingSym.Uninstall ~

(*test all TEST modules/procedures in symbol files in a path*)
(*ModuleTestingSym.TestDatabase [dbname] ~ *)
ModuleTestingSym.ModuleTest -t=TesterFile "work/*" ".Sym" ~
ModuleTestingSym.ReportResults~ 


