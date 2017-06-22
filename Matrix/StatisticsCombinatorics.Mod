MODULE StatisticsCombinatorics; (** AUTHOR "Patrick Hunziker 2017"; PURPOSE "Library of tools for combinatorics"; *)

IMPORT Random (*, Commands, MatrixUtilities*);

PROCEDURE Permutation*(N:LONGINT): ARRAY[*] OF LONGINT;
VAR i,n:LONGINT; series: ARRAY [*] OF LONGINT;
BEGIN
	IF LEN(RESULT,0)#N THEN NEW(RESULT,N) END;
	IF LEN(series,0)#N THEN NEW(series,N) END;
	FOR i:=0 TO N-1 DO series[i]:=i END;
	FOR i:=N TO 1 BY -1 DO
		n:=sequence.Dice(i);
		RESULT[i-1]:=series[n];
		IF n#i-1 THEN series[n]:=series[i-1] END;
	END;
	RETURN RESULT
END Permutation;

VAR sequence: Random.Sequence;

(*PROCEDURE Test*(context:Commands.Context);
VAR n:LONGINT; p:ARRAY [*] OF LONGINT;
BEGIN
	IF context.arg.GetInteger(n,FALSE) THEN
	p:=Permutation(n);
	MatrixUtilities.Out(p);
	END;
END Test;*)

BEGIN
	NEW(sequence);
END StatisticsCombinatorics.

StatisticsCombinatorics.Test 10~
