MODULE LinearFIRConvolveLongReal;	(** Patrick Hunziker & dk(assembler)   **)
(** implements basic FIR convolutions for convolve, convolve+downsample, convolve+upsample *)

IMPORT Util:=MatrixUtilities;

PROCEDURE Convolve*(CONST filter:ARRAY[*]  OF FLOAT64; CONST data:ARRAY [*] OF FLOAT64; VAR result:ARRAY [*] OF FLOAT64);
VAR d,filterlen,reslen:SIZE;
BEGIN
	filterlen:=LEN(filter,0);
	IF LEN(data,0)<LEN(result,0) THEN reslen:=LEN(data,0) ELSE reslen:=LEN(result,0) END;
	FOR d:= 0 TO reslen-filterlen DO
		result[d]:= data[d..d+filterlen-1] +* filter;
	END;
END Convolve;

(*
PROCEDURE Convolve*(CONST filter:ARRAY[*]  OF FLOAT64; VAR data,result:ARRAY [*] OF FLOAT64);
VAR diffrlfl :SIGNED32;
CODE {SYSTEM.i386, SYSTEM.FPU}
		;28[EBP] : LEN(filter)
		; 20[EBP] : LEN(data,0)
		;12[EBP] : LEN(result,0)

		MOV EBX, 20[EBP]  ; LEN(data,0)
		MOV EDX, 12[EBP]  ; LEN(result,0)
		CMP EBX, EDX
		JG endif
		MOV EBX, 12[EBP] ; reslen:=LEN(data,0)
	endif:
		MOV EDX, 28[EBP] ;
		SUB EBX, EDX
		MOV diffrlfl[EBP], EBX ;  reslen - LEN(filter)

		MOV EDI, data[EBP] ; EDI := ADDRESSOF(data[0]);
		MOV ESI, filter[EBP];  ESI := ADDRESSOF(filter[0]);
		MOV EDX, result[EBP]  ;EDX := ADDRESSOF(result[0]);

		MOV EAX, 0 ; d := 0
		JMP conditionOL
	outerloop:
		MOV ECX, 0 ;f := 0
		FLDZ
		JMP conditionIL
	innerloop:
		FLD QWORD 0[EDI][ECX*8]
		FLD QWORD 0[ESI][ECX*8]
		FMULP
		FADDP
		INC ECX ; INC(f)
	conditionIL:
		 CMP ECX, 28[EBP] ;  f < LEN(filter) ?
		 JL innerloop;
		FSTP QWORD  0[EDX][EAX*8]
		WAIT
		INC EAX;  INC(d);
		ADD EDI, 8  ; EDI := ADDRESSOF(data[0 + d]);
	conditionOL:
		CMP EAX, diffrlfl[EBP] ; d < reslen - LEN(filter) ?
		JLE outerloop
END Convolve;
*)

PROCEDURE ConvolveDown2*(CONST filter:ARRAY[*]  OF FLOAT64;  CONST data:ARRAY [*] OF FLOAT64;VAR result:ARRAY [*] OF FLOAT64; shift:SIGNED32);
VAR d,filterlen,datalen,resPos:SIZE;
BEGIN
	(** precondition: shift IN {0,1} ; this is used for even/odd algorithm variants *)
	IF LEN(result,0) < LEN(data,0) DIV 2 THEN datalen:=2* LEN(result,0) ELSE datalen:= LEN(data,0) END;
	filterlen:=LEN(filter,0);
	result:=0;
	FOR d:= shift TO datalen-filterlen-1(*??-1*) BY 2 DO
		resPos:=d DIV 2 ;	(* downsampling *)
		result[resPos]:= data[d..d+filterlen-1] +* filter;
		(*Util.OutVector(result);*)
	END;
END ConvolveDown2;

(*
PROCEDURE ConvolveDown2*(CONST filter:ARRAY[*]  OF FLOAT64; VAR data,result:ARRAY [*] OF FLOAT64; shift:SIGNED32);
VAR diffdlfl :SIGNED32;
CODE {SYSTEM.i386, SYSTEM.FPU}
		;32[EBP] : LEN(filter)
		;24[EBP] : LEN(data,0)
		;16[EBP] : LEN(result,0)

		MOV EBX, 24[EBP];  LEN(data,0)
		SAR EBX,1 ; LEN(data,0) DIV 2
		MOV EDX, 16[EBP];  LEN(result,0)
		CMP EDX, EBX  ; LEN(result,0) < LEN(data,0) DIV 2 ?
		JNL else
		MOV EBX, 16[EBP]
		SHL EBX,1 ; datalen := 2* LEN(result,0)
		JMP endif
	else:
		MOV EBX, 24[EBP] ; datalen := LEN(data,0)
	endif:
		MOV EDX, 32[EBP] ;
		SUB EBX, EDX ; diffdlfl := datalen - LEN(filter)
		MOV diffdlfl[EBP], EBX

		MOV EDI, data[EBP] ; EDI := ADDRESSOF(data[0])
		MOV ESI, filter[EBP] ; ESI := ADDRESSOF(filter[0])
		MOV EDX, result[EBP] ;EXI := ADDRESSOF(result[0])


		MOV EAX, shift[EBP]; d := shift
		MOV ECX, EAX
		SHL ECX,3
		ADD EDI, ECX ; data[d] := data[0 + shift]

		JMP conditionOL
	outerloop:
		MOV ECX, 0 ;f := 0
		FLDZ
		JMP conditionIL
	innerloop:
		FLD QWORD 0[EDI][ECX*8]
		FLD QWORD 0[ESI][ECX*8]
		FMULP
		FADDP
		INC ECX ; INC(f)
	conditionIL:
		CMP ECX, 32[EBP]; f < LEN(filter) ?
		JL innerloop

		MOV ECX, EAX
		SAR ECX, 1;
		FSTP QWORD 0[EDX][ECX * 8]
		WAIT
		ADD EAX, 2 ; INC(d,2)
		ADD EDI, 16  ;EDI := ADDRESSOF(data[0 + d])
	conditionOL:
		CMP EAX, diffdlfl[EBP] ; d < reslen - LEN(filter)
		JLE outerloop
endouterloop:

END ConvolveDown2;
*)

