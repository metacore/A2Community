MODULE Testing; (** AUTHOR "Patrick Hunziker"; PURPOSE "automated module testing"; *)

(*may be promoted from Matrix Libary to general use*)
IMPORT FoxSyntaxTree, FoxBasic, Strings, Modules, Compiler, Out, Commands;

(*TYPE Test*= POINTER TO RECORD;
			mod: FoxSyntaxTree.Module;
			id: INTEGER;
			cmd: PROCEDURE(): ANY;
			res: ANY;
			next: Test;
	END;*)

TYPE Registry*=OBJECT
		(*VAR tests:Test;*)
			(* find all procedures "TESTxxx", assume that they have the signature PROCEDURE():ANY; call them, and check if they return NIL(=fail) or something(=succeed)*)
		PROCEDURE TestModule(module: FoxSyntaxTree.Module); 
		VAR p: FoxSyntaxTree.Procedure; 
			m,n, cmd, msg: ARRAY 64 OF CHAR;
			testProc: PROCEDURE():ANY;
			i, res:INTEGER;
			mod:Modules.Module;
		BEGIN
			FoxBasic.GetString(module.name, m);
		(*	COPY("System.FreeDownTo ",cmd); Strings.Append(cmd, m); Commands.Call (cmd, {}, res, msg);
			mod:=Modules.ThisModule(m, res, msg);
			*)
			(*Out.String("   freed downto "); Out.String(m); Out.Ln;*)
			p:=module.moduleScope.firstProcedure;
			i:=0;
			WHILE p#NIL DO
				FoxBasic.GetString(p.name, n);
				IF Strings.Pos("TEST",n)=0 THEN
					GETPROCEDURE(m,n,testProc);	
					IF (testProc#NIL) THEN
						Out.String("   "); Out.String(m); Out.String("."); Out.String(n);
						IF (testProc()#NIL) THEN (*currently, for simplicity, failure is signaled by returning NIL *)
							Out.String(" succeeded") 
						ELSE Out.String(" failed") 
						END;
						Out.Ln; Out.Update;	
						(*Register(module, i, testProc); INC(i); *)		
					ELSE Out.String("GETPROCEDURE failed on "); Out.String(m); Out.String("."); Out.String(n); Out.Ln;
					END; 
					Out.Update;
				END;
				p:=p.nextProcedure;
			END;
		END TestModule;
		(*
		(*registration of TEST procedures, not yet used*)
		PROCEDURE Register*(mod:FoxSyntaxTree.Module; id: INTEGER; cmd: PROCEDURE():ANY);
		VAR t, newT:Test;
			BEGIN
				NEW(newT); newT.mod:=mod; newT.id:=id; newT.cmd:=cmd; newT.res:=NIL;
				IF tests=NIL THEN tests:=newT;
				ELSE
					t:=tests;
					WHILE t.next#NIL DO t:=t.next END;
					t.next:=newT
				END;
		END Register;	
*)
END Registry;

VAR registry*: Registry;

PROCEDURE Install*;
BEGIN
	NEW(registry); 
	Compiler.TestModule:=registry.TestModule
END Install;

PROCEDURE Uninstall*;
BEGIN
	Compiler.TestModule:=NIL
END Uninstall;

BEGIN
	Modules.InstallTermHandler(Uninstall);
END Testing. 

System.FreeDownTo Testing~
Testing.Install ~
