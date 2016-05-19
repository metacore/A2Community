MODULE ImportCollector; (** AUTHOR "SAGE"; PURPOSE "Utility for collecting of all imported modules for specified applications"; *)

IMPORT
	Machine, Commands, Files, Options, Strings, UTF8Strings,
	Diagnostics, ModuleParser, Containers, Zip, ZipTool, KernelLog;

CONST
	DefaultOutputFilename = "CollectedModules.zip";

TYPE
	ModulesVector = OBJECT (Containers.CustomVector)
	VAR
		null: ModuleParser.Module; (* for speedup of Contains procedure *)

		PROCEDURE &New;
		BEGIN
			NEW(null, NIL);
			NEW(null.ident);
			NEW(null.ident.name, 257);
			NEW(vector, Compare, {Containers.VECTOR_SORTED, Containers.VECTOR_NO_DUPLICATES})
		END New;

		PROCEDURE Compare(first, second: ANY): LONGINT;
		BEGIN
			RETURN UTF8Strings.Compare(first(ModuleParser.Module).ident.name^,
				second(ModuleParser.Module).ident.name^)
		END Compare;

		PROCEDURE Add(module: ModuleParser.Module);
		BEGIN
			vector.Add(module)
		END Add;

		PROCEDURE Contains(CONST name: ARRAY OF CHAR): BOOLEAN;
		BEGIN
			COPY(name, null.ident.name^);
			RETURN vector.IndexOf(null) >= 0
		END Contains;

		PROCEDURE GetItem(pos: LONGINT): ModuleParser.Module;
		VAR
			ptr: ANY;
		BEGIN
			ptr := vector.GetItem(pos);
			IF ptr # NIL THEN
				RETURN ptr(ModuleParser.Module)
			ELSE
				RETURN NIL
			END
		END GetItem;

	END ModulesVector;
	
	RememberMapItem = POINTER TO RECORD
		key: Files.FileName;
		list: Containers.StringVector;
	END;
	
	RememberMap = OBJECT (Containers.CustomVector)
	VAR
		null: RememberMapItem;
	
		PROCEDURE &New;
		BEGIN
			NEW(null);
			NEW(vector, Compare, {Containers.VECTOR_SORTED, Containers.VECTOR_NO_DUPLICATES})
		END New;

		PROCEDURE Compare(first, second: ANY): LONGINT;
		BEGIN
			RETURN UTF8Strings.Compare(first(RememberMapItem)^.key,
				second(RememberMapItem)^.key)
		END Compare;

		PROCEDURE Add(key: ARRAY OF CHAR; list: Containers.StringVector);
		VAR
			item: RememberMapItem;
		BEGIN
			NEW(item);
			COPY(key, item^.key);
			item.list := list;
			vector.Add(item)
		END Add;
		
		PROCEDURE Contains(CONST key: ARRAY OF CHAR): BOOLEAN;
		BEGIN
			COPY(key, null^.key);
			RETURN vector.IndexOf(null) >= 0
		END Contains;

		PROCEDURE GetItem(CONST key: ARRAY OF CHAR): RememberMapItem;
		VAR
			i: LONGINT;
		BEGIN
			COPY(key, null^.key);
			i := vector.IndexOf(null);
			IF i >= 0 THEN
				RETURN vector.GetItem(i)(RememberMapItem)
			ELSE
				RETURN NIL
			END
		END GetItem;
		
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
PROCEDURE FindCorrectFilepath(CONST moduleName: ARRAY OF CHAR; vecModulesPaths: Containers.StringVector): Files.FileName;
VAR
	pathName: Files.FileName;
	i: LONGINT;
BEGIN
	IF vecModulesPaths.GetCount() = 0 THEN
		pathName := FindCorrectFilename("", moduleName)
	ELSE
		i := 0;
		REPEAT
			pathName := FindCorrectFilename(vecModulesPaths.GetItem(i)^, moduleName);
			INC(i)
		UNTIL FileExists(pathName) OR (i > vecModulesPaths.GetCount() - 1)
	END;
	RETURN pathName
END FindCorrectFilepath;

PROCEDURE ProcessModule(context: Commands.Context; vecModules: ModulesVector; vecModulesNotFound, vecModulesPaths: Containers.StringVector; CONST modName: ARRAY OF CHAR);

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
		vecModulesNotFound.Add(name^);
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

PROCEDURE Output(CONST sFileName, sRememberKey: ARRAY OF CHAR; vecModules: ModulesVector; vecModulesNotFound, vecModulesExcludes: Containers.StringVector): BOOLEAN;
VAR
	i: LONGINT;
	m: ModuleParser.Module;
	archive: Zip.Archive;
	res: LONGINT;
	outputFilename: Files.FileName;
	listRemember: Containers.StringVector;
	item: RememberMapItem;
	sysextension: ARRAY 6 OF CHAR;
