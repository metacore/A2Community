MODULE RegExpMaps; (** AUTHOR "Yaroslav Romanchenko (SAGE)"; PURPOSE "Map container classes for use in RegExp engine"; *)

IMPORT
	Vector, NewContainers;

TYPE

	DFAStateNumMapValue* = RECORD(Vector.Value)
		lstStates: NewContainers.LongintVector;
		iState-: LONGINT;
	END;

	DFAStateNumMap* = OBJECT(Vector.Vector)
	TYPE
		DFAStateNumMapValues = POINTER TO ARRAY OF DFAStateNumMapValue;
	VAR
		array: DFAStateNumMapValues;

		PROCEDURE &Init*;
		BEGIN
			New(Vector.INITIAL_SIZE, SIZEOF(DFAStateNumMapValue),
				{Vector.SORTED}, Create, Compare, NIL)
		END Init;

		PROCEDURE Create(nSize: LONGINT; VAR pArray: ANY; VAR adrArray: ADDRESS);
		BEGIN
			NEW(array, nSize);
			pArray := array; adrArray := ADDRESSOF(array^[0])
		END Create;

		PROCEDURE Compare(iLeft: LONGINT; VAR right: Vector.Value): LONGINT;
		BEGIN
			RETURN NewContainers.CompareLongintVectors(
				array^[iLeft].lstStates, right(DFAStateNumMapValue).lstStates)
		END Compare;

		PROCEDURE Add*(VAR lstStates: NewContainers.LongintVector; iState: LONGINT);
		VAR
			v: DFAStateNumMapValue;
		BEGIN
			v.lstStates := lstStates;
			v.iState := iState;
			AddInternal(v)
		END Add;

		PROCEDURE Contains*(lstStates: NewContainers.LongintVector): BOOLEAN;
		VAR
			v: DFAStateNumMapValue;
		BEGIN
			v.lstStates := lstStates;
			RETURN IndexOfInternal(v) >= 0
		END Contains;

		PROCEDURE Get*(lstStates: NewContainers.LongintVector): DFAStateNumMapValue;
		VAR
			v: DFAStateNumMapValue;
			pos: LONGINT;
		BEGIN
			v.lstStates := lstStates;
			pos := IndexOfInternal(v);
			ASSERT((pos >= 0) & (pos < Count), 101);
			RETURN array^[pos]
		END Get;

	END DFAStateNumMap;

	Transition* = RECORD
		iState-: LONGINT;
		iData-: LONGINT;
	END;

	TransitionMapValue* = RECORD(Vector.Value)
		trans-: Transition;
		iState-: LONGINT;
	END;

	TransitionMap* = OBJECT(Vector.Vector)
	TYPE
		TransitionMapValues = POINTER TO ARRAY OF TransitionMapValue;
	VAR
		array: TransitionMapValues;

		PROCEDURE &Init*;
		BEGIN
			New(Vector.INITIAL_SIZE, SIZEOF(TransitionMapValue),
				{Vector.SORTED}, Create, Compare, NIL)
		END Init;

		PROCEDURE Create(nSize: LONGINT; VAR pArray: ANY; VAR adrArray: ADDRESS);
		BEGIN
			NEW(array, nSize);
			pArray := array; adrArray := ADDRESSOF(array^[0])
		END Create;

		PROCEDURE Compare(iLeft: LONGINT; VAR right: Vector.Value): LONGINT;
		VAR
			itemLeft, itemRight: TransitionMapValue;
		BEGIN
			itemLeft := array^[iLeft];
			itemRight := right(TransitionMapValue);
			IF itemLeft.trans.iState < itemRight.trans.iState THEN
				RETURN -1
			ELSIF itemLeft.trans.iState > itemRight.trans.iState THEN
				RETURN 1
			ELSE
				IF itemLeft.trans.iData < itemRight.trans.iData THEN
					RETURN -1
				ELSIF itemLeft.trans.iData > itemRight.trans.iData THEN
					RETURN 1
				ELSE
					RETURN 0
				END
			END
		END Compare;

		PROCEDURE Add*(VAR trans: Transition; iState: LONGINT);
		VAR
			v: TransitionMapValue;
		BEGIN
			v.trans := trans;
			v.iState := iState;
			AddInternal(v)
		END Add;

		PROCEDURE Contains*(VAR x: Transition): BOOLEAN;
		VAR
			v: TransitionMapValue;
		BEGIN
			v.trans := x;
			RETURN IndexOfInternal(v) >= 0
		END Contains;

		PROCEDURE Get*(VAR x: Transition): TransitionMapValue;
		VAR
			v: TransitionMapValue;
			pos: LONGINT;
		BEGIN
			v.trans := x;
			pos := IndexOfInternal(v);
			ASSERT((pos >= 0) & (pos < Count), 101);
			RETURN array^[pos]
		END Get;

		PROCEDURE GetItem*(pos: LONGINT): TransitionMapValue;
		BEGIN
			ASSERT((pos >= 0) & (pos < Count), 101);
			RETURN array^[pos]
		END GetItem;

	END TransitionMap;

	PROCEDURE NewTransition*(iState, iData: LONGINT): Transition;
	VAR
		x: Transition;
	BEGIN
		x.iState := iState;
		x.iData := iData;
		RETURN x
	END NewTransition;

END RegExpMaps.

