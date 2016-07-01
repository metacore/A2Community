MODULE VCTypes;

(** AUTHOR "Yaroslav Romanchenko (SAGE) http://sage.com.ua/";
	PURPOSE "Visual Objects Container types"; *)

IMPORT
	Math, WMComponents, WMRectangles, WMGraphics,
	Vector;

TYPE
	FloatPoint* = RECORD(Vector.Value)
		X*, Y*: REAL
	END;

	FloatPoints = ARRAY OF FloatPoint;

	PFloatPoints* = POINTER TO FloatPoints;

	FloatPointVector* = OBJECT(Vector.Vector)
	VAR
		array: PFloatPoints;

		PROCEDURE &Init*;
		BEGIN
			New(Vector.INITIAL_SIZE, SIZEOF(FloatPoint), {}, Create, NIL, NIL)
		END Init;

		PROCEDURE Create(nSize: LONGINT; VAR pArray: ANY; VAR adrArray: ADDRESS);
		BEGIN
			NEW(array, nSize);
			pArray := array; adrArray := ADDRESSOF(array^[0])
		END Create;

		PROCEDURE Add*(X, Y: REAL);
		VAR
			v: FloatPoint;
			posDummy: LONGINT;
		BEGIN
			v.X := X;
			v.Y := Y;
			posDummy := AddInternal(v)
		END Add;

		PROCEDURE Insert*(pos: LONGINT; X, Y: REAL);
		VAR
			v: FloatPoint;
		BEGIN
			v.X := X;
			v.Y := Y;
			InsertInternal(pos, v)
		END Insert;

		PROCEDURE Set*(pos: LONGINT; X, Y: REAL);
		BEGIN
			ASSERT((pos >= 0) & (pos < Count), 101);
			array^[pos].X := X;
			array^[pos].Y := Y
		END Set;

		PROCEDURE Get*(pos: LONGINT): FloatPoint;
		BEGIN
			ASSERT((pos >= 0) & (pos < Count), 101);
			RETURN array^[pos]
		END Get;

	END FloatPointVector;

	Point* = WMGraphics.Point2d;

	Points = POINTER TO ARRAY OF Point;

	VisualContainerBase* = OBJECT(WMComponents.VisualComponent)

		PROCEDURE LogToScreen*(Value: REAL): REAL;
		END LogToScreen;

		PROCEDURE ScreenToLog*(Value: LONGINT): REAL;
		END ScreenToLog;

		PROCEDURE LogToScreenPt*(lX, lY: REAL; VAR sX, sY: REAL);
		END LogToScreenPt;

		PROCEDURE ScreenToLogPt*(sX, sY: LONGINT; VAR lX, lY: REAL);
		END ScreenToLogPt;

	END VisualContainerBase;

	LogicalCanvas* = OBJECT
	VAR
		FCanvas: WMGraphics.Canvas;
		FConvertIntf: VisualContainerBase;

		color: LONGINT;
		mode: LONGINT;

		(* Reusable buffers of polygons' points for DrawPolygon.
			Two buffers are maintained, for left and right parts.
			Left buffer also finally accumulates total polygon *)
		pPolyLeft, pPolyRight: Points;

		PROCEDURE &New*(Canvas: WMGraphics.Canvas; ConvertIntf: VisualContainerBase);
		BEGIN
			FCanvas := Canvas;
			FConvertIntf := ConvertIntf;
			mode := WMGraphics.ModeCopy
		END New;

		PROCEDURE SetColor*(cl: LONGINT);
		BEGIN
			color := cl
		END SetColor;

		PROCEDURE DrawVertex*(X, Y: REAL);
		VAR
			fp1: FloatPoint;
			p1, p2, p3, p4: Point;
		BEGIN
			FConvertIntf.LogToScreenPt(X, Y, fp1.X, fp1.Y);
			p1.x := round(fp1.X) - 3;
			p1.y := round(fp1.Y) - 3;
			p2.x := p1.x;
			p2.y := round(fp1.Y) + 3;
			p3.x := round(fp1.X) + 3;
			p3.y := p2.y;
			p4.x := p3.x;
			p4.y := p1.y;
			FCanvas.Fill(WMRectangles.MakeRect(p1.x - 1, p1.y - 1, p3.x + 1, p3.y + 1), WMGraphics.Black, mode);
			FCanvas.Fill(WMRectangles.MakeRect(p1.x, p1.y, p3.x, p3.y), WMGraphics.White, mode);
			(*FCanvas.PolyLine([p1, p2, p3, p4], 4, TRUE, color, mode);*)
		END DrawVertex;

		(* Line's perpendicular vector *)
		PROCEDURE LinePerp(CONST fp1, fp2: FloatPoint; VAR vPerp: FloatPoint);
		BEGIN
			vPerp.X := -(fp2.Y - fp1.Y);
			vPerp.Y := fp2.X - fp1.X;
			normalize(vPerp)
		END LinePerp;

		PROCEDURE DrawLine*(X1, Y1, X2, Y2, LineWidth: REAL);
		VAR
			fp1, fp2: FloatPoint;
			vLinePerp: FloatPoint;
			fW: REAL;
			p1, p2, p3, p4: Point;
		BEGIN
			FConvertIntf.LogToScreenPt(X1, Y1, fp1.X, fp1.Y);
			FConvertIntf.LogToScreenPt(X2, Y2, fp2.X, fp2.Y);

(*			fW := FConvertIntf.LogToScreen(LineWidth);
			FCanvas.SetLineWidth(ENTIER(fW + 0.5));
			FCanvas.Line(ENTIER(fp1.X + 0.5), ENTIER(fp1.Y + 0.5),
				ENTIER(fp2.X + 0.5), ENTIER(fp2.Y + 0.5), color, mode);  *)
			
			(* Half LineWidth *)
			fW := 0.5 * FConvertIntf.LogToScreen(LineWidth);

			(* Represent line as polygon bar *)

			LinePerp(fp1, fp2, vLinePerp);

			(* Multiply by half LineWidth *)
			vLinePerp.X := fW * vLinePerp.X;
			vLinePerp.Y := fW * vLinePerp.Y;
			(* Add *)
			p1.x := round(fp1.X + vLinePerp.X);
			p1.y := round(fp1.Y + vLinePerp.Y);
			p2.x := round(fp2.X + vLinePerp.X);
			p2.y := round(fp2.Y + vLinePerp.Y);
			(* negate vector *)
			vLinePerp.X := -vLinePerp.X;
			vLinePerp.Y := -vLinePerp.Y;
			(* Add *)
			p3.x := round(fp1.X + vLinePerp.X);
			p3.y := round(fp1.Y + vLinePerp.Y);
			p4.x := round(fp2.X + vLinePerp.X);
			p4.y := round(fp2.Y + vLinePerp.Y);

			FCanvas.FillPolygonFlat([p1, p2, p4, p3], 4, color, mode)

		END DrawLine;

		PROCEDURE DrawRect*(X1, Y1, X2, Y2, LineWidth: REAL);
		VAR
			fp1, fp2: FloatPoint;
			fW: REAL;
			poly: ARRAY 10 OF Point;
		BEGIN
			FConvertIntf.LogToScreenPt(X1, Y1, fp1.X, fp1.Y);
			FConvertIntf.LogToScreenPt(X2, Y2, fp2.X, fp2.Y);
			fW := 0.5 * FConvertIntf.LogToScreen(LineWidth);

			(*
			 Represent rectangle as following polygon strip:

				 0_________
				  \        |9
				6|\\1___2  |
				 | \    |  |
				 |  |___|3 |
				7|_________|8

			*)
			poly[0].x := round(fp1.X - fW); poly[0].y := round(fp1.Y - fW);
			poly[1].x := round(fp1.X + fW); poly[1].y := round(fp1.Y + fW);
			poly[2].x := round(fp2.X - fW); poly[2].y := poly[1].y;
			poly[3].x := poly[2].x; poly[3].y := round(fp2.Y - fW);
			poly[4].x := poly[1].x; poly[4].y := poly[3].y;
			poly[5] := poly[1];
			poly[6] := poly[0];
			poly[7].x := poly[0].x; poly[7].y := round(fp2.Y + fW);
			poly[8].x := round(fp2.X + fW); poly[8].y := poly[7].y;
			poly[9].x := poly[8].x; poly[9].y := poly[0].y;

			FCanvas.FillPolygonFlat(poly, LEN(poly), color, mode)
		END DrawRect;

		PROCEDURE DrawRoundRect*(X1, Y1, X2, Y2, LineWidth: REAL);
		(*VAR
			sX1, sY1, sX2, sY2: LONGINT;*)
		BEGIN
			(*
			FConvertIntf.LogToScreenPt(X1, Y1, sX1, sY1);
			FConvertIntf.LogToScreenPt(X2, Y2, sX2, sY2);
			*)
			(*
			FCanvas.Pen.Width := FConvertIntf.LogToScreen(LineWidth);
			FCanvas.Brush.Style := bsSolid;
			FCanvas.RoundRect(sX1, sY1, sX2, sY2, (sX2 - sX1) DIV 6, (sY2 - sY1) DIV 2);
			*)
		END DrawRoundRect;

		PROCEDURE DrawText*(X1, Y1, X2, Y2, TextHeight: REAL; Text: ARRAY OF CHAR);
		VAR
			fp1, fp2: FloatPoint;
		BEGIN
			FConvertIntf.LogToScreenPt(X1, Y1, fp1.X, fp1.Y);
			FConvertIntf.LogToScreenPt(X2, Y2, fp2.X, fp2.Y);
			WMGraphics.DrawStringInRect(FCanvas,
				WMRectangles.MakeRect(round(fp1.X), round(fp1.Y), round(fp2.X), round(fp2.Y)),
				FALSE, WMGraphics.AlignCenter, WMGraphics.AlignCenter, Text)
		END DrawText;

		PROCEDURE DrawPolygon*(pPts: PFloatPoints; LineWidth: REAL; closed: BOOLEAN);

			(* Put one point to left list and 2 points to right list *)
			PROCEDURE PutSpecial(pL, pR: Points; VAR iL, iR: LONGINT; bReverseDir: BOOLEAN);
			VAR
				vPerp: FloatPoint;
				fCosAlpha: REAL;
			BEGIN
				PointSet(pL[iL], round(pPts[i].X + vNode.X), round(pPts[i].Y + vNode.Y));
				INC(iL);

				(* Make perpendicular to vNode and find cos alpha to one of the lines perpendicular *)
				FloatPointSet(vPerp, -vNode.Y, vNode.X);
				normalize(vPerp);
				fCosAlpha := cosAlpha(vLine1Perp, vPerp);

				FloatPointSet(vPerp, vPerp.X * fW / fCosAlpha, vPerp.Y * fW / fCosAlpha);

				IF bReverseDir THEN
					PointSet(pR[iR], round(pPts[i].X - vPerp.X), round(pPts[i].Y - vPerp.Y));
					INC(iR);
					PointSet(pR[iR], round(pPts[i].X + vPerp.X), round(pPts[i].Y + vPerp.Y));
					INC(iR)
				ELSE
					PointSet(pR[iR], round(pPts[i].X + vPerp.X), round(pPts[i].Y + vPerp.Y));
					INC(iR);
					PointSet(pR[iR], round(pPts[i].X - vPerp.X), round(pPts[i].Y - vPerp.Y));
					INC(iR)
				END

			END PutSpecial;

		VAR
			i, iLeft, iRight: LONGINT;
			fW, fCosHalfAlpha, fCosAlphaToCorner: REAL;
			vLine1Perp, vLine2Perp, vNode, vLine, vJoint: FloatPoint;
			bSpecialCase, bSimpleJoint: BOOLEAN;

		BEGIN

			IF (closed & (LEN(pPts^) < 3)) OR (~closed & (LEN(pPts^) < 2)) THEN
				RETURN
			END;

			FOR i := 0 TO LEN(pPts^) - 1 DO
				FConvertIntf.LogToScreenPt(pPts[i].X, pPts[i].Y, pPts[i].X, pPts[i].Y)
			END;
			fW := 0.5 * FConvertIntf.LogToScreen(LineWidth);

			(* To estimate highest possible lengths' try to figure
				out hardest case, a star, for example, 5-vertex star
				gives 10 resulting points at the left, 6 at the right
				and 16 in total, so, 2 is highest rate for left/right
				buffer and because left buffer accumulates final result
				rate 4 for it should be used
			*)
			IF (pPolyLeft = NIL) OR (LEN(pPolyLeft^) < LEN(pPts^) * 4) THEN
				NEW(pPolyLeft, LEN(pPts^) * 4)
			END;
			IF (pPolyRight = NIL) OR (LEN(pPolyRight^) < LEN(pPts^) * 2) THEN
				NEW(pPolyRight, LEN(pPts^) * 2)
			END;

			iLeft := 0;
			iRight := 0;
			bSimpleJoint := FALSE;

			FOR i := 0 TO LEN(pPts^) - 1 DO
				bSpecialCase := FALSE;
				IF ~closed & (i = LEN(pPts^) - 1) THEN
					LinePerp(pPts[LEN(pPts^) - 1], pPts[LEN(pPts^) - 2], vNode)
				ELSIF ~closed & (i = 0) THEN
					LinePerp(pPts[1], pPts[0], vNode)
				ELSE
					IF closed & (i = 0) THEN
						LinePerp(pPts[i], pPts[LEN(pPts^) - 1], vLine1Perp);
						LinePerp(pPts[i + 1], pPts[i], vLine2Perp);
					ELSIF closed & (i = LEN(pPts^) - 1) THEN
						LinePerp(pPts[i], pPts[i - 1], vLine1Perp);
						LinePerp(pPts[0], pPts[i], vLine2Perp)
					ELSE
						LinePerp(pPts[i], pPts[i - 1], vLine1Perp);
						LinePerp(pPts[i + 1], pPts[i], vLine2Perp)
					END;
					(* Average vector *)
					vNode.X := vLine1Perp.X + vLine2Perp.X;
					vNode.Y := vLine1Perp.Y + vLine2Perp.Y;
					normalize(vNode);
					fCosHalfAlpha := cosAlpha(vLine1Perp, vNode);
					(* Because we measure angle between perpendiculars
						the logic of finding a special case is inverted *)
					IF fCosHalfAlpha >= 0.5 (*fHalfSqrt2*) THEN
						(* If fCosHalfAlpha >= 0.5 than Half Alpha is less than or equal 60 degrees *)
						IF closed THEN
							bSimpleJoint := TRUE
						END;
						FloatPointSet(vNode, vNode.X / fCosHalfAlpha, vNode.Y / fCosHalfAlpha)
					ELSE (* Half Alpha is higher than 60 degrees *)
						bSpecialCase := TRUE;
						FloatPointSet(vNode, vNode.X * fW / fCosHalfAlpha, vNode.Y * fW / fCosHalfAlpha);
						IF closed THEN
							vJoint := vNode
						END;
						(* Is vNode inside corner or outside. Let's find its cos alpha to one of corner's lines *)
						IF closed & (i = 0) THEN
							FloatPointSet(vLine, pPts[LEN(pPts^) - 1].X - pPts[i].X, pPts[LEN(pPts^) - 1].Y - pPts[i].Y)
						ELSE
							FloatPointSet(vLine, pPts[i - 1].X - pPts[i].X, pPts[i - 1].Y - pPts[i].Y)
						END;
						fCosAlphaToCorner := cosAlpha(vLine, vNode);
						IF fCosAlphaToCorner < 0 THEN (* Outside. Negate vNode *)
							FloatPointSet(vNode, -vNode.X, -vNode.Y);
							(* Put 2 points to left list and one point to right list *)
							PutSpecial(pPolyRight, pPolyLeft, iRight, iLeft, FALSE)
						ELSE (* Put one point to left list and 2 points to right list *)
							PutSpecial(pPolyLeft, pPolyRight, iLeft, iRight, TRUE)
						END
					END
				END;
				IF ~bSpecialCase THEN
					FloatPointSet(vNode, vNode.X * fW, vNode.Y * fW);
					PointSet(pPolyLeft[iLeft], round(pPts[i].X + vNode.X), round(pPts[i].Y + vNode.Y));
					INC(iLeft);
					PointSet(pPolyRight[iRight], round(pPts[i].X - vNode.X), round(pPts[i].Y - vNode.Y));
					INC(iRight)
				END
			END;
			IF closed THEN
				IF bSimpleJoint THEN
					pPolyLeft[iLeft] := pPolyLeft[0];
					INC(iLeft);
					pPolyRight[iRight] := pPolyRight[0];
					INC(iRight)
				ELSE
					pPolyLeft[iLeft] := pPolyLeft[0];
					INC(iLeft);
					PointSet(pPolyRight[iRight], round(pPts[0].X - vJoint.X), round(pPts[0].Y - vJoint.Y));
					INC(iRight)
				END
			END;
			
			(* Sum up result *)
			i := iRight - 1;
			WHILE i >= 0 DO
				pPolyLeft[iLeft] := pPolyRight[i];
				INC(iLeft);
				DEC(i)
			END;

			FCanvas.FillPolygonFlat(pPolyLeft^, iLeft, color, mode)
			
		END DrawPolygon;

	END LogicalCanvas;

	PROCEDURE PointSet(VAR p: Point; x, y: LONGINT);
	BEGIN
		p.x := x;
		p.y := y
	END PointSet;

	PROCEDURE FloatPointSet(VAR fp: FloatPoint; x, y: REAL);
	BEGIN
		fp.X := x;
		fp.Y := y
	END FloatPointSet;

	PROCEDURE round(f: REAL): LONGINT;
	BEGIN
		RETURN ENTIER(f + 0.5)
	END round;

	PROCEDURE normalize(VAR v: FloatPoint);
	VAR
		fLen2, fInvSqrt: REAL;
	BEGIN
		fLen2 := v.X * v.X + v.Y * v.Y;
		IF fLen2 > 0 THEN
			fInvSqrt := 1 / Math.sqrt(fLen2);
			v.X := v.X * fInvSqrt;
			v.Y := v.Y * fInvSqrt
		END
	END normalize;

	(* cos(alpha) between vectors *)
	PROCEDURE cosAlpha(CONST v1, v2: FloatPoint): REAL;
	VAR
		fDot, fModules: REAL;
	BEGIN
		(* dot product *)
		fDot := v1.X * v2.X + v1.Y * v2.Y;
		(* multiplication of vectors' modules *)
		fModules := Math.sqrt(v1.X * v1.X + v1.Y * v1.Y) *
			Math.sqrt(v2.X * v2.X + v2.Y * v2.Y);
		RETURN fDot / fModules
	END cosAlpha;

BEGIN

END VCTypes.
