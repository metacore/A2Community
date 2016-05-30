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

		PROCEDURE &Init*();
		BEGIN
			New(Vector.INITIAL_SIZE, SIZEOF(DFAStateNumMapValue),
				{Vector.SORTED, Vector.NO_DUPLICATES}, Create, Compare)
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

		PROCEDURE IndexOf*(VAR lstStates: NewContainers.LongintVector): LONGINT;
		VAR
			v: DFAStateNumMapValue;
		BEGIN
			v.lstStates := lstStates;
			RETURN IndexOfInternal(v)
		END IndexOf;

		PROCEDURE Get*(pos: LONGINT): DFAStateNumMapValue;
		BEGIN
			ASSERT((pos >= 0) & (pos < GetCount()), 101);
			RETURN array[pos]
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

		PROCEDURE &Init*();
		BEGIN
			New(Vector.INITIAL_SIZE, SIZEOF(TransitionMapValue),
				{Vector.SORTED, Vector.NO_DUPLICATES}, Create, Compare)
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

		PROCEDURE IndexOf*(VAR x: Transition): LONGINT;
		VAR
			v: TransitionMapValue;
		BEGIN
			v.trans := x;
			RETURN IndexOfInternal(v)
		END IndexOf;

		PROCEDURE Get*(pos: LONGINT): TransitionMapValue;
		BEGIN
			ASSERT((pos >= 0) & (pos < GetCount()), 101);
			RETURN array[pos]
		END Get;

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

