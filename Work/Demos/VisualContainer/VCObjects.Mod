MODULE VCObjects;

(** AUTHOR "Yaroslav Romanchenko (SAGE) http://sage.com.ua/";
	PURPOSE "Visual Objects Container objects"; *)

IMPORT
	Strings, Math, WMEvents, WMComponents,
	Vector, VCTypes;

TYPE

	HT* = ENUM
		OUTSIDE*,
		INSIDE*,
		VERTEX*,
		SIDE*
	END;

	CR* = ENUM
		DEFAULT*,
		SIZEALL*,
		HORIZONTAL*,
		VERTICAL*,
		DIAG1*,
		DIAG2*
	END;

	HitTest* = RECORD
		Type*: HT;
		Index*: LONGINT;
	END;

	HitTestParams* = RECORD
		Pos*: VCTypes.Point;
		Tolerance*: LONGINT;
	END;

	Command = RECORD
	END;

	CommandBeginDrag* = RECORD(Command)
		Hit*: HitTest;
		StartPos*: VCTypes.FloatPoint;
	END;

	CommandEndDrag* = RECORD(Command)
	END;

	CommandDrag* = RECORD(Command)
		NewPos*: VCTypes.FloatPoint;
	END;

	CommandVertexMove = RECORD(Command)
		Index: LONGINT;
		NewPos: VCTypes.FloatPoint;
	END;

	CommandSideMove = RECORD(Command)
		Index: LONGINT;
		NewPos: VCTypes.FloatPoint;
	END;

	CommandMove = RECORD(Command)
		DeltaX: REAL;
		DeltaY: REAL;
	END;

	CommandHitTest* = RECORD(Command)
		ConvertIntf*: VCTypes.VisualContainerBase;
		Params*: HitTestParams;
		Hit*: HitTest;
	END;

	CommandGetCursor* = RECORD(Command)
		Hit*: HitTest;
		Cursor*: CR;
	END;

	CommandConstructPoint* = RECORD(Command)
		Pos*: VCTypes.FloatPoint;
		Result*: BOOLEAN
	END;

	CommandProcessConstruct* = RECORD(Command)
		Pos*: VCTypes.FloatPoint;
	END;

	CommandStopConstruct* = RECORD(Command)
		Result*: BOOLEAN
	END;

	CommandVControl = RECORD(Command)
		Hit: HitTest;
		Pos: VCTypes.FloatPoint;
	END;

	BaseVisualObject* = OBJECT(WMComponents.Component)
	VAR

		FBasePoints: VCTypes.FloatPointVector;

		onChange-: WMEvents.EventSource;

		FLockCount: LONGINT;
		FDragging: BOOLEAN;
		FDragHitTest: HitTest;
		FDragStartPos: VCTypes.FloatPoint;

		PROCEDURE &Init;
		BEGIN
			Init^;

			NEW(FBasePoints);

			(* events *)
			NEW(onChange, SELF, Strings.NewString("onChange"), Strings.NewString("Object changed"), NIL);
			events.Add(onChange);

		END Init;

		PROCEDURE HandleCommand*(VAR command: Command);
		VAR
			i: LONGINT;
			pos: VCTypes.FloatPoint;
			cmdMove: CommandMove;
			cmdVertexMove: CommandVertexMove;
			cmdSideMove: CommandSideMove;
		BEGIN
			IF command IS CommandBeginDrag THEN
				WITH command: CommandBeginDrag DO
					FDragging := TRUE;
					FDragHitTest := command.Hit;
					FDragStartPos := command.StartPos
				END
			ELSIF command IS CommandDrag THEN
				WITH command: CommandDrag DO
					IF FDragging THEN
						CASE FDragHitTest.Type OF
							HT.INSIDE:
								cmdMove.DeltaX := command.NewPos.X - FDragStartPos.X;
								cmdMove.DeltaY := command.NewPos.Y - FDragStartPos.Y;
								FDragStartPos := command.NewPos;
								HandleCommand(cmdMove)
						|	HT.VERTEX:
								cmdVertexMove.Index := FDragHitTest.Index;
								cmdVertexMove.NewPos := command.NewPos;
								HandleCommand(cmdVertexMove)
						|	HT.SIDE:
								cmdSideMove.Index := FDragHitTest.Index;
								cmdSideMove.NewPos := command.NewPos;
								HandleCommand(cmdSideMove)
						ELSE
						END
					END
				END
			ELSIF command IS CommandEndDrag THEN
				FDragging := FALSE
			ELSIF command IS CommandGetCursor THEN
				command(CommandGetCursor).Cursor := CR.DEFAULT
			ELSIF command IS CommandHitTest THEN
				command(CommandHitTest).Hit.Type := HT.OUTSIDE
			ELSIF command IS CommandMove THEN
				WITH command: CommandMove DO
					BeginUpdate;
					FOR i := 0 TO GetBasePointsCount() - 1 DO
						pos := GetBasePoint(i);
						SetBasePoint(i, pos.X + command.DeltaX, pos.Y + command.DeltaY)
					END;
					EndUpdate
				END
			ELSIF command IS CommandVertexMove THEN
				WITH command: CommandVertexMove DO
					SetVertex(command.Index, command.NewPos.X, command.NewPos.Y)
				END
			END
		END HandleCommand;

		PROCEDURE Change;
		BEGIN
			IF FLockCount = 0 THEN
				onChange.Call(NIL (* par *))
			END
		END Change;

		PROCEDURE AddBasePoint(X, Y: REAL);
		BEGIN
			FBasePoints.Add(X, Y);
			Change;
		END AddBasePoint;

		PROCEDURE InsertBasePoint(Index: LONGINT; X, Y: REAL);
		BEGIN
			FBasePoints.Insert(Index, X, Y);
			Change;
		END InsertBasePoint;

		PROCEDURE DeleteBasePoint(Index: LONGINT);
		BEGIN
			FBasePoints.Remove(Index);
			Change;
		END DeleteBasePoint;

		PROCEDURE ClearBasePoints;
		BEGIN
			FBasePoints.Clear;
			Change;
		END ClearBasePoints;

		PROCEDURE GetBasePointsCount(): LONGINT;
		BEGIN
			RETURN FBasePoints.Count
		END GetBasePointsCount;

		PROCEDURE GetBasePoint(Index: LONGINT): VCTypes.FloatPoint;
		BEGIN
			RETURN FBasePoints.Get(Index)
		END GetBasePoint;

		PROCEDURE SetBasePoint(Index: LONGINT; X, Y: REAL);
		VAR
			item: VCTypes.FloatPoint;
		BEGIN
			item := FBasePoints.Get(Index);
			IF (item.X # X) OR (item.Y # Y) THEN
				FBasePoints.Set(Index, X, Y);
				Change
			END
		END SetBasePoint;

		PROCEDURE GetVerticesCount(): LONGINT;
		END GetVerticesCount;

		PROCEDURE GetVertex(Index: LONGINT): VCTypes.FloatPoint;
		END GetVertex;

		PROCEDURE SetVertex(Index: LONGINT; X, Y: REAL);
		END SetVertex;

		PROCEDURE BeginUpdate;
		BEGIN
			INC(FLockCount)
		END BeginUpdate;

		PROCEDURE EndUpdate;
		BEGIN
			DEC(FLockCount);
			(*FLockCount := MAX(0, FLockCount - 1);*)
			IF FLockCount = 0 THEN
				Change
			END
		END EndUpdate;

		PROCEDURE Draw*(Canvas: VCTypes.LogicalCanvas);
		VAR
			i: LONGINT;
			vertex: VCTypes.FloatPoint;
		BEGIN
			FOR i := 0 TO GetVerticesCount() - 1 DO
				vertex := GetVertex(i);
				Canvas.DrawVertex(vertex.X, vertex.Y)
			END
		END Draw;

		(*property OnChange: TNotifyEvent read FOnChange write FOnChange;*)
	END BaseVisualObject;

	VisualObjectGen* = PROCEDURE {DELEGATE} (): BaseVisualObject;

	BaseVisualObjectValue = RECORD(Vector.Value)
		value: BaseVisualObject
	END;

	VisualObjectVector* = OBJECT(Vector.Vector)
	VAR
		array: POINTER TO ARRAY OF BaseVisualObjectValue;

		PROCEDURE &Init*;
		BEGIN
			New(Vector.INITIAL_SIZE, SIZEOF(BaseVisualObjectValue), {Vector.INDEX}, Create, CompareRef, NIL)
		END Init;

		PROCEDURE Create(nSize: LONGINT; VAR pArray: ANY; VAR adrArray: ADDRESS);
		BEGIN
			NEW(array, nSize);
			pArray := array; adrArray := ADDRESSOF(array^[0])
		END Create;

		PROCEDURE CompareRef(iLeft: LONGINT; VAR right: Vector.Value): LONGINT;
		VAR
			adrLeft, adrRight: ADDRESS;
		BEGIN
			WITH right: BaseVisualObjectValue DO
				adrLeft := array^[iLeft].value;
				adrRight := right.value;
				IF adrLeft < adrRight THEN
					RETURN -1
				ELSIF adrLeft > adrRight THEN
					RETURN 1
				ELSE
					RETURN 0
				END
			END
		END CompareRef;

		PROCEDURE Add*(o: BaseVisualObject): LONGINT;
		VAR
			v: BaseVisualObjectValue;
		BEGIN
			v.value := o;
			RETURN AddInternal(v)
		END Add;

		PROCEDURE IndexOf*(o: BaseVisualObject): LONGINT;
		VAR
			v: BaseVisualObjectValue;
		BEGIN
			v.value := o;
			RETURN IndexOfInternal(v)
		END IndexOf;

		PROCEDURE Get*(pos: LONGINT): BaseVisualObject;
		BEGIN
			ASSERT((pos >= 0) & (pos < Count), 101);
			RETURN array^[pos].value
		END Get;

	END VisualObjectVector;

	RectVisualObject* = OBJECT(BaseVisualObject)
	VAR
		FConstructing: BOOLEAN;
		FCurrentPoint: LONGINT;
		FText: Strings.String;

		PROCEDURE &Init;
		BEGIN
			Init^;
			AddBasePoint(0, 0);
			AddBasePoint(0, 0);
			FText := NullText
		END Init;

		PROCEDURE SetText*(CONST Value: ARRAY OF CHAR);
		BEGIN
			IF FText^ # Value THEN
				FText := Strings.NewString(Value);
				Change
			END
		END SetText;
		
		PROCEDURE GetText*(VAR Value: ARRAY OF CHAR);
		BEGIN
			IF FText # NIL THEN
				COPY(FText^, Value)
			ELSE
				COPY("", Value)
			END
		END GetText;

		PROCEDURE HandleCommand(VAR command: Command);
		VAR
			sX1f, sY1f, sX2f, sY2f: REAL;
			sX1, sY1, sX2, sY2: LONGINT;
			Point, fp0, fp1: VCTypes.FloatPoint;
		BEGIN
			IF command IS CommandConstructPoint THEN
				WITH command: CommandConstructPoint DO
					IF ~FConstructing THEN
						FConstructing := TRUE;
						FCurrentPoint := 0;
					END;
					CASE FCurrentPoint OF
						0:
						BeginUpdate;
						SetBasePoint(0, command.Pos.X, command.Pos.Y);
						SetBasePoint(1, command.Pos.X, command.Pos.Y);
						EndUpdate;
						command.Result := TRUE
					|	1:
						SetBasePoint(1, command.Pos.X, command.Pos.Y);
						FConstructing := FALSE;
						command.Result := FALSE
					ELSE
					END;
					INC(FCurrentPoint)
				END
			ELSIF command IS CommandGetCursor THEN
				WITH command: CommandGetCursor DO
					CASE command.Hit.Type OF
						HT.INSIDE: command.Cursor := CR.SIZEALL
					|	HT.VERTEX:
							IF (command.Hit.Index = 0) OR (command.Hit.Index = 2) THEN
								command.Cursor := CR.DIAG1
							ELSE
								command.Cursor := CR.DIAG2
							END
					|	HT.SIDE:
							IF (command.Hit.Index = 0) OR (command.Hit.Index = 2) THEN
								command.Cursor := CR.HORIZONTAL
							ELSE
								command.Cursor := CR.VERTICAL
							END
					ELSE
						command.Cursor := CR.DEFAULT
					END
				END
			ELSIF command IS CommandHitTest THEN
				WITH command: CommandHitTest DO
					fp0 := GetBasePoint(0);
					fp1 := GetBasePoint(1);
					command.ConvertIntf.LogToScreenPt(fp0.X, fp0.Y, sX1f, sY1f);
					command.ConvertIntf.LogToScreenPt(fp1.X, fp1.Y, sX2f, sY2f);
					sX1 := round(sX1f); sY1 := round(sY1f);
					sX2 := round(sX2f); sY2 := round(sY2f);
					command.Hit.Type := HT.OUTSIDE;
					IF (ABS(command.Params.Pos.x - sX1) <= command.Params.Tolerance) &
						(ABS(command.Params.Pos.y - sY1) <= command.Params.Tolerance)
					THEN
						command.Hit.Type := HT.VERTEX;
						command.Hit.Index := 0
					ELSIF (ABS(command.Params.Pos.x - sX2) <= command.Params.Tolerance) &
						(ABS(command.Params.Pos.y - sY1) <= command.Params.Tolerance)
					THEN
						command.Hit.Type := HT.VERTEX;
						command.Hit.Index := 1
					ELSIF (ABS(command.Params.Pos.x - sX2) <= command.Params.Tolerance) &
						(ABS(command.Params.Pos.y - sY2) <= command.Params.Tolerance)
					THEN
						command.Hit.Type := HT.VERTEX;
						command.Hit.Index := 2
					ELSIF (ABS(command.Params.Pos.x - sX1) <= command.Params.Tolerance) &
						(ABS(command.Params.Pos.y - sY2) <= command.Params.Tolerance)
					THEN
						command.Hit.Type := HT.VERTEX;
						command.Hit.Index := 3
					ELSIF (ABS(command.Params.Pos.x - sX1) <= command.Params.Tolerance) &
						(command.Params.Pos.y > sY1) & (command.Params.Pos.y < sY2)
					THEN
						command.Hit.Type := HT.SIDE;
						command.Hit.Index := 0
					ELSIF (ABS(command.Params.Pos.y - sY1) <= command.Params.Tolerance) &
						(command.Params.Pos.x > sX1) & (command.Params.Pos.x < sX2)
					THEN
						command.Hit.Type := HT.SIDE;
						command.Hit.Index := 1
					ELSIF (ABS(command.Params.Pos.x - sX2) <= command.Params.Tolerance) &
						(command.Params.Pos.y > sY1) & (command.Params.Pos.y < sY2)
					THEN
						command.Hit.Type := HT.SIDE;
						command.Hit.Index := 2
					ELSIF (ABS(command.Params.Pos.y - sY2) <= command.Params.Tolerance) &
						(command.Params.Pos.x > sX1) & (command.Params.Pos.x < sX2)
					THEN
						command.Hit.Type := HT.SIDE;
						command.Hit.Index := 3
					ELSIF (command.Params.Pos.x > sX1) & (command.Params.Pos.x < sX2) &
						(command.Params.Pos.y > sY1) & (command.Params.Pos.y < sY2)
					THEN
						command.Hit.Type := HT.INSIDE
					END
				END
			ELSIF command IS CommandProcessConstruct THEN
				WITH command: CommandProcessConstruct DO
					IF FConstructing THEN
						CASE FCurrentPoint OF
							0: SetVertex(0, command.Pos.X, command.Pos.Y);
						|	1: SetVertex(2, command.Pos.X, command.Pos.Y)
						ELSE
						END
					END
				END
			ELSIF command IS CommandSideMove THEN
				WITH command: CommandSideMove DO
					CASE command.Index OF
						0:
								Point := GetVertex(0);
								Point.X := command.NewPos.X;
								SetVertex(0, Point.X, Point.Y)
					|	1:
								Point := GetVertex(0);
								Point.Y := command.NewPos.Y;
								SetVertex(0, Point.X, Point.Y)
					|	2:
								Point := GetVertex(2);
								Point.X := command.NewPos.X;
								SetVertex(2, Point.X, Point.Y)
					|	3:
								Point := GetVertex(2);
								Point.Y := command.NewPos.Y;
								SetVertex(2, Point.X, Point.Y)
					ELSE
					END
				END
			ELSIF command IS CommandStopConstruct THEN
				command(CommandStopConstruct).Result := TRUE;
				IF FConstructing THEN
					FConstructing := FALSE;
					command(CommandStopConstruct).Result := FALSE
				END
			ELSE
				HandleCommand^(command)
			END
		END HandleCommand;

		PROCEDURE GetVerticesCount(): LONGINT;
		BEGIN
			RETURN 4
		END GetVerticesCount;

		PROCEDURE GetVertex(Index: LONGINT): VCTypes.FloatPoint;
		VAR
			fp: VCTypes.FloatPoint;
		BEGIN
			CASE Index OF
				0: RETURN GetBasePoint(0)
			|	1:
				fp.X := GetBasePoint(1).X;
				fp.Y := GetBasePoint(0).Y;
				RETURN fp
			|	2: RETURN GetBasePoint(1)
			|	3:
				fp.X := GetBasePoint(0).X;
				fp.Y := GetBasePoint(1).Y;
				RETURN fp
			ELSE
			END
		END GetVertex;

		PROCEDURE SetVertex(Index: LONGINT; X, Y: REAL);
		VAR
			fp0, fp1: VCTypes.FloatPoint;
		BEGIN
			fp0 := GetBasePoint(0);
			fp1 := GetBasePoint(1);
			CASE Index OF
				0:
					SetBasePoint(0, MIN(X, fp1.X), MIN(Y, fp1.Y))
			|	1:
					SetBasePoint(1, MAX(X, fp0.X), fp1.Y);
					SetBasePoint(0, fp0.X, MIN(Y, fp1.Y))
			|	2:
					SetBasePoint(1, MAX(X, fp0.X), MAX(Y, fp0.Y))
			|	3:
					SetBasePoint(0, MIN(X, fp1.X), fp0.Y);
					SetBasePoint(1, fp1.X, MAX(Y, fp0.Y))
			ELSE
			END
		END SetVertex;

		PROCEDURE IsBadRect(): BOOLEAN;
		VAR
			v00, v0, v1, v2, v3: VCTypes.FloatPoint;
		BEGIN

			v0 := GetVertex(0); v00 := v0;
			v1 := GetVertex(1);
			v2 := GetVertex(2);
			v3 := GetVertex(3);

			v0.X := v1.X - v0.X;
			v0.Y := v1.Y - v0.Y;

			v1.X := v2.X - v1.X;
			v1.Y := v2.Y - v1.Y;

			v2.X := v3.X - v2.X;
			v2.Y := v3.Y - v2.Y;

			v3.X := v00.X - v3.X;
			v3.Y := v00.Y - v3.Y;

			RETURN (ABS(v0.X * v0.X + v0.Y * v0.Y) < 0.1) OR
				(ABS(v1.X * v1.X + v1.Y * v1.Y) < 0.1) OR
				(ABS(v2.X * v2.X + v2.Y * v2.Y) < 0.1) OR
				(ABS(v3.X * v3.X + v3.Y * v3.Y) < 0.1)
		END IsBadRect;

		(*property Text: ARRAY OF CHAR read FText write SetText;*)
	END RectVisualObject;

	LineVisualObject = OBJECT(BaseVisualObject)
	VAR
		FConstructing: BOOLEAN;
		FCurrentPoint: LONGINT;

		PROCEDURE HandleCommand(VAR command: Command);
		VAR
			i: LONGINT;
			sX1f, sY1f, sX2f, sY2f: REAL;
			sX1, sY1, sX2, sY2: LONGINT;
			D: REAL;
			vertex1, vertex2: VCTypes.FloatPoint;
		BEGIN
			IF command IS CommandConstructPoint THEN
				WITH command: CommandConstructPoint DO
					IF ~FConstructing THEN
						FConstructing := TRUE;
						BeginUpdate;
						ClearBasePoints;
						FCurrentPoint := 0;
						AddBasePoint(command.Pos.X, command.Pos.Y);
						EndUpdate
					END;
					command.Result := NotNeedToStopConstruct(FCurrentPoint + 1);
					IF ~command.Result THEN
						FConstructing := FALSE;
						RETURN
					END;
					AddBasePoint(command.Pos.X, command.Pos.Y);
					INC(FCurrentPoint)
				END
			ELSIF command IS CommandGetCursor THEN
				WITH command: CommandGetCursor DO
					IF command.Hit.Type # HT.OUTSIDE THEN
						command.Cursor := CR.SIZEALL
					ELSE
						command.Cursor := CR.DEFAULT
					END
				END
			ELSIF command IS CommandHitTest THEN
				WITH command: CommandHitTest DO
					command.Hit.Type := HT.OUTSIDE;
					i := GetVerticesCount() - 1;
					WHILE i >= 0 DO
						vertex1 := GetVertex(i);
						command.ConvertIntf.LogToScreenPt(vertex1.X, vertex1.Y, sX1f, sY1f);
						sX1 := round(sX1f); sY1 := round(sY1f);
						IF (ABS(command.Params.Pos.x - sX1) <= command.Params.Tolerance) &
							(ABS(command.Params.Pos.y - sY1) <= command.Params.Tolerance)
						THEN
							command.Hit.Type := HT.VERTEX;
							command.Hit.Index := i;
							RETURN
						END;
						DEC(i)
					END;
					i := GetVerticesCount() - 1;
					WHILE i >= 1 DO
						vertex1 := GetVertex(i);
						vertex2 := GetVertex(i - 1);
						command.ConvertIntf.LogToScreenPt(vertex1.X, vertex1.Y, sX1f, sY1f);
						command.ConvertIntf.LogToScreenPt(vertex2.X, vertex2.Y, sX2f, sY2f);
						sX1 := round(sX1f); sY1 := round(sY1f);
						sX2 := round(sX2f); sY2 := round(sY2f);
						D := LineDistance(command.Params.Pos.x, command.Params.Pos.y,
							sX1, sY1, sX2, sY2);
						IF D <= command.Params.Tolerance THEN
							command.Hit.Type := HT.INSIDE;
							command.Hit.Index := i - 1;
							RETURN
						END;
						DEC(i)
					END
				END
			ELSIF command IS CommandProcessConstruct THEN
				WITH command: CommandProcessConstruct DO
					IF FConstructing THEN
						SetBasePoint(FCurrentPoint, command.Pos.X, command.Pos.Y)
					END
				END
			ELSIF command IS CommandStopConstruct THEN
				WITH command: CommandStopConstruct DO
					command.Result := TRUE;
					IF FConstructing THEN
						FConstructing := FALSE;
						DeleteBasePoint(FCurrentPoint);
						IF GetVerticesCount() < 2 THEN
							command.Result := FALSE
						END
					END
				END
			ELSE
				HandleCommand^(command)
			END
		END HandleCommand;

		PROCEDURE GetVerticesCount(): LONGINT;
		BEGIN
			RETURN GetBasePointsCount()
		END GetVerticesCount;

		PROCEDURE GetVertex(Index: LONGINT): VCTypes.FloatPoint;
		BEGIN
			RETURN GetBasePoint(Index)
		END GetVertex;

		PROCEDURE SetVertex(Index: LONGINT; X, Y: REAL);
		BEGIN
			SetBasePoint(Index, X, Y);
		END SetVertex;

		PROCEDURE NotNeedToStopConstruct(Count: LONGINT): BOOLEAN;
		END NotNeedToStopConstruct;

		PROCEDURE Draw(canvas: VCTypes.LogicalCanvas);
		VAR
			i: LONGINT;
			pPts: VCTypes.PFloatPoints;
		BEGIN
			NEW(pPts, GetVerticesCount());
			FOR i := 0 TO GetVerticesCount() - 1 DO
				pPts[i] := GetVertex(i)
			END;
			canvas.DrawPolygon(pPts, 0.5, FALSE);
			Draw^(canvas)
		END Draw;

	END LineVisualObject;

	SimpleLineBlock = OBJECT(LineVisualObject)

		PROCEDURE NotNeedToStopConstruct(Count: LONGINT): BOOLEAN;
		BEGIN
			RETURN Count < 2
		END NotNeedToStopConstruct;

	END SimpleLineBlock;

	PolyLineBlock = OBJECT(LineVisualObject)

		PROCEDURE HandleCommand(VAR command: Command);
		BEGIN
			IF command IS CommandVControl THEN
				WITH command: CommandVControl DO
					CASE command.Hit.Type OF
						HT.INSIDE:
							InsertBasePoint(command.Hit.Index + 1, command.Pos.X, command.Pos.Y);
					|	HT.VERTEX:
							IF GetVerticesCount() > 2 THEN
								DeleteBasePoint(command.Hit.Index)
							END
					ELSE
					END
				END
			ELSE
				HandleCommand^(command)
			END
		END HandleCommand;

		PROCEDURE NotNeedToStopConstruct(Count: LONGINT): BOOLEAN;
		BEGIN
			RETURN TRUE
		END NotNeedToStopConstruct;

	END PolyLineBlock;

	BeginEndBlock = OBJECT(RectVisualObject)

		PROCEDURE Draw(canvas: VCTypes.LogicalCanvas);
		VAR
			fp0, fp1: VCTypes.FloatPoint;
		BEGIN
			IF IsBadRect() THEN
				Draw^(canvas);
				RETURN
			END;
			fp0 := GetBasePoint(0);
			fp1 := GetBasePoint(1);
			canvas.DrawRoundRect(fp0.X, fp0.Y, fp1.X, fp1.Y, 0.5);
			canvas.DrawText(fp0.X, fp0.Y, fp1.X, fp1.Y, 5, FText^);
			Draw^(canvas)
		END Draw;

	END BeginEndBlock;

	InputOutputBlock = OBJECT(RectVisualObject)
	VAR
		pPts: VCTypes.PFloatPoints;

		PROCEDURE &Init;
		BEGIN
			Init^;
			NEW(pPts, 4)
		END Init;

		PROCEDURE Draw(canvas: VCTypes.LogicalCanvas);
		VAR
			fp0, fp1: VCTypes.FloatPoint;
		BEGIN
			IF IsBadRect() THEN
				Draw^(canvas);
				RETURN
			END;
			pPts[0] := GetVertex(0);
			pPts[1] := GetVertex(1);
			pPts[2] := GetVertex(2);
			pPts[3] := GetVertex(3);
			pPts[0].X := pPts[0].X + (pPts[1].X - pPts[0].X) / 6;
			pPts[2].X := pPts[2].X - (pPts[2].X - pPts[3].X) / 6;
			canvas.DrawPolygon(pPts, 0.5, TRUE);
			fp0 := GetBasePoint(0);
			fp1 := GetBasePoint(1);
			canvas.DrawText(fp0.X, fp0.Y, fp1.X, fp1.Y, 5, FText^);
			Draw^(canvas)
		END Draw;

	END InputOutputBlock;

	ActionBlock = OBJECT(RectVisualObject)

		PROCEDURE Draw(canvas: VCTypes.LogicalCanvas);
		VAR
			fp0, fp1: VCTypes.FloatPoint;
		BEGIN
			IF IsBadRect() THEN
				Draw^(canvas);
				RETURN
			END;
			fp0 := GetBasePoint(0);
			fp1 := GetBasePoint(1);

			canvas.DrawRect(fp0.X, fp0.Y, fp1.X, fp1.Y, 0.5);

			canvas.DrawText(fp0.X, fp0.Y, fp1.X, fp1.Y, 5, FText^);
			Draw^(canvas)
		END Draw;

	END ActionBlock;

	ConditionBlock = OBJECT(RectVisualObject)
	VAR
		pPts: VCTypes.PFloatPoints;

		PROCEDURE &Init;
		BEGIN
			Init^;
			NEW(pPts, 4)
		END Init;

		PROCEDURE Draw(canvas: VCTypes.LogicalCanvas);
		VAR
			f0X, f1Y: REAL;
			fp0, fp1: VCTypes.FloatPoint;
		BEGIN

			IF IsBadRect() THEN
				Draw^(canvas);
				RETURN
			END;

			pPts[0] := GetVertex(0);
			pPts[1] := GetVertex(1);
			pPts[2] := GetVertex(2);
			pPts[3] := GetVertex(3);

			f0X := pPts[0].X;
			f1Y := pPts[1].Y;
			pPts[0].X := f0X + (pPts[1].X - f0X) / 2;
			pPts[1].Y := f1Y + (pPts[2].Y - f1Y) / 2;
			pPts[2].X := f0X + (pPts[1].X - f0X) / 2;
			pPts[3].Y := f1Y + (pPts[2].Y - f1Y) / 2;

			canvas.DrawPolygon(pPts, 0.5, TRUE);

			fp0 := GetBasePoint(0);
			fp1 := GetBasePoint(1);

			canvas.DrawText(fp0.X, fp0.Y, fp1.X, fp1.Y, 5, FText^);
			Draw^(canvas)
		END Draw;

	END ConditionBlock;

	SubBlock = OBJECT(RectVisualObject)

		PROCEDURE Draw(canvas: VCTypes.LogicalCanvas);
		VAR
			fp0, fp1: VCTypes.FloatPoint;
		BEGIN
			IF IsBadRect() THEN
				Draw^(canvas);
				RETURN
			END;
			fp0 := GetBasePoint(0);
			fp1 := GetBasePoint(1);
			canvas.DrawRect(fp0.X, fp0.Y, fp1.X, fp1.Y, 0.5);
			canvas.DrawLine(fp0.X + (fp1.X - fp0.X) / 10, fp0.Y,
				fp0.X + (fp1.X - fp0.X) / 10, fp1.Y, 0.5);
			canvas.DrawLine(fp1.X - (fp1.X - fp0.X) / 10, fp0.Y,
				fp1.X - (fp1.X - fp0.X) / 10, fp1.Y, 0.5);
			canvas.DrawText(fp0.X, fp0.Y, fp1.X, fp1.Y, 5, FText^);
			Draw^(canvas)
		END Draw;

	END SubBlock;

	TextBlock = OBJECT(RectVisualObject)

		PROCEDURE Draw(Canvas: VCTypes.LogicalCanvas);
		VAR
			fp0, fp1: VCTypes.FloatPoint;
		BEGIN
			fp0 := GetBasePoint(0);
			fp1 := GetBasePoint(1);
			Canvas.DrawText(fp0.X, fp0.Y, fp1.X, fp1.Y, 5, FText^);
			Draw^(Canvas)
		END Draw;

	END TextBlock;

VAR
	BlockGenerators-: ARRAY 9 OF VisualObjectGen;
	NullText: Strings.String;

	PROCEDURE SimpleLineBlockGen*(): BaseVisualObject;
	VAR o: SimpleLineBlock;
	BEGIN NEW(o); RETURN o
	END SimpleLineBlockGen;

	PROCEDURE PolyLineBlockGen*(): BaseVisualObject;
	VAR o: PolyLineBlock;
	BEGIN NEW(o); RETURN o
	END PolyLineBlockGen;

	PROCEDURE BeginEndBlockGen*(): BaseVisualObject;
	VAR o: BeginEndBlock;
	BEGIN NEW(o); RETURN o
	END BeginEndBlockGen;

	PROCEDURE InputOutputBlockGen*(): BaseVisualObject;
	VAR o: InputOutputBlock;
	BEGIN NEW(o); RETURN o
	END InputOutputBlockGen;

	PROCEDURE ActionBlockGen*(): BaseVisualObject;
	VAR o: ActionBlock;
	BEGIN NEW(o); RETURN o
	END ActionBlockGen;

	PROCEDURE ConditionBlockGen*(): BaseVisualObject;
	VAR o: ConditionBlock;
	BEGIN NEW(o); RETURN o
	END ConditionBlockGen;

	PROCEDURE SubBlockGen*(): BaseVisualObject;
	VAR o: SubBlock;
	BEGIN NEW(o); RETURN o
	END SubBlockGen;

	PROCEDURE TextBlockGen*(): BaseVisualObject;
	VAR o: TextBlock;
	BEGIN NEW(o); RETURN o
	END TextBlockGen;

	PROCEDURE LineDistance(X, Y, X1, Y1, X2, Y2: LONGINT): REAL;
	VAR
		A1, B1, C1, A2, B2, C2, DD: LONGINT;
		D, Px, Py: REAL;

		PROCEDURE Xchg(VAR A, B: LONGINT);
		VAR
			C: LONGINT;
		BEGIN
			C := A;
			A := B;
			B := C
		END Xchg;

	BEGIN
		IF (X2 = X1) & (Y2 = Y1) THEN
			RETURN Math.sqrt((X - X1)*(X - X1) + (Y - Y1)*(Y - Y1))
		ELSE
			A1 := Y2 - Y1;
			B1 := X1 - X2;
			C1 := Y1*(X2 - X1) - X1*(Y2 - Y1);
			D := ABS(A1*X + B1*Y + C1)/Math.sqrt(A1*A1 + B1*B1);
			IF X1 > X2 THEN Xchg(X1, X2) END;
			IF Y2 > Y1 THEN Xchg(Y1, Y2) END;
			A2 := -B1;
			B2 := A1;
			C2 := B1*X - A1*Y;
			DD := A1*B2 - B1*A2;
			Px := (-C1*B2 + B1*C2)/DD;
			Py := (-A1*C2 + C1*A2)/DD;
			IF (Px >= X1) & (Px <= X2) & (Py >= Y2) & (Py <= Y1) THEN
				RETURN D
			ELSE
				RETURN MIN(Math.sqrt((X - X1)*(X - X1) + (Y - Y1)*(Y - Y1)),
					Math.sqrt((X - X2)*(X - X2) + (Y - Y2)*(Y - Y2)))
			END
		END
	END LineDistance;

	PROCEDURE round(f: REAL): LONGINT;
	BEGIN
		RETURN ENTIER(f + 0.5)
	END round;

	PROCEDURE Init;
	BEGIN
		BlockGenerators[0] := NIL;
		BlockGenerators[1] := SimpleLineBlockGen;
		BlockGenerators[2] := PolyLineBlockGen;
		BlockGenerators[3] := BeginEndBlockGen;
		BlockGenerators[4] := InputOutputBlockGen;
		BlockGenerators[5] := ActionBlockGen;
		BlockGenerators[6] := ConditionBlockGen;
		BlockGenerators[7] := SubBlockGen;
		BlockGenerators[8] := TextBlockGen;

		NullText := Strings.NewString("Text")

	END Init;

BEGIN
	Init
END VCObjects.
