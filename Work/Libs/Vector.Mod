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

	(* Sorted by default (compareRef shouldn't be NIL!) *)
	SORTED* = 0;

	(* Prevents from inserting of duplicate value (compareRef may be NIL, but, SLOW
		sequental search will be used for prevention of duplicates insertion. Specify
		compareRef for ability to use binary search, that means FAST performance!) *)
	NO_DUPLICATES* = 1;

	(* Supports turning into sortable on demand (Both compareRef and OpCompareIdx
		shouldn't be NIL in that case!) 	*)
	(*! NOTE: On big amounts of data it's MUCH faster to create at the begining
		Vector with SORTABLE option, add all the data and only then sort data by
		calling SetSorted(TRUE), instead of making Vector with SORTED option *)
	SORTABLE* = 2;

	(* Initial size of dynamic array *)
	INITIAL_SIZE* = 4;

TYPE
	(** OpCreate creates new array of needed size and returns pointer to array and address of first element *)
	OpCreate = PROCEDURE {DELEGATE} (nSize: LONGINT; VAR pArray: ANY; VAR adrArray: ADDRESS);

	(** OpCompareIdx and OpCompareRef both defines an Operation that compares two Values.
		The only difference between them that OpCompareIdx gives both compared values by indexes in array and
		OpCompareRef gives right Value by reference.
		The Operation then returns:
			-1	if the left Value is "smaller" then the right Value
			0	if both Values are "equal"
			1	if the left Value is "greater" then the right Value. *)
	OpCompareIdx = PROCEDURE {DELEGATE} (iLeft, iRight: LONGINT): LONGINT;
	OpCompareRef = PROCEDURE {DELEGATE} (iLeft: LONGINT; VAR right: Value): LONGINT;

	(** Abstract Value *)
	Value* = RECORD END;

	(** Abstract Vector object *)
	Vector* = OBJECT
	VAR
		Count-, nSize, nElementSize: LONGINT;
		pArray: ANY;
		adrArray: ADDRESS;

		create: OpCreate;
		compareIdx: OpCompareIdx;
		compareRef: OpCompareRef;

		(* Options *)
		bSorted, bNoDuplicates, bSortable: BOOLEAN;

		nReadLock: LONGINT;

		(* temporary Value storage for Swap operation during sorting *)
		tmpValue: POINTER TO ARRAY OF CHAR;

		PROCEDURE &New*(nSize, nElementSize: LONGINT; options: SET; create: OpCreate;
			compareRef: OpCompareRef; compareIdx: OpCompareIdx);
		BEGIN
			ASSERT(create # NIL);
			ASSERT(nElementSize > 0);
			bSorted := {SORTED} * options # {};
			bNoDuplicates := {NO_DUPLICATES} * options # {};
			bSortable := {SORTABLE} * options # {};
			ASSERT(~bSorted OR (bSorted & (compareRef # NIL)));
			ASSERT(~bSortable OR (bSortable & (compareRef # NIL) & (compareIdx # NIL)));
			SELF.nElementSize := nElementSize;
			SELF.create := create;
			SELF.compareIdx := compareIdx;
			SELF.compareRef := compareRef;
			IF (nSize >= 4) & (nSize <= 65536) THEN
				SELF.nSize := nSize
			ELSE
				SELF.nSize := INITIAL_SIZE
			END;
			Count := 0;
			create(SELF.nSize, pArray, adrArray);
			IF bSortable THEN
				NEW(tmpValue, nElementSize)
			END
		END New;

		PROCEDURE GetSorted*(): BOOLEAN;
		BEGIN
			RETURN bSorted
		END GetSorted;

		PROCEDURE SetSorted*(b: BOOLEAN);
		BEGIN
			IF ~bSortable OR (bSorted = b) THEN
				RETURN
			END;
			bSorted := b;
			IF ~bSorted OR (Count = 0) THEN
				RETURN
			END;
			QuickSort(0, Count - 1)
		END SetSorted;

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
				IF compareRef(i, x) = 0 THEN
					RETURN i
				END;
				INC(i)
			END;
			RETURN -1
		END FindSequentially;

(*
		PROCEDURE QuickSort(l, r: LONGINT);
		VAR
			i, j, x: LONGINT;
			adrI, adrJ: ADDRESS;
		BEGIN
			i := l;
			j := r;
			(*x := l + (r - l) DIV 2;*)
			x := (l + R) DIV 2;
			REPEAT
				WHILE compareIdx(i, x) < 0 DO
					INC(i)
				END;
				WHILE compareIdx(x, j) < 0 DO
					DEC(j)
				END;
				IF i <= j THEN
					(* Swap i'th and j'th element *)
					adrI := adrArray + i * nElementSize;
					adrJ := adrArray + j * nElementSize;
					(*t := a[i];*)
					SYSTEM.MOVE(adrI, ADDRESSOF(tmpValue^[0]), nElementSize);
					(*a[i] := a[j];*)
					SYSTEM.MOVE(adrJ, adrI, nElementSize);
					(*a[j] := t;*)
					SYSTEM.MOVE(ADDRESSOF(tmpValue^[0]), adrJ, nElementSize);
					INC(i);
					DEC(j)
				END
			UNTIL i > j;
			IF l < j THEN
				QuickSort(l, j)
			END;
			IF i < r THEN
				QuickSort(i, r)
			END
		END QuickSort;
*)

		PROCEDURE QuickSort(l, r: LONGINT);
		VAR
			i, j, x: LONGINT;
			adrI, adrJ: ADDRESS;
		BEGIN
			REPEAT
				i := l;
				j := r;
				x := l + (r - l) DIV 2;
				(*x := (l + r) DIV 2;*)
				REPEAT
					WHILE compareIdx(i, x) < 0 DO
						INC(i)
					END;
					WHILE compareIdx(x, j) < 0 DO
						DEC(j)
					END;
					IF i <= j THEN

						(* Swap i'th and j'th element *)
						adrI := adrArray + i * nElementSize;
						adrJ := adrArray + j * nElementSize;
						(*t := a[i];*)
						SYSTEM.MOVE(adrI, ADDRESSOF(tmpValue^[0]), nElementSize);
						(*a[i] := a[j];*)
						SYSTEM.MOVE(adrJ, adrI, nElementSize);
						(*a[j] := t;*)
						SYSTEM.MOVE(ADDRESSOF(tmpValue^[0]), adrJ, nElementSize);

						IF x = i THEN
							x := j
						ELSIF x = j THEN
							x := i
						END;

						INC(i);
						DEC(j)
					END
				UNTIL i > j;
				IF l < j THEN
					QuickSort(l, j)
				END;
				l := i
			UNTIL i >= r
		END QuickSort;

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
				value := compareRef(middle, x);
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

		(*
		PROCEDURE FindPosition(VAR x: Value; VAR bFound: BOOLEAN): LONGINT;
		VAR
			lowerBound, upperBound: LONGINT;
			middle: LONGINT;
			value: LONGINT;
		BEGIN
			bFound := FALSE;
			IF Count = 0 THEN RETURN 0; END;
			IF compare(0, x) >= 1 THEN RETURN 0; END;
			IF compare(Count - 1, x) <= -1 THEN RETURN Count; END;
			lowerBound := 0;
			upperBound := Count - 1;

			WHILE (upperBound - lowerBound) > 1 DO
				middle := (lowerBound + upperBound) DIV 2;
				value := compare(middle, x);
				IF value = 0 THEN bFound := TRUE; RETURN middle; END;
				IF value < 0 THEN
					lowerBound := middle;
				ELSE
					upperBound := middle;
				END;
			END;

			IF compare(lowerBound, x) = 0 THEN
				RETURN lowerBound;
			ELSE
				RETURN upperBound;
			END;
		END FindPosition;
		*)

		PROCEDURE Grow;
		VAR
			pOld{UNTRACED}: ANY;
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

BEGIN

END Vector.
