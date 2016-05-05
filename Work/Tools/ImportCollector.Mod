MODULE ImportCollector; (** AUTHOR "SAGE"; PURPOSE "Utility for collecting of all imported modules for specified applications"; *)

IMPORT
	Commands, Files, Options, Strings, UTF8Strings,
	Diagnostics, ModuleParser, Containers, Zip, ZipTool;

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

		PROCEDURE GetItem*(pos: LONGINT): ModuleParser.Module;
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

PROCEDURE Output(CONST sFileName: ARRAY OF CHAR; vecModules: ModulesVector; vecModulesNotFound: Containers.StringVector): BOOLEAN;
VAR
	i: LONGINT;
	m: ModuleParser.Module;
	s: Strings.String;
	archive: Zip.Archive;
	res: LONGINT;
BEGIN

	archive := Zip.CreateArchive(sFileName, res);
	IF (archive # NIL) & (res = Zip.Ok) THEN
		FOR i := 0 TO vecModules.vector.GetCount() - 1 DO
			m := vecModules.GetItem(i);
			IF m # NIL THEN
				(** TODO: Implement more robust generation of file name
					as in Modules.ThisModule. Or propose ETHZ to add real
					file name as field to Modules.Module *)
				s := Strings.ConcatToNew(m.ident.name^, ".Obw");
				ZipTool.AddFile(archive, s^, s^, Zip.DefaultCompression, Zip.DefaultStrategy, res);
				IF (res # Zip.Ok) & (vecModulesNotFound.IndexOf(m.ident.name^) = -1) THEN
					vecModulesNotFound.Add(m.ident.name^)
				END
			END
		END;
		RETURN TRUE
	END;

	RETURN FALSE
END Output;

PROCEDURE ParsePaths(CONST paths: ARRAY OF CHAR; vecModulesPaths: Containers.StringVector);
VAR
	j, k: LONGINT;
	dir: Files.FileName;

	PROCEDURE AddDir;
	BEGIN
		IF k > 0 THEN
			dir[k] := 0X;
			IF (dir # "") & (vecModulesPaths.IndexOf(dir) = -1) THEN
				vecModulesPaths.Add(dir)
			END;
			k := 0
		END
	END AddDir;

BEGIN
	k := 0;
	WHILE paths[j] # 0X DO
		IF paths[j] = ';' THEN
			AddDir
		ELSE
			dir[k] := paths[j]; INC(k)
		END;
		INC(j)
	END;
	AddDir
END ParsePaths;

PROCEDURE Collect*(context: Commands.Context); (** [options] moduleName {" " modulename} ~  *)
VAR
	vecModules: ModulesVector;
	vecModulesNotFound,
	vecModulesPaths: Containers.StringVector;
	moduleName, outputFilename: Files.FileName;
	paths: ARRAY 1024 OF CHAR;
	options: Options.Options;
	i: LONGINT;
	s: Strings.String;
BEGIN
	NEW(options);
	options.Add("f", "file", Options.String);
	options.Add("p", "paths", Options.String);
	IF options.Parse(context.arg, context.out) THEN
		IF ~options.GetString("file", outputFilename) THEN
			COPY(DefaultOutputFilename, outputFilename)
		END;
		NEW(vecModulesPaths, {Containers.VECTOR_SORTED, Containers.VECTOR_NO_DUPLICATES});
		vecModulesPaths.Add("");
		IF options.GetString("paths", paths) THEN
			ParsePaths(paths, vecModulesPaths)
		END;

		NEW(vecModules);
		NEW(vecModulesNotFound, {Containers.VECTOR_SORTED, Containers.VECTOR_NO_DUPLICATES});

		WHILE context.arg.GetString(moduleName) DO
			ProcessModule(context, vecModules, vecModulesNotFound, vecModulesPaths, moduleName)
		END;

		IF Output(outputFilename, vecModules, vecModulesNotFound) THEN
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

END ImportCollector.

ImportCollector.Collect

	-p=Bindings/BASS/;Libs/;Components/;Tools/;Demos/

	WinStarter WMBass3DTest WMRaycaster
	WMRaycasterMaze WMAStar WMFM

	DisplayNull Traps FileTrapWriter FSTools RelativeFileSystem
	Loader WMOTFonts WMOberonFonts	Clipboard Autostart
  SkinEngine PNGDecoder Tar SystemTools UpTime ~
  
ImportCollector.Collect

	-p=Bindings/BASS/;Libs/;Components/;Tools/;Demos/

	WinStarter WMBass3DTest WMRaycaster
	WMRaycasterMaze WMAStar WMFM

	DisplayNull Traps FileTrapWriter FSTools RelativeFileSystem
	Loader WMOTFonts WMOberonFonts	Clipboard Autostart
  SkinEngine PNGDecoder Tar UpTime ~

SystemTools.Free ImportCollector ~