PROCEDURE ConvolveUp2*(CONST filter:ARRAY[*]  OF FLOAT64; CONST data: ARRAY [*] OF FLOAT64;VAR result:ARRAY [*] OF FLOAT64; shift:SIGNED32);
	(** upsampling by 2 and convolution with filter; admissible types should include all basic Oberon number types *)
VAR f,d,filterlen,reslen,filterstart:SIZE;
BEGIN
	(** precondition: shift IN {0,1} ; this is used for even/odd algorithm variants *)
	(* in simpler, slow variant, upsampling (shifted by shift) into a temp array is followed by standard FIRConvolve*)
	IF LEN(result,0) < 2 * LEN(data,0) THEN reslen:=LEN(result,0) ELSE reslen:=2*LEN(data,0) END;
	filterlen:=LEN(filter,0);
	FOR d:= 0 TO reslen-filterlen DO
		result[d]:=0;
		IF ODD(d+shift) THEN filterstart:=1 ELSE filterstart:=0 END;
		FOR f:=filterstart TO filterlen-1 BY 2 DO
			result[d]:=data[(d+f ) DIV 2 ]*filter[f] + result[d]
		END;
		(*write as matrix expression.. *)
	END;
END ConvolveUp2;

(*
PROCEDURE ConvolveUp2*(CONST filter:ARRAY[*]  OF FLOAT64; VAR data,result:ARRAY [*] OF FLOAT64; shift:SIGNED32);
VAR diffrlfl :SIGNED32;
CODE {SYSTEM.i386, SYSTEM.FPU}
		;32[EBP] : LEN(filter)
		;24[EBP] : LEN(data,0)
		;16[EBP] : LEN(result,0)

		MOV EBX, 24[EBP]
		SHL EBX, 1; reslen := 2 * LEN(data,0)
		MOV EDX, 16[EBP]; EDX := LEN(result,0)
		CMP EDX, EBX ; LEN(result,0) < 2 * LEN(data,0) ?
		JG endif
		MOV EBX, 16[EBP] ; reslen := LEN(result,0)
	endif:
		MOV EDX, 32[EBP] ; EDX := LEN(filter)
		SUB EBX, EDX ; EBX := reslen - filterlen
		MOV diffrlfl[EBP], EBX

		MOV EDI, data[EBP] ; EDI := ADDRESSOF(data[0])
		MOV ESI, filter[EBP] ; ESI := ADDRESSOF(filter[0])
		MOV EDX, result[EBP] ;EXI := ADDRESSOF(result[0])

		MOV EAX, 0; d := 0
		JMP conditionOL
	outerloop:
		FLDZ
		MOV ECX, shift[EBP]
		ADD ECX, EAX
		AND ECX, 00000001H ; IF ODD(d+shift) THEN filterstart:=1 ELSE filterstart:=0 END;
		JMP conditionIL
	innerloop:
		MOV EBX, EAX
		 ADD EBX, ECX
		SAR EBX, 1	; index := d+ f DIV 2
		FLD QWORD 0[EDI][EBX*8]
		FLD QWORD 0[ESI][ECX*8]
		FMULP
		FADDP
		 ADD ECX, 2 ; INC(f, 2)
	conditionIL:
		CMP ECX, 32[EBP]; f < LEN(filter) ?
		JL innerloop

		FSTP QWORD 0[EDX][EAX * 8]
		WAIT
		INC EAX ; INC(d)
	conditionOL:
		CMP EAX, diffrlfl[EBP] ; d <  reslen - filterlen ?
		JLE outerloop
endouterloop:

END ConvolveUp2;
*)

END LinearFIRConvolveLongReal.

System.Free FIRConvolveReal ~
Decoder.Decode FIRConvolveReal~

------------------------
System.Log output:


Builder.Compile *
fofPC.Compile \s *
