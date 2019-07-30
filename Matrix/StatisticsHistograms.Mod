MODULE StatisticsHistograms; (** AUTHOR "Patrick Hunziker"; PURPOSE "Histograms"; *)

IMPORT KernelLog, MatrixBase,MatrixUtilities;

TYPE
	Volume= ARRAY [*,*,*] OF MatrixBase.Datatype;
	Data= ARRAY [?] OF MatrixBase.Datatype;

PROCEDURE LinearHistogram*(CONST data: MatrixBase.Vector; bins: LONGINT; VAR histogram: MatrixBase.Vector);
VAR max,min:LONGREAL; i,index :LONGINT;
BEGIN
	max:=MAX(data); min:=MIN(data);
	IF LEN(histogram)=0 THEN NEW(histogram,bins) ELSE histogram:=0 END;
	FOR i:=0 TO LEN(data,0)-1 DO
		index:=ENTIER((data[i]-min)*(bins-1) / (max-min));
		histogram[index ]:=histogram[index]+1;
	END;
END LinearHistogram;

PROCEDURE PlanarHistogram*(CONST data: MatrixBase.Matrix; bins: LONGINT; VAR histogram: MatrixBase.Vector);
VAR max,min:LONGREAL; i,j,index :LONGINT;
BEGIN
	max:=MAX(data); min:=MIN(data);
	IF LEN(histogram)=0 THEN NEW(histogram,bins) ELSE histogram:=0 END;
	FOR j:=0 TO LEN(data,0)-1 DO
		FOR i:=0 TO LEN(data,1)-1 DO
			index:=ENTIER((data[j,i]-min)*(bins-1) / (max-min));
			histogram[index ]:=histogram[index]+1;
		END;
	END;
END PlanarHistogram;

PROCEDURE VolumeHistogram*(CONST data: Volume; bins: LONGINT; VAR histogram: MatrixBase.Vector);
VAR max,min:LONGREAL; i,j,k,index :LONGINT;
BEGIN
	max:=MAX(data); min:=MIN(data);
	IF LEN(histogram)=0 THEN NEW(histogram,bins) ELSE histogram:=0 END;
	FOR k:=0 TO LEN(data,0)-1 DO
		FOR j:=0 TO LEN(data,0)-1 DO
			FOR i:=0 TO LEN(data,1)-1 DO
				index:=ENTIER((data[k,j,i]-min)*(bins-1) / (max-min));
				histogram[index ]:=histogram[index]+1;
			END;
		END;
	END;
END VolumeHistogram;

PROCEDURE TensorHistogram*;
END TensorHistogram;


PROCEDURE Histogram*(CONST data: Data ; bins: LONGINT; VAR histogram: MatrixBase.Vector);
(*VAR max,min:LONGREAL; index :LONGINT;
BEGIN
	max:=MAX(data); min:=MIN(data);
	IF LEN(histogram)=0 THEN NEW(histogram,bins) END;
*)
END Histogram;


PROCEDURE Test*;
VAR histogram,h2:MatrixBase.Vector;
BEGIN
	LinearHistogram([0,1,2,3,4,4,5,5,5,6,7,8,9],10,histogram);
	MatrixUtilities.OutVector(histogram);
	PlanarHistogram([[1,2,3,4],[2,3,4,5],[2,4,6,8],[1,3,4,5]],10,h2);
	MatrixUtilities.OutVector(h2);
END Test;


END StatisticsHistograms.

StatisticsHistograms.Test
SystemTools.Free Histograms~
