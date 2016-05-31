MODULE Vector;

(** AUTHOR "Yaroslav Romanchenko (SAGE) http://sage.com.ua/";
	PURPOSE "More advanced implementation of container (Vector) based on dynamic array";

	It is possible to implement practically any type of container on base of Vector,
	including Sets, Dictionaries and ect. As it done in FreePascal, for example.

	One of big advantages of this implementation that it can work with static elements,
	represented as descendants of base static Value type. So, no additional pointers needed for
	representing simple element types and records, practically any type of data supported!

	For achivement of this abilities importing of SYSTEM module needed.
*)

IMPORT
	SYSTEM;

CONST
	(** Vector options *)
	SORTED* = 0;
	NO_DUPLICATES* = 1;

	(* Initial size of dynamic array *)
	INITIAL_SIZE* = 4;

TYPE
	(** OpCreate creates new array of needed size and returns pointer to array and address of first element *)
	OpCreate = PROCEDURE {DELEGATE} (nSize: LONGINT; VAR pArray: ANY; VAR adrArray: ADDRESS);

	(** OpCompare defines an Operation that compares two Values.
		The Operation then returns:
			-1	if the left Value is "smaller" then the right Value
			0	if both Values are "equal"
			1	if the left Value is "greater" then the right Value. *)
	OpCompare = PROCEDURE {DELEGATE} (iLeft: LONGINT; VAR right: Value): LONGINT;

	(** Abstract Value *)
	Value* = RECORD END;

	(** Abstract Vector object *)
	Vector* = OBJECT
	VAR
		Count-, nSize, nElementSize: LONGINT;
		pArray: ANY;
		adrArray: ADDRESS;

		create: OpCreate;
		compare: OpCompare;

		(* Options *)
		bSorted, bNoDuplicates: BOOLEAN;

		nReadLock: LONGINT;

		PROCEDURE &New*(nSize, nElementSize: LONGINT; options: SET; create: OpCreate; compare: OpCompare);
		BEGIN
			ASSERT(create # NIL);
			ASSERT(nElementSize > 0);
			bSorted := {SORTED} * options # {};
			bNoDuplicates := {NO_DUPLICATES} * options # {};
			ASSERT(~bSorted OR (bSorted & (compare # NIL)));
			SELF.nElementSize := nElementSize;
			SELF.create := create;
			SELF.compare := compare;
			IF (nSize >= 4) & (nSize <= 65536) THEN
				SELF.nSize := nSize
			ELSE
				SELF.nSize := INITIAL_SIZE
			END;
			Count := 0;
			create(SELF.nSize, pArray, adrArray)
		END New;
		
		PROCEDURE IndexOfInternal*(VAR x: Value): LONGINT;
		VAR
			pos: LONGINT;
			bFound: BOOLEAN;
		BEGIN {EXCLUSIVE}
			IF bSorted THEN
				pos := FindPosition(x, bFound);
				IF bFound THEN
					RETURN pos
				ELSE
					RETURN -1
				END
			ELSE
				RETURN FindSequentially(x)
			END
		END IndexOfInternal;
		
		(** Add an object to the list. Add may block if number of
			calls to Lock is bigger than the number of calls to Unlock *)
		PROCEDURE AddInternal*(VAR x: Value);
		BEGIN {EXCLUSIVE}
			AWAIT(nReadLock = 0);
			IF bSorted THEN
				AddUnlocked(x)
			ELSE
				(* Append *)
				IF bNoDuplicates THEN
					ASSERT(FindSequentially(x) = -1)
				END;
				IF Count = nSize THEN
					Grow
				END;
				(* Put x at Count position *)
				SYSTEM.MOVE(ADDRESSOF(x), adrArray + Count * nElementSize, nElementSize);
				INC(Count)
			END
		END AddInternal;

		PROCEDURE InsertInternal*(pos: LONGINT; VAR x: Value);
		VAR
			i: LONGINT;
			adrSrc: ADDRESS;
		BEGIN {EXCLUSIVE}
			AWAIT(nReadLock = 0);
			ASSERT((pos >= 0) & (pos < Count), 101);
			IF bSorted THEN
				AddUnlocked(x)
			ELSE
				(* Insert *)
				IF bNoDuplicates THEN
					ASSERT(FindSequentially(x) = -1)
				END;
				IF Count = nSize THEN
					Grow
				END;
				i := Count - 1;
				adrSrc := adrArray + i * nElementSize;
				WHILE i >= pos DO
					(*array[i + 1] := array[i];*)
					SYSTEM.MOVE(adrSrc, adrSrc + nElementSize, nElementSize);
					DEC(adrSrc, nElementSize);
					DEC(i)
				END;
				(* Put x at pos position *)
				SYSTEM.MOVE(ADDRESSOF(x), adrArray + pos * nElementSize, nElementSize);
				INC(Count)
			END
		END InsertInternal;
		
		(** Remove an object from the list. Remove may block if number of calls to Lock is bigger than the number of calls to Unlock *)
		PROCEDURE Remove*(pos: LONGINT);
		VAR
			i: LONGINT;
			adrSrc: ADDRESS;
		BEGIN {EXCLUSIVE}
			AWAIT(nReadLock = 0);
			ASSERT((pos >= 0) & (pos < Count), 101);
			i := pos;
			adrSrc := adrArray + (i + 1) * nElementSize;
			WHILE i < Count - 1 DO
				(*array[i] := array[i + 1];*)
				SYSTEM.MOVE(adrSrc, adrSrc - nElementSize, nElementSize);
				INC(adrSrc, nElementSize);
				INC(i)
			END;
			(*?
			array[Count - 1] := NIL;
			*)
			DEC(Count)
		END Remove;
		
		PROCEDURE Clear*;
		BEGIN {EXCLUSIVE}
			AWAIT(nReadLock = 0);
			(*?
			FOR i := 0 TO Count - 1 DO
				array[i] := NIL
			END;
			*)
			Count := 0
		END Clear;

		PROCEDURE FindSequentially(VAR x: Value): LONGINT;
		VAR
			i: LONGINT;
		BEGIN
			i := 0;
			WHILE i < Count DO
				IF compare(i, x) = 0 THEN
					RETURN i
				END;
				INC(i)
			END;
			RETURN -1
		END FindSequentially;

		(* Binary search *)
		PROCEDURE FindPosition(VAR x: Value; VAR bFound: BOOLEAN): LONGINT;
		VAR
			lower, middle, upper: LONGINT;
			value: LONGINT;
		BEGIN
			bFound := FALSE;
			IF Count = 0 THEN RETURN 0 END;
			lower := 0;
			upper := Count - 1;
			WHILE lower <= upper DO
				middle := lower + (upper - lower) DIV 2;
				value := compare(middle, x);
				IF value = 0 THEN
					bFound := TRUE;
					RETURN middle
				ELSIF value < 0 THEN
					lower := middle + 1
				ELSE
					upper := middle - 1
				END;
			END;
			IF lower <= upper THEN
				RETURN upper
			ELSE
				RETURN lower
			END;
		END FindPosition;

		PROCEDURE Grow;
		VAR
			pOld: ANY;
			adrOld: ADDRESS;
			nOldSize: LONGINT;
		BEGIN
			adrOld := adrArray;
			nOldSize := nSize;
			nSize := nSize * 2;
			
			(* store pointer to prevent it be collected by GC before recreating an array *)
			pOld := pArray;
			create(nSize, pArray, adrArray);
			
			SYSTEM.MOVE(adrOld, adrArray, nOldSize * nElementSize)
		END Grow;

		PROCEDURE AddUnlocked(VAR x: Value);
		VAR
			pos, i: LONGINT;
			bFound: BOOLEAN;
			adrSrc: ADDRESS;
		BEGIN
			pos := FindPosition(x, bFound);
			IF bNoDuplicates THEN
				ASSERT(~bFound)
			END;
			IF Count = nSize THEN
				Grow
			END;
			i := Count - 1;
			adrSrc := adrArray + i * nElementSize;
			WHILE i >= pos DO
				(*array[i + 1] := array[i];*)
				SYSTEM.MOVE(adrSrc, adrSrc + nElementSize, nElementSize);
				DEC(adrSrc, nElementSize);
				DEC(i)
			END;
			(* Put x at pos position *)
			SYSTEM.MOVE(ADDRESSOF(x), adrArray + pos * nElementSize, nElementSize);
			INC(Count)
		END AddUnlocked;
		
		PROCEDURE IsEmpty*(): BOOLEAN;
		BEGIN
			RETURN Count = 0
		END IsEmpty;
		
		(** Lock prevents modifications to the list. All calls to Lock
			must be followed by a call to Unlock. Lock can be nested. *)
		PROCEDURE Lock*;
		BEGIN {EXCLUSIVE}
			INC(nReadLock); ASSERT(nReadLock > 0)
		END Lock;

		(** Unlock removes one modification lock. All calls to Unlock
			must be preceeded by a call to Lock. *)
		PROCEDURE Unlock*;
		BEGIN {EXCLUSIVE}
			DEC(nReadLock); ASSERT(nReadLock >= 0)
		END Unlock;

	END Vector;

END Vector.
