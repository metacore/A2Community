MODULE NewContainers;

(** AUTHOR "Yaroslav Romanchenko (SAGE) http://sage.com.ua/";
	PURPOSE "Standard collections based on Vector"; *)

IMPORT
	Vector, Strings, UTF8Strings, Commands;
	
TYPE

	(* CHAR vector *)

	CharValue* = RECORD(Vector.Value)
		value*: CHAR
	END;

	CharVector* = OBJECT(Vector.Vector)
	TYPE
		CharValues = POINTER TO ARRAY OF CharValue;
	VAR
		array: CharValues;

		PROCEDURE &Init*(options: SET);
		BEGIN
			New(Vector.INITIAL_SIZE, SIZEOF(CharValue), options, Create, Compare)
		END Init;
		
		PROCEDURE Create(nSize: LONGINT; VAR pArray: ANY; VAR adrArray: ADDRESS);
		BEGIN
			NEW(array, nSize);
			pArray := array; adrArray := ADDRESSOF(array^[0])
		END Create;
		
		PROCEDURE Compare(iLeft: LONGINT; VAR right: Vector.Value): LONGINT;
		BEGIN
			WITH right: CharValue DO
				IF array^[iLeft].value < right.value THEN
					RETURN -1
				ELSIF array^[iLeft].value > right.value THEN
					RETURN 1
				ELSE
					RETURN 0
				END
			END
		END Compare;

		PROCEDURE Add*(x: CHAR);
		VAR
			v: CharValue;
		BEGIN
			v.value := x;
			AddInternal(v)
		END Add;

		PROCEDURE Insert*(pos: LONGINT; x: CHAR);
		VAR
			v: CharValue;
		BEGIN
			v.value := x;
			InsertInternal(pos, v)
		END Insert;

		PROCEDURE IndexOf*(x: CHAR): LONGINT;
		VAR
			v: CharValue;
		BEGIN
			v.value := x;
			RETURN IndexOfInternal(v)
		END IndexOf;

		PROCEDURE Get*(pos: LONGINT): CHAR;
		BEGIN
			ASSERT((pos >= 0) & (pos < Count), 101);
			RETURN array^[pos].value
		END Get;

	END CharVector;

	(* LONGINT vector *)

	LongintValue* = RECORD(Vector.Value)
		value*: LONGINT
	END;

	LongintVector* = OBJECT(Vector.Vector)
	TYPE
		LongintValues = POINTER TO ARRAY OF LongintValue;
	VAR
		array: LongintValues;

		PROCEDURE &Init*(options: SET);
		BEGIN
			New(Vector.INITIAL_SIZE, SIZEOF(LongintValue), options, Create, Compare)
		END Init;

		PROCEDURE Create(nSize: LONGINT; VAR pArray: ANY; VAR adrArray: ADDRESS);
		BEGIN
			NEW(array, nSize);
			pArray := array; adrArray := ADDRESSOF(array^[0])
		END Create;
		
		PROCEDURE Compare(iLeft: LONGINT; VAR right: Vector.Value): LONGINT;
		BEGIN
			WITH right: LongintValue DO
				IF array^[iLeft].value < right.value THEN
					RETURN -1
				ELSIF array^[iLeft].value > right.value THEN
					RETURN 1
				ELSE
					RETURN 0
				END
			END
		END Compare;

		PROCEDURE Add*(x: LONGINT);
		VAR
			v: LongintValue;
		BEGIN
			v.value := x;
			AddInternal(v)
		END Add;

		PROCEDURE Insert*(pos: LONGINT; x: LONGINT);
		VAR
			v: LongintValue;
		BEGIN
			v.value := x;
			InsertInternal(pos, v)
		END Insert;

		PROCEDURE IndexOf*(x: LONGINT): LONGINT;
		VAR
			v: LongintValue;
		BEGIN
			v.value := x;
			RETURN IndexOfInternal(v)
		END IndexOf;

		PROCEDURE Get*(pos: LONGINT): LONGINT;
		BEGIN
			ASSERT((pos >= 0) & (pos < Count), 101);
			RETURN array^[pos].value
		END Get;

	END LongintVector;
	
	(** Vector of LONGINT vectors *)	

	LongintVectorValue* = RECORD(Vector.Value)
		value*: LongintVector
	END;

	LongintVectorVector* = OBJECT(Vector.Vector)
	TYPE
		LongintVectorValues = POINTER TO ARRAY OF LongintVectorValue;
	VAR
		array: LongintVectorValues;

		PROCEDURE &Init*(options: SET);
		BEGIN
			New(Vector.INITIAL_SIZE, SIZEOF(LongintVectorValue), options, Create, Compare)
		END Init;

		PROCEDURE Create(nSize: LONGINT; VAR pArray: ANY; VAR adrArray: ADDRESS);
		BEGIN
			NEW(array, nSize);
			pArray := array; adrArray := ADDRESSOF(array^[0])
		END Create;
		
		PROCEDURE Compare(iLeft: LONGINT; VAR right: Vector.Value): LONGINT;
		BEGIN
			RETURN CompareLongintVectors(array^[iLeft].value, right(LongintVectorValue).value)
		END Compare;

		PROCEDURE Add*(VAR x: LongintVector);
		VAR
			v: LongintVectorValue;
		BEGIN
			v.value := x;
			AddInternal(v)
		END Add;

		PROCEDURE Insert*(pos: LONGINT; VAR x: LongintVector);
		VAR
			v: LongintVectorValue;
		BEGIN
			v.value := x;
			InsertInternal(pos, v)
		END Insert;

		PROCEDURE IndexOf*(VAR x: LongintVector): LONGINT;
		VAR
			v: LongintVectorValue;
		BEGIN
			v.value := x;
			RETURN IndexOfInternal(v)
		END IndexOf;
		
		PROCEDURE Get*(pos: LONGINT): LongintVector;
		BEGIN
			ASSERT((pos >= 0) & (pos < Count), 101);
			RETURN array^[pos].value
		END Get;

	END LongintVectorVector;
	
	(** Vector of Strings *)	

	StringValue* = RECORD(Vector.Value)
		value*: Strings.String
	END;
	
	StringVector* = OBJECT(Vector.Vector)
	TYPE
		StringValues = POINTER TO ARRAY OF StringValue;
	VAR
		array: StringValues;

		PROCEDURE &Init*(options: SET);
		BEGIN
			New(Vector.INITIAL_SIZE, SIZEOF(StringValue), options, Create, Compare)
		END Init;

		PROCEDURE Create(nSize: LONGINT; VAR pArray: ANY; VAR adrArray: ADDRESS);
		BEGIN
			NEW(array, nSize);
			pArray := array; adrArray := ADDRESSOF(array^[0])
		END Create;
		
		PROCEDURE Compare(iLeft: LONGINT; VAR right: Vector.Value): LONGINT;
		BEGIN
			RETURN UTF8Strings.Compare(array^[iLeft].value^,
				right(StringValue).value^)
		END Compare;

		PROCEDURE Add*(CONST x: ARRAY OF CHAR);
		VAR
			v: StringValue;
		BEGIN
			v.value := Strings.NewString(x);
			AddInternal(v)
		END Add;

		PROCEDURE Insert*(pos: LONGINT; CONST x: ARRAY OF CHAR);
		VAR
			v: StringValue;
		BEGIN
			v.value := Strings.NewString(x);
			InsertInternal(pos, v)
		END Insert;

		PROCEDURE IndexOf*(CONST x: ARRAY OF CHAR): LONGINT;
		VAR
			v: StringValue;
		BEGIN
			v.value := Strings.NewString(x);
			RETURN IndexOfInternal(v)
		END IndexOf;

		PROCEDURE Get*(pos: LONGINT): Strings.String;
		BEGIN
			ASSERT((pos >= 0) & (pos < Count), 101);
			RETURN array^[pos].value
		END Get;

	END StringVector;

	PROCEDURE CompareLongintVectors*(left, right: LongintVector): LONGINT;
	VAR
		n, i, nRes: LONGINT;
	BEGIN
		n := MIN(left.Count, right.Count);
		IF n = 0 THEN
			IF left.Count > 0 THEN
				RETURN 1
			ELSIF right.Count > 0 THEN
				RETURN -1
			ELSE
				RETURN 0
			END
		ELSE
			i := 0; nRes := 0;
			WHILE (i < n) & (nRes = 0) DO
				IF left.Get(i) < right.Get(i) THEN
					nRes := -1
				ELSIF left.Get(i) > right.Get(i) THEN
					nRes := 1
				ELSE
					nRes := 0
				END;
				INC(i)
			END;
			IF nRes # 0 THEN
				RETURN nRes
			ELSIF left.Count > n THEN
				RETURN 1
			ELSIF right.Count > n THEN
				RETURN -1
			ELSE
				RETURN 0
			END
		END
	END CompareLongintVectors;

	PROCEDURE Test*(context : Commands.Context);
	VAR
		vLong: LongintVector;
		vChar: CharVector;
		i, j: LONGINT;
	BEGIN

		context.out.Ln;

		NEW(vLong, {});
		FOR i := 0 TO 25 DO
			vLong.Add(i)
		END;

		vLong.Remove(vLong.IndexOf(2));
		vLong.Remove(vLong.IndexOf(4));
		vLong.Remove(vLong.IndexOf(6));
		vLong.Remove(vLong.IndexOf(11));
		vLong.Remove(vLong.IndexOf(13));
		vLong.Remove(vLong.IndexOf(15));

		FOR i := 0 TO 25 DO
			j := vLong.IndexOf(i);
			context.out.Int(i, 0);
			IF j >= 0 THEN
				context.out.String(" located at pos: "); context.out.Int(j, 0)
			ELSE
				context.out.String(" not found")
			END;
			context.out.Ln
		END;

		context.out.Ln;

		NEW(vChar, {Vector.SORTED, Vector.NO_DUPLICATES});
		FOR i := 0 TO 25 DO
			vChar.Add(CHR(i + 61H))
		END;

		vChar.Remove(vChar.IndexOf('b'));
		vChar.Remove(vChar.IndexOf('d'));
		vChar.Remove(vChar.IndexOf('f'));
		vChar.Remove(vChar.IndexOf('k'));
		vChar.Remove(vChar.IndexOf('m'));
		vChar.Remove(vChar.IndexOf('o'));

		FOR i := 0 TO 25 DO
			j := vChar.IndexOf(CHR(i + 61H));
			context.out.Char(CHR(i + 61H));
			IF j >= 0 THEN
				context.out.String(" located at pos: "); context.out.Int(j, 0)
			ELSE
				context.out.String(" not found")
			END;
			context.out.Ln
		END
		
	END Test;

BEGIN

END NewContainers.

NewContainers.Test ~
SystemTools.Free NewContainers Vector ~