BEGIN

	Machine.GetConfig("ObjectFileExtension", sysextension);
	IF sysextension = "" THEN
		COPY(Machine.DefaultObjectFileExtension, sysextension)
	END;
	KernelLog.String(sysextension); KernelLog.Ln;

	listRemember := NIL;
	IF sRememberKey # "" THEN
		item := mapRemember.GetItem(sRememberKey);
		IF item # NIL THEN
			item.list.vector.Clear;
			listRemember := item.list
		ELSE
			NEW(listRemember, {Containers.VECTOR_SORTED, Containers.VECTOR_NO_DUPLICATES});
			mapRemember.Add(sRememberKey, listRemember)
		END
	END;

	archive := Zip.CreateArchive(sFileName, res);
	IF (archive # NIL) & (res = Zip.Ok) THEN
		FOR i := 0 TO vecModules.vector.GetCount() - 1 DO
			m := vecModules.GetItem(i);
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
						listRemember.Add(m.ident.name^)
					END
				ELSIF vecModulesNotFound.IndexOf(m.ident.name^) = -1 THEN
					vecModulesNotFound.Add(m.ident.name^)
				END
			END
		END;
		RETURN TRUE
	END;

	RETURN FALSE
END Output;

PROCEDURE ParseSemicolonList(CONST list: ARRAY OF CHAR; vecList: Containers.StringVector);
VAR
	j, k: LONGINT;
	part: Files.FileName;

	PROCEDURE AddPart;
	BEGIN
		IF k > 0 THEN
			part[k] := 0X;
			IF (part # "") & (vecList.IndexOf(part) = -1) THEN
				vecList.Add(part)
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
PROCEDURE ResolveExcludes(vecList: Containers.StringVector);
VAR
	i, j: LONGINT;
	s: Strings.String;
	sa: Strings.StringArray;
	a: ARRAY 8 OF CHAR;
	bRelationResolved: BOOLEAN;
	vecTemp, list: Containers.StringVector;
BEGIN
	NEW(vecTemp, {});
	i := 0;
	WHILE i < vecList.GetCount() DO
		bRelationResolved := FALSE;
		s := vecList.GetItem(i);
		IF (s # NIL) THEN
			sa := Strings.Split(s^, ':');
			IF LEN(sa) > 1 THEN
				COPY(sa[0]^, a);
				Strings.UpperCase(a);
				IF (a = "REF") & (mapRemember.Contains(sa[1]^)) THEN
					list := mapRemember.GetItem(sa[1]^).list;
					FOR j := 0 TO list.GetCount() - 1 DO
						vecTemp.Add(list.GetItem(j)^)
					END
				END
			END
		END;
		INC(i)
	END;
	IF vecTemp.GetCount() > 0 THEN
		FOR i := 0 TO vecTemp.GetCount() - 1 DO
			vecList.Add(vecTemp.GetItem(i)^)
		END
	END
END ResolveExcludes;

PROCEDURE Collect*(context: Commands.Context); (** [options] moduleName {" " modulename} ~  *)
VAR
	vecModules: ModulesVector;
	vecModulesNotFound,
	vecModulesPaths,
	vecModulesExcludes: Containers.StringVector;
	moduleName, outputFilename: Files.FileName;
	paths, excludes, remember: ARRAY 1024 OF CHAR;
	options: Options.Options;
	i: LONGINT;
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
		NEW(vecModulesPaths, {Containers.VECTOR_SORTED, Containers.VECTOR_NO_DUPLICATES});
		vecModulesPaths.Add("");
		IF options.GetString("paths", paths) THEN
			ParseSemicolonList(paths, vecModulesPaths)
		END;
		
		NEW(vecModulesExcludes, {Containers.VECTOR_SORTED, Containers.VECTOR_NO_DUPLICATES});
		IF options.GetString("excludes", excludes) THEN
			ParseSemicolonList(excludes, vecModulesExcludes)
		END;
		
		ResolveExcludes(vecModulesExcludes);
	
		bDummy := options.GetString("remember", remember);

		NEW(vecModules);
		NEW(vecModulesNotFound, {Containers.VECTOR_SORTED, Containers.VECTOR_NO_DUPLICATES});

		WHILE context.arg.GetString(moduleName) DO
			ProcessModule(context, vecModules, vecModulesNotFound, vecModulesPaths, moduleName)
		END;

		IF Output(outputFilename, remember, vecModules, vecModulesNotFound, vecModulesExcludes) THEN
			context.out.String("Collected modules written to "); context.out.String(outputFilename); context.out.Ln;
			IF vecModulesNotFound.GetCount() > 0 THEN
				context.out.String("Some modules wasn't found: "); context.out.Ln;
				FOR i := 0 TO vecModulesNotFound.GetCount() - 1 DO
					s := vecModulesNotFound.GetItem(i);
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


