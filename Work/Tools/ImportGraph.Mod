MODULE ImportGraph; (** AUTHOR "SAGE"; PURPOSE "Utility for generation of import graphs in Graphviz (http://www.graphviz.org/) DOT format"; *)

IMPORT
	Commands, Files, Options, Codecs, Streams, Strings, UTF8Strings,
	Diagnostics, ModuleParser, Containers, Modules, KernelLog;

CONST
	DefaultOutputFilename = "ImportGraph.dot";

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

PROCEDURE ParseModule(CONST modName: ARRAY OF CHAR): ModuleParser.Module;
VAR
	module: ModuleParser.Module;
	diag: Diagnostics.Diagnostics;
BEGIN
	IF ~Strings.EndsWith(".Mod", modName) & (modName # "SYSTEM") THEN
		module := ModuleParser.ParseFile(Strings.ConcatToNew(modName, ".Mod")^, diag)
	ELSE
		module := ModuleParser.ParseFile(modName, diag)
	END;
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

PROCEDURE ProcessModule(context: Commands.Context; modules: ModulesVector; modulesNotFound: Containers.StringVector; CONST modName: ARRAY OF CHAR);
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
	IF modules.Contains(name^) OR (modulesNotFound.IndexOf(name^) >= 0) THEN
		RETURN
	END;
	module := ParseModule(name^);
	IF module = NIL THEN
		modulesNotFound.Add(name^);
		RETURN
	END;
	modules.Add(module);
	context.out.String("Added "); context.out.String(module.ident.name^);
	context.out.Ln; context.out.Update;
	import := module.importList;
	WHILE import # NIL DO
		info := ProperModuleInfo(import);
		IF (info # NIL) & ~modules.Contains(info.name^) THEN
			ProcessModule(context, modules, modulesNotFound, info.name^)
		END;
		IF import.next # NIL THEN
			import := import.next(ModuleParser.Import)
		ELSE
			import := NIL
		END
	END
END ProcessModule;

(* Get the list of actually imported modules *)
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

PROCEDURE Output(stream: Streams.Writer; modules: ModulesVector; modulesNotFound: Containers.StringVector);

	PROCEDURE OutputName(n: Strings.String);
	BEGIN
		stream.String('"');
		stream.String(n^);
		stream.String('"')
	END OutputName;

	PROCEDURE OutputLink(from, to: Strings.String);
	BEGIN
		OutputName(from);
		stream.String("->");
		OutputName(to);
		stream.String("; ")
	END OutputLink;

VAR
	i: LONGINT;
	m: ModuleParser.Module;
	import: ModuleParser.Import;
	s: Strings.String;
	info: ModuleParser.InfoItem;

BEGIN
	stream.String('strict digraph G{');
	stream.Ln;
	FOR i := 0 TO modules.vector.GetCount() - 1 DO
		m := modules.GetItem(i);
		IF m # NIL THEN
		
			ActualImports(m.ident.name^);
			
			OutputName(m.ident.name);
			IF m.FindImport("SYSTEM") # NIL THEN
				stream.String(' [fontcolor = red]; ')
			ELSE
				stream.String('; ')
			END;
			import := m.importList;
			WHILE import # NIL DO
				info := ProperModuleInfo(import);
				IF info # NIL THEN
					OutputLink(m.ident.name, info.name)
				END;
				IF import.next # NIL THEN
					import := import.next(ModuleParser.Import)
				ELSE
					import := NIL
				END
			END
		END
	END;
	FOR i := 0 TO modulesNotFound.GetCount() - 1 DO
		s := modulesNotFound.GetItem(i);
		IF s # NIL THEN
			OutputName(s);
			stream.String(' [shape = plaintext]; ')
		END
	END;
	stream.String('}');
	stream.Ln;
	stream.Update;
END Output;

PROCEDURE Generate*(context: Commands.Context); (** [options] moduleName {" " modulename} ~  *)
VAR
	modules: ModulesVector;
	modulesNotFound: Containers.StringVector;
	moduleName, outputFilename: Files.FileName;
	options: Options.Options;
	stream: Streams.Writer;

BEGIN
	NEW(options);
	options.Add("f", "file", Options.String);
	IF options.Parse(context.arg, context.out) THEN
		IF ~options.GetString("file", outputFilename) THEN
			COPY(DefaultOutputFilename, outputFilename);
		END;
		stream := Codecs.OpenOutputStream(outputFilename);
		IF (stream # NIL) THEN

			NEW(modules);
			NEW(modulesNotFound, {Containers.VECTOR_SORTED, Containers.VECTOR_NO_DUPLICATES});

			WHILE context.arg.GetString(moduleName) DO
				ProcessModule(context, modules, modulesNotFound, moduleName)
			END;

			Output(stream, modules, modulesNotFound);

			context.out.String("Graph description written to "); context.out.String(outputFilename); context.out.Ln;
		ELSE
			context.out.String("Could not create file "); context.out.String(outputFilename); context.out.Ln;
		END;
	END;
END Generate;

BEGIN

END ImportGraph.

ImportGraph.Generate -f=ImportGraphContainers.dot Containers ~

ImportGraph.Generate -f=ImportGraphWMWindowManager.dot WMWindowManager ~
ImportGraph.Generate -f=ImportGraphImportGraph.dot ImportGraph ~

ImportGraph.Generate -f=ImportGraphWebBrowser.dot WebBrowser ~

Import graph of all components (generator procedure present):
ImportGraph.Generate -f=ImportGraphWMStringGrids.dot 
	WMStringGrids~
ImportGraph.Generate -f=ImportGraphWMTextView.dot 
	WMTextView ~

ImportGraph.Generate -f=ImportGraphWMEditors.dot 
	WMEditors ~

SystemTools.Free ImportGraph ~
