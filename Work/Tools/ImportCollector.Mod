MODULE ImportCollector; (** AUTHOR "SAGE"; PURPOSE "Utility for collecting of all imported modules for specified applications"; *)

IMPORT
	Machine, Commands, Files, Options, Strings, UTF8Strings,
	Diagnostics, ModuleParser, Vector, NewContainers, Zip, ZipTool, KernelLog;

CONST
	DefaultOutputFilename = "CollectedModules.zip";

TYPE

	ModulesValue = RECORD(Vector.Value)
		module: ModuleParser.Module
	END;

	ModulesVector = OBJECT (Vector.Vector)
	TYPE
		ModulesValues = POINTER TO ARRAY OF ModulesValue;
	VAR
		array: ModulesValues;

		(* for speedup of Contains procedure *)
		null: ModuleParser.Module;

		PROCEDURE &Init;
		BEGIN
			NEW(null, NIL);
			NEW(null.ident);
			NEW(null.ident.name, 257);
			New(Vector.INITIAL_SIZE, SIZEOF(ModulesValue),
				{Vector.SORTED}, Create, Compare, NIL)
		END Init;

		PROCEDURE Create(nSize: LONGINT; VAR pArray: ANY; VAR adrArray: ADDRESS);
		BEGIN
			NEW(array, nSize);
			pArray := array; adrArray := ADDRESSOF(array^[0])
		END Create;

		PROCEDURE Compare(iLeft: LONGINT; VAR right: Vector.Value): LONGINT;
		BEGIN
			RETURN UTF8Strings.Compare(array^[iLeft].module.ident.name^,
				right(ModulesValue).module.ident.name^)
		END Compare;

		PROCEDURE Add(module: ModuleParser.Module);
		VAR
			v: ModulesValue;
			posDummy: LONGINT
		BEGIN
			v.module := module;
			posDummy := AddInternal(v)
		END Add;

		PROCEDURE Contains(CONST name: ARRAY OF CHAR): BOOLEAN;
		VAR
			v: ModulesValue;
		BEGIN
			COPY(name, null.ident.name^);
			v.module := null;
			RETURN IndexOfInternal(v) >= 0
		END Contains;

		PROCEDURE Get(pos: LONGINT): ModuleParser.Module;
		BEGIN
			ASSERT((pos >= 0) & (pos < Count), 101);
			RETURN array[pos].module
		END Get;

	END ModulesVector;

	RememberMapValue = RECORD(Vector.Value)
		key: Files.FileName;
		list: NewContainers.StringVector;
	END;

	RememberMap = OBJECT(Vector.Vector)
	TYPE
		RememberMapValues = POINTER TO ARRAY OF RememberMapValue;
	VAR
		array: RememberMapValues;

		PROCEDURE &Init;
		BEGIN
			New(Vector.INITIAL_SIZE, SIZEOF(RememberMapValue),
				{Vector.SORTED}, Create, Compare, NIL)
		END Init;

		PROCEDURE Create(nSize: LONGINT; VAR pArray: ANY; VAR adrArray: ADDRESS);
		BEGIN
			NEW(array, nSize);
			pArray := array; adrArray := ADDRESSOF(array^[0])
		END Create;

		PROCEDURE Compare(iLeft: LONGINT; VAR right: Vector.Value): LONGINT;
		BEGIN
			RETURN UTF8Strings.Compare(array^[iLeft].key,
				right(RememberMapValue).key)
		END Compare;
		
		PROCEDURE Add(CONST key: ARRAY OF CHAR; list: NewContainers.StringVector);
		VAR
			v: RememberMapValue;
			posDummy: LONGINT;
		BEGIN
			COPY(key, v.key);
			v.list := list;
			posDummy := AddInternal(v)
		END Add;
		
		PROCEDURE Contains(CONST key: ARRAY OF CHAR): BOOLEAN;
		VAR
			v: RememberMapValue;
		BEGIN
			COPY(key, v.key);
			RETURN IndexOfInternal(v) >= 0
		END Contains;

		PROCEDURE Get(CONST key: ARRAY OF CHAR): RememberMapValue;
		VAR
			v: RememberMapValue;
			pos: LONGINT;
		BEGIN
			COPY(key, v.key);
			pos := IndexOfInternal(v);
			ASSERT((pos >= 0) & (pos < Count), 101);
			RETURN array[pos]
		END Get;

	END RememberMap;

VAR
	mapRemember: RememberMap;

PROCEDURE FileExists(CONST fileName: ARRAY OF CHAR): BOOLEAN;
VAR
	file: Files.File;
