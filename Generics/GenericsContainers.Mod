MODULE GenericsContainers(TYPE T(*, CONST C*));

CONST
	(* Initial size of containers *)
	INITIAL_SIZE* = 16;

TYPE

	PArrayT* = POINTER TO ARRAY OF T;

	(** Abstract container *)
	Container* = OBJECT
	VAR
	
		(* Size of base container (array)  *)
		iSize: SIZE;
	
		array: PArrayT;
		
		PROCEDURE &NewContainer*();
		BEGIN
			iSize := INITIAL_SIZE;
			NEW(array, iSize);
			Clear
		END NewContainer;
		
		PROCEDURE Clear*();
		BEGIN HALT(301)
		END Clear;

		PROCEDURE Count*(): SIZE;
		BEGIN HALT(301)
		END Count;
		
		PROCEDURE Grow*();
		VAR
			oldArray: PArrayT;
			iOldSize, i: SIZE;
		BEGIN
			oldArray := array;
			iOldSize := iSize;
			iSize := iSize * 2;
			NEW(array, iSize);
			FOR i := 0 TO iOldSize - 1 DO
				array[i] := oldArray[i]
			END
		END Grow;
		
	END Container;
	
	(** Abstract stack *)
	Stack* = OBJECT(Container)

		PROCEDURE Empty*(): BOOLEAN;
		BEGIN HALT(301)
		END Empty;

		PROCEDURE Pop*(VAR item: T): BOOLEAN;
		BEGIN HALT(301)
		END Pop;

		PROCEDURE Push*(CONST item: T);
		BEGIN HALT(301)
		END Push;

		PROCEDURE Top*(VAR item: T): BOOLEAN;
		BEGIN HALT(301)
		END Top;
		
	END Stack;

	(** Simple Queue or LIFO stack *)
	Queue* = OBJECT(Stack)
	VAR
		iPos: SIZE;

		PROCEDURE Clear*;
		BEGIN
			iPos := 0
		END Clear;

		PROCEDURE Count*(): SIZE;
		BEGIN
			RETURN iPos
		END Count;
		
		PROCEDURE Empty*(): BOOLEAN;
		BEGIN
			RETURN iPos = 0
		END Empty;
		
		PROCEDURE Pop*(VAR item: T): BOOLEAN;
		VAR
			bOk: BOOLEAN;
		BEGIN
			bOk := iPos # 0;
			IF bOk THEN DEC(iPos); item := array[iPos] END;
			RETURN bOk
		END Pop;

		PROCEDURE Push*(CONST item: T);
		BEGIN
			IF iPos = iSize THEN Grow END;
			array[iPos] := item;
			INC(iPos)
		END Push;

		PROCEDURE Top*(VAR item: T): BOOLEAN;
		VAR
			bOk: BOOLEAN;
		BEGIN
			bOk := iPos # 0;
			IF bOk THEN item := array[iPos - 1] END;
			RETURN bOk
		END Top;

	END Queue;
	
	(** Double Ended Queue or FIFO stack *)
	DEQue* = OBJECT(Stack)
	VAR
		iHead, iTail: SIZE;

		PROCEDURE Clear*();
		BEGIN
			iHead := 0;
			iTail := 0
		END Clear;

		PROCEDURE Count*(): SIZE;
		BEGIN
			RETURN iTail - iHead
		END Count;
		
		PROCEDURE Empty*(): BOOLEAN;
		BEGIN
			RETURN iTail - iHead = 0
		END Empty;

		PROCEDURE Grow*();
		VAR
			iCount, i: SIZE;
		BEGIN
			iCount := iTail - iHead;
			IF iCount = 0 THEN
				(* DEQue is empty, simply reset... *)
				iHead := 0; iTail := 0
			ELSIF iCount * 2 > iSize THEN
				(* Must grow, call default implementation *)
				Grow^
			ELSE
				(* may for now simply shift, to move free space to the end *)
				FOR i := 0 TO iCount - 1 DO
					array[i] := array[iHead + i]
				END;
				iHead := 0; iTail := iCount
			END
		END Grow;

		PROCEDURE Pop*(VAR item: T): BOOLEAN;
		VAR
			bOk: BOOLEAN;
		BEGIN
			bOk := iHead # iTail;
			IF iHead # iTail THEN item := array[iHead];INC(iHead) END;
			RETURN bOk
		END Pop;
		
		PROCEDURE Push*(CONST item: T);
		BEGIN
			IF iTail = iSize THEN Grow END;
			array[iTail] := item;
			INC(iTail)
		END Push;

		PROCEDURE Top*(VAR item: T): BOOLEAN;
		VAR
			bOk: BOOLEAN;
		BEGIN
			bOk := iHead # iTail;
			IF bOk THEN item := array[iHead] END;
			RETURN bOk
		END Top;

	END DEQue;

	(*
	Vector* = OBJECT(Container)
	CONST	
		(* Sorted by default (comp shouldn't be NIL!) *)
		SORTED* = 0;
		(* Prevents from inserting of duplicate value *)
		NO_DUPLICATES* = 1;
	VAR
		iPos: LONGINT;

		pCompA, pCompB: PItem;
		comp: LessComparer;

		bSorted: BOOLEAN;

		(* Options *)
		bNoDuplicates: BOOLEAN;

		(* temporary Item storage for Swap operation during sorting *)
		bufTempItem: POINTER TO ARRAY OF CHAR;

		PROCEDURE &NewVector*(iItemSize: LONGINT; pCompA, pCompB: PItem; comp: LessComparer; options: SET);
		BEGIN
			NewContainer(iItemSize);
			SELF.pCompA := pCompA;
			SELF.pCompB := pCompB;
			SELF.comp := comp;
			bNoDuplicates := {NO_DUPLICATES} * options # {};
			bSorted := {SORTED} * options # {};
			ASSERT(~bSorted OR (bSorted & (comp # NIL) & (pCompA # NIL) & (pCompB # NIL)));
			NEW(bufTempItem, iItemSize)
		END NewVector;

		PROCEDURE Clear*;
		BEGIN
			iPos := 0
		END Clear;

		PROCEDURE Count*(): LONGINT;
		BEGIN
			RETURN iPos
		END Count;

		PROCEDURE GetSorted*(): BOOLEAN;
		BEGIN
			RETURN bSorted
		END GetSorted;

		PROCEDURE SetSorted*(b: BOOLEAN);
		BEGIN
			ASSERT((comp # NIL) & (pCompA # NIL) & (pCompB # NIL));
			IF bSorted = b THEN
				RETURN
			END;
			bSorted := b;
			IF ~bSorted OR (iPos = 0) THEN
				RETURN
			END;
			QuickSort(0, iPos - 1)
		END SetSorted;

		PROCEDURE QuickSort(l, r: LONGINT);
		VAR
			i, j, x: LONGINT;
			addrI, addrJ, addrX: ADDRESS;
		BEGIN
			REPEAT
				i := l;
				j := r;
				x := l + (r - l) DIV 2;
				REPEAT
					addrI := addrArray + i * iItemSize;
					addrJ := addrArray + j * iItemSize;
					addrX := addrArray + x * iItemSize;
					WHILE less(addrI, addrX) DO
						INC(i);
						INC(addrI, iItemSize)
					END;
					WHILE less(addrX, addrJ) DO
						DEC(j);
						DEC(addrJ, iItemSize)
					END;
					IF i <= j THEN
						(* Swap i'th and j'th element *)
						SYSTEM.MOVE(addrI, ADDRESSOF(bufTempItem^[0]), iItemSize);
						SYSTEM.MOVE(addrJ, addrI, iItemSize);
						SYSTEM.MOVE(ADDRESSOF(bufTempItem^[0]), addrJ, iItemSize);
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

		PROCEDURE less(addrCompA, addrCompB: ADDRESS): BOOLEAN;
		BEGIN
			SYSTEM.MOVE(addrCompA, ADDRESSOF(pCompA^), iItemSize);
			SYSTEM.MOVE(addrCompB, ADDRESSOF(pCompB^), iItemSize);
			RETURN comp(pCompA, pCompB)
		END less;

		PROCEDURE IndexOfInternal*(VAR x: Item): LONGINT;
		VAR
			pos: LONGINT;
			bFound: BOOLEAN;
		BEGIN
			ASSERT((comp # NIL) & (pCompA # NIL) & (pCompB # NIL));
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
		PROCEDURE AddInternal*(VAR x: Item): LONGINT;
		VAR
			pos: LONGINT;
		BEGIN
			IF bSorted THEN
				(* Only Addition is possible. Just Add into sorted array *)
				pos := AddUnlocked(x)
			ELSE
				(* Append to unsorted array *)
				IF bNoDuplicates THEN
					ASSERT(FindSequentially(x) = -1)
				END;
				IF iPos = iSize THEN
					Grow
				END;
				(* Put x at Count position *)
				SYSTEM.MOVE(ADDRESSOF(x), addrArray + iPos * iItemSize, iItemSize);
				pos := iPos;
				INC(iPos)
			END;
			RETURN pos
		END AddInternal;

		PROCEDURE GetInternal*(pos: LONGINT; VAR x: Item);
		BEGIN
			ASSERT((pos >= 0) & (pos < iPos), 101);
			SYSTEM.MOVE(addrArray + pos * iItemSize, ADDRESSOF(x), iItemSize)
		END GetInternal;

		PROCEDURE SetInternal*(pos: LONGINT; VAR x: Item);
		BEGIN
			ASSERT((pos >= 0) & (pos < iPos), 101);
			SYSTEM.MOVE(ADDRESSOF(x), addrArray + pos * iItemSize, iItemSize)
		END SetInternal;

		PROCEDURE InsertInternal*(pos: LONGINT; VAR x: Item);
		VAR
			i, posDummy: LONGINT;
			adrSrc: ADDRESS;
		BEGIN
			ASSERT((pos >= 0) & (pos < iPos), 101);
			IF bSorted THEN
				(* Only Addition is possible. Just Add into sorted array *)
				posDummy := AddUnlocked(x)
			ELSE
				(* Insert to unsorted array *)
				IF bNoDuplicates THEN
					ASSERT(FindSequentially(x) = -1)
				END;
				IF iPos = iSize THEN
					Grow
				END;
				i := iPos - 1;
				adrSrc := addrArray + i * iItemSize;
				WHILE i >= pos DO
					(*array[i + 1] := array[i];*)
					SYSTEM.MOVE(adrSrc, adrSrc + iItemSize, iItemSize);
					DEC(adrSrc, iItemSize);
					DEC(i)
				END;
				(* Put x at pos position *)
				SYSTEM.MOVE(ADDRESSOF(x), addrArray + pos * iItemSize, iItemSize);
				INC(iPos)
			END
		END InsertInternal;

		(** Remove an object from the list. Remove may block if number of calls to Lock is bigger than the number of calls to Unlock *)
		PROCEDURE Remove*(pos: LONGINT);
		VAR
			i: LONGINT;
			adrSrc: ADDRESS;
		BEGIN
			ASSERT((pos >= 0) & (pos < iPos), 101);
			i := pos;
			adrSrc := addrArray + (i + 1) * iItemSize;
			WHILE i < iPos - 1 DO
				(*array[i] := array[i + 1];*)
				SYSTEM.MOVE(adrSrc, adrSrc - iItemSize, iItemSize);
				INC(adrSrc, iItemSize);
				INC(i)
			END;
			DEC(iPos)
		END Remove;

		PROCEDURE FindSequentially(VAR x: Item): LONGINT;
		VAR
			i: LONGINT;
			addrI, addrX: ADDRESS;
		BEGIN
			i := 0;
			addrI := addrArray;
			addrX := ADDRESSOF(x);
			WHILE i < iPos DO
				IF ~less(addrI, addrX) & ~less(addrX, addrI) THEN
					RETURN i
				END;
				INC(i);
				INC(addrI, iItemSize)
			END;
			RETURN -1
		END FindSequentially;

		(* Binary search *)
		PROCEDURE FindPosition(VAR x: Item; VAR bFound: BOOLEAN): LONGINT;
		VAR
			lower, middle, upper: LONGINT;
			addrMiddle: ADDRESS;
		BEGIN
			bFound := FALSE;
			IF iPos = 0 THEN RETURN 0 END;
			lower := 0;
			upper := iPos - 1;
			WHILE lower <= upper DO
				middle := lower + (upper - lower) DIV 2;
				addrMiddle := addrArray + middle * iItemSize;
				IF less(addrMiddle, ADDRESSOF(x)) THEN
					(* array[middle] < x *)
					lower := middle + 1
				ELSIF less(ADDRESSOF(x), addrMiddle) THEN
					(* x < array[middle] *)
					upper := middle - 1
				ELSE
					(* array[middle] = x *)
					bFound := TRUE;
					RETURN middle
				END;
			END;
			IF lower <= upper THEN
				RETURN upper
			ELSE
				RETURN lower
			END;
		END FindPosition;

		PROCEDURE AddUnlocked(VAR x: Item): LONGINT;
		VAR
			pos, i: LONGINT;
			bFound: BOOLEAN;
			adrSrc: ADDRESS;
		BEGIN
			pos := FindPosition(x, bFound);
			IF bNoDuplicates THEN
				ASSERT(~bFound)
			END;
			IF iPos = iSize THEN
				Grow
			END;
			i := iPos - 1;
			adrSrc := addrArray + i * iItemSize;
			WHILE i >= pos DO
				(*array[i + 1] := array[i];*)
				SYSTEM.MOVE(adrSrc, adrSrc + iItemSize, iItemSize);
				DEC(adrSrc, iItemSize);
				DEC(i)
			END;
			(* Put x at pos position *)
			SYSTEM.MOVE(ADDRESSOF(x), addrArray + pos * iItemSize, iItemSize);
			INC(iPos);
			RETURN pos
		END AddUnlocked;

		PROCEDURE IsEmpty*(): BOOLEAN;
		BEGIN
			RETURN iPos = 0
		END IsEmpty;

	END Vector;
	*)
	
END GenericsContainers.