BEGIN
	file := Files.Old(fileName);
	RETURN (file # NIL)
END FileExists;

(* Simple heuristics that tries to find the filename of a given module name *)
PROCEDURE FindCorrectFilename(CONST path, moduleName: ARRAY OF CHAR): Files.FileName;

	PROCEDURE GenerateFilename(CONST path, prefix, moduleName: ARRAY OF CHAR): Files.FileName;
	VAR
		fileName: Files.FileName;
	BEGIN
		COPY(path, fileName);
		Strings.Append(fileName, prefix);
		Strings.Append(fileName, moduleName);
		Strings.Append(fileName, ".Mod");
		RETURN fileName
	END GenerateFilename;

VAR
	fileName: Files.FileName;
BEGIN
	fileName := GenerateFilename(path, "", moduleName);
	IF ~FileExists(fileName) THEN
		fileName := GenerateFilename(path, "I386.", moduleName);
		IF ~FileExists(fileName) THEN
			fileName := GenerateFilename(path, "Win32.", moduleName);
			IF ~FileExists(fileName) THEN
				fileName := GenerateFilename(path, "Unix.", moduleName);
				IF ~FileExists(fileName) THEN
					COPY(moduleName, fileName)
				END
			END
		END
	END;
	RETURN fileName
END FindCorrectFilename;

(* Simple heuristics that tries to find the filepath of a given module name *)
PROCEDURE FindCorrectFilepath(CONST moduleName: ARRAY OF CHAR; vecModulesPaths: NewContainers.StringVector): Files.FileName;
VAR
	pathName: Files.FileName;
	i: LONGINT;
BEGIN
	IF vecModulesPaths.Count = 0 THEN
		pathName := FindCorrectFilename("", moduleName)
	ELSE
		i := 0;
		REPEAT
			pathName := FindCorrectFilename(vecModulesPaths.Get(i)^, moduleName);
			INC(i)
		UNTIL FileExists(pathName) OR (i > vecModulesPaths.Count - 1)
	END;
	RETURN pathName
END FindCorrectFilepath;

PROCEDURE ProcessModule(context: Commands.Context; vecModules: ModulesVector; vecModulesNotFound, vecModulesPaths: NewContainers.StringVector; CONST modName: ARRAY OF CHAR);

	PROCEDURE ParseModule(CONST modName: ARRAY OF CHAR): ModuleParser.Module;
	VAR
		module: ModuleParser.Module;
		diag: Diagnostics.Diagnostics;
	BEGIN
		module := ModuleParser.ParseFile(FindCorrectFilepath(modName, vecModulesPaths), diag);
		RETURN module
	END ParseModule;

	PROCEDURE ProperModuleInfo(import: ModuleParser.Import): ModuleParser.InfoItem;
	BEGIN
		IF (import.alias # NIL) & (import.alias.name^ # "") THEN
			RETURN import.alias
		ELSE
			RETURN import.ident
		END
	END ProperModuleInfo;

VAR
	module: ModuleParser.Module;
	import: ModuleParser.Import;
	name: Strings.String;
	info: ModuleParser.InfoItem;
	posDummy: LONGINT;
BEGIN
	name := Strings.NewString(modName);
	IF Strings.EndsWith(".Mod", name^) THEN
		name^[Strings.Length(name^) - 4] := 0X
	END;
	IF vecModules.Contains(name^) OR (vecModulesNotFound.IndexOf(name^) >= 0) THEN
		RETURN
	END;
	module := ParseModule(name^);
	IF module = NIL THEN
		posDummy := vecModulesNotFound.Add(name^);
		RETURN
	END;
	vecModules.Add(module);
	context.out.String("Added "); context.out.String(module.ident.name^);
	context.out.Ln; context.out.Update;
	import := module.importList;
	WHILE import # NIL DO
		info := ProperModuleInfo(import);
		IF (info # NIL) & ~vecModules.Contains(info.name^) THEN
			ProcessModule(context, vecModules, vecModulesNotFound, vecModulesPaths, info.name^)
		END;
		IF import.next # NIL THEN
			import := import.next(ModuleParser.Import)
		ELSE
			import := NIL
		END
	END
END ProcessModule;

(* Get the list of actually imported modules *)
(*
PROCEDURE ActualImports(CONST modName: ARRAY OF CHAR);
VAR
	objModule: Modules.Module;
	res: LONGINT;
	msg: ARRAY 8 OF CHAR;
	i: LONGINT;
BEGIN
	objModule := Modules.ThisModule(modName, res, msg);
	IF (objModule # NIL) & (res = Modules.Ok) THEN
		KernelLog.Ln;
		KernelLog.String("Module: ");
		KernelLog.String(objModule.name);
		KernelLog.String(", imports: ");
		IF objModule.module # NIL THEN
			FOR i := 0 TO LEN(objModule.module) - 1 DO
				KernelLog.String(objModule.module[i].name);
				IF i # LEN(objModule.module) - 1 THEN
					KernelLog.String(", ");
				END
			END
		END;
		KernelLog.Ln
	END
END ActualImports;
*)

PROCEDURE Output(CONST sFileName, sRememberKey: ARRAY OF CHAR; vecModules: ModulesVector; vecModulesNotFound, vecModulesExcludes: NewContainers.StringVector): BOOLEAN;
VAR
	i: LONGINT;
	m: ModuleParser.Module;
	archive: Zip.Archive;
	res, posDummy: LONGINT;
	outputFilename: Files.FileName;
	listRemember: NewContainers.StringVector;
	item: RememberMapValue;
	sysextension: ARRAY 6 OF CHAR;
BEGIN

	Machine.GetConfig("ObjectFileExtension", sysextension);
	IF sysextension = "" THEN
		COPY(Machine.DefaultObjectFileExtension, sysextension)
	END;
	KernelLog.String(sysextension); KernelLog.Ln;

	listRemember := NIL;
	IF sRememberKey # "" THEN
		IF mapRemember.Contains(sRememberKey) THEN
			item := mapRemember.Get(sRememberKey);
			item.list.Clear;
			listRemember := item.list
		ELSE
			NEW(listRemember, {Vector.SORTED, Vector.NO_DUPLICATES});
			mapRemember.Add(sRememberKey, listRemember)
		END
	END;

	archive := Zip.CreateArchive(sFileName, res);
	IF (archive # NIL) & (res = Zip.Ok) THEN
		FOR i := 0 TO vecModules.Count - 1 DO
			m := vecModules.Get(i);
			IF (m # NIL) & (vecModulesExcludes.IndexOf(m.ident.name^) = -1) THEN

				(** TODO: Implement more robust generation of file name
					as in Modules.ThisModule. Or propose ETHZ to add real
					file name as field to Modules.Module *)
				COPY(m.ident.name^, outputFilename);
				Strings.Concat(outputFilename, sysextension, outputFilename);

				ZipTool.AddFile(archive, outputFilename, outputFilename,
					Zip.BestCompression, Zip.DefaultStrategy, res);

				IF res = Zip.Ok THEN
					IF listRemember # NIL THEN
						posDummy := listRemember.Add(m.ident.name^)
					END
				ELSIF vecModulesNotFound.IndexOf(m.ident.name^) = -1 THEN
					posDummy := vecModulesNotFound.Add(m.ident.name^)
				END
			END
		END;
		RETURN TRUE
	END;

	RETURN FALSE
END Output;

PROCEDURE ParseSemicolonList(CONST list: ARRAY OF CHAR; vecList: NewContainers.StringVector);
VAR
	j, k, posDummy: LONGINT;
	part: Files.FileName;

	PROCEDURE AddPart;
	BEGIN
		IF k > 0 THEN
			part[k] := 0X;
			IF (part # "") & (vecList.IndexOf(part) = -1) THEN
				posDummy := vecList.Add(part)
			END;
			k := 0
		END
	END AddPart;

BEGIN
	k := 0;
	WHILE list[j] # 0X DO
		IF list[j] = ';' THEN
			AddPart
		ELSE
			part[k] := list[j]; INC(k)
		END;
		INC(j)
	END;
	AddPart
END ParseSemicolonList;

(* Try to find references to remembered lists inside excludes *)
PROCEDURE ResolveExcludes(vecList: NewContainers.StringVector);
VAR
	i, j, posDummy: LONGINT;
	s: Strings.String;
	sa: Strings.StringArray;
	a: ARRAY 8 OF CHAR;
	bRelationResolved: BOOLEAN;
	vecTemp, list: NewContainers.StringVector;
BEGIN
	NEW(vecTemp, {});
	i := 0;
	WHILE i < vecList.Count DO
		bRelationResolved := FALSE;
		s := vecList.Get(i);
		IF (s # NIL) THEN
			sa := Strings.Split(s^, ':');
			IF LEN(sa) > 1 THEN
				COPY(sa[0]^, a);
				Strings.UpperCase(a);
				IF (a = "REF") & (mapRemember.Contains(sa[1]^)) THEN
					list := mapRemember.Get(sa[1]^).list;
					FOR j := 0 TO list.Count - 1 DO
						posDummy := vecTemp.Add(list.Get(j)^)
					END
				END
			END
		END;
		INC(i)
	END;
	IF vecTemp.Count > 0 THEN
		FOR i := 0 TO vecTemp.Count - 1 DO
			posDummy := vecList.Add(vecTemp.Get(i)^)
		END
	END
END ResolveExcludes;

PROCEDURE Collect*(context: Commands.Context); (** [options] moduleName {" " modulename} ~  *)
VAR
	vecModules: ModulesVector;
	vecModulesNotFound,
	vecModulesPaths,
	vecModulesExcludes: NewContainers.StringVector;
	moduleName, outputFilename: Files.FileName;
	paths, excludes, remember: ARRAY 1024 OF CHAR;
	options: Options.Options;
	i, posDummy: LONGINT;
	s: Strings.String;
	bDummy: BOOLEAN;
BEGIN
	NEW(options);
	options.Add("f", "file", Options.String);
	options.Add("p", "paths", Options.String);
	options.Add("x", "excludes", Options.String);
	options.Add("r", "remember", Options.String); (* Remember results under key *)
	IF options.Parse(context.arg, context.out) THEN
		IF ~options.GetString("file", outputFilename) THEN
			COPY(DefaultOutputFilename, outputFilename)
		END;
		NEW(vecModulesPaths, {Vector.SORTED, Vector.NO_DUPLICATES});
		posDummy := vecModulesPaths.Add("");
		IF options.GetString("paths", paths) THEN
			ParseSemicolonList(paths, vecModulesPaths)
		END;

		NEW(vecModulesExcludes, {Vector.SORTED, Vector.NO_DUPLICATES});
		IF options.GetString("excludes", excludes) THEN
			ParseSemicolonList(excludes, vecModulesExcludes)
		END;

		ResolveExcludes(vecModulesExcludes);

		bDummy := options.GetString("remember", remember);

		NEW(vecModules);
		NEW(vecModulesNotFound, {Vector.SORTED, Vector.NO_DUPLICATES});

		WHILE context.arg.GetString(moduleName) DO
			ProcessModule(context, vecModules, vecModulesNotFound, vecModulesPaths, moduleName)
		END;

		IF Output(outputFilename, remember, vecModules, vecModulesNotFound, vecModulesExcludes) THEN
			context.out.String("Collected modules written to "); context.out.String(outputFilename); context.out.Ln;
			IF vecModulesNotFound.Count > 0 THEN
				context.out.String("Some modules wasn't found: "); context.out.Ln;
				FOR i := 0 TO vecModulesNotFound.Count - 1 DO
					s := vecModulesNotFound.Get(i);
					IF s # NIL THEN
						context.out.String(s^); context.out.Ln
					END
				END
			END
		ELSE
			context.out.String("Could not create file "); context.out.String(outputFilename); context.out.Ln
		END;
		context.out.Update
	END
END Collect;

BEGIN

	NEW(mapRemember)

END ImportCollector.

ImportCollector.Collect

	-f=ZipLoader.zip
	-p=Libs/
	-x=Kernel32;Trace;Machine;Heaps;Modules;Objects;Kernel;KernelLog;Streams;Commands;Files;WinFS;Loader;BootConsole
	-r=ZipLoaderList

	ZipLoader ~

ImportCollector.Collect

	-f=Obj.Zip
	-p=Bindings/BASS/;Libs/;Components/;Tools/;Demos/
	-x=ref:ZipLoaderList;Kernel32;Trace;Machine;Heaps;Modules;Objects;Kernel;KernelLog;Streams;Commands;Files;WinFS;Loader;BootConsole

	WinStarter WMBass3DTest WMBassDSPTest WMRaycaster
	WMRaycasterMaze WMAStar WMFM WMColorLines

	DisplayNull Traps FileTrapWriter FSTools RelativeFileSystem
	WMOTFonts WMOberonFonts	Clipboard Autostart
  SkinEngine PNGDecoder BMPCodec Tar ~

ImportCollector.Collect

	-p=Bindings/BASS/;Libs/;Components/;Tools/;Demos/;Examples/
	-x=ref:ZipLoaderList;Kernel32;Trace;Machine;Heaps;Modules;Objects;Kernel;KernelLog;Streams;Commands;Files;WinFS;Loader;BootConsole

	WMAAGraphicsExample

	WinStarter DisplayNull Traps FileTrapWriter SystemVersion PNGDecoder ~


SystemTools.Free ImportCollector ~


