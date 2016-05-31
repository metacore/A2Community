MODULE RegExpSubsetConstruct; (** AUTHOR "Yaroslav Romanchenko (SAGE)"; PURPOSE "Subset construction algorithm implementation"; *)

(*
// This code is in the public domain - feel free to do anything you 
// wish with it.
//
// Eli Bendersky (spur4444@yahoo.com)
//
*)

IMPORT
	Vector, NewContainers,
	RegExpMaps, RegExpNFA, RegExpDFA;

	PROCEDURE EpsClosure*(nfa: RegExpNFA.NFA; lstStates: NewContainers.LongintVector): NewContainers.LongintVector;
	VAR
		lstEpsClosure, lstUnchecked: NewContainers.LongintVector;
		i, iFrom, iTo: LONGINT;
	BEGIN
		NEW(lstEpsClosure, {Vector.SORTED, Vector.NO_DUPLICATES});
		NEW(lstUnchecked, {});
		FOR i := 0 TO lstStates.Count - 1 DO
			lstEpsClosure.Add(lstStates.Get(i));
			lstUnchecked.Add(lstStates.Get(i))
		END;
		WHILE ~lstUnchecked.IsEmpty() DO
			i := lstUnchecked.Count - 1;
			iFrom := lstUnchecked.Get(i);
			lstUnchecked.Remove(i);
			FOR iTo := 0 TO nfa.nSize - 1 DO
				IF (nfa.aTable[iFrom, iTo].iType = RegExpNFA.NODE_TYPE_EPS) &
					(lstEpsClosure.IndexOf(iTo) = -1)
				THEN
					lstEpsClosure.Add(iTo);
					lstUnchecked.Add(iTo)
				END
			END
		END;
		RETURN lstEpsClosure
	END EpsClosure;
	
	PROCEDURE Move*(nfa: RegExpNFA.NFA; lstStates: NewContainers.LongintVector; iData: LONGINT): NewContainers.LongintVector;
	VAR
		lstResult: NewContainers.LongintVector;
 		i, iFrom, iTo: LONGINT;
	BEGIN
		NEW(lstResult, {Vector.SORTED, Vector.NO_DUPLICATES});
		FOR i := 0 TO lstStates.Count - 1 DO
			iFrom := lstStates.Get(i);
			FOR iTo := 0 TO nfa.nSize - 1 DO
				IF (nfa.aTable[iFrom, iTo].iType = RegExpNFA.NODE_TYPE_DATA) &
					(nfa.aTable[iFrom, iTo].iData = iData)
				THEN
					lstResult.Add(iTo)
				END
			END
		END;
		RETURN lstResult
	END Move;

	PROCEDURE SubsetConstruct*(nfa: RegExpNFA.NFA): RegExpDFA.DFA;
	VAR
		dfa: RegExpDFA.DFA;
		trans: RegExpMaps.Transition;
		lstlstMarked, lstlstUnmarked: NewContainers.LongintVectorVector;
		mapDFAStateNum: RegExpMaps.DFAStateNumMap;
		lstNFAInitial, lstFirst, lstAState, lstNext: NewContainers.LongintVector;
		iNewState, iInput: LONGINT;
		
		PROCEDURE gen_new_state(): LONGINT;
		BEGIN
			INC(iNewState);
			RETURN iNewState
		END gen_new_state;
		
	BEGIN
		NEW(dfa);
		NEW(lstNFAInitial, {});
		NEW(lstlstMarked, {Vector.SORTED, Vector.NO_DUPLICATES});
		NEW(lstlstUnmarked, {Vector.SORTED, Vector.NO_DUPLICATES});
		NEW(mapDFAStateNum);
		iNewState := 0;
		lstNFAInitial.Add(nfa.iInitial);
		lstFirst := EpsClosure(nfa, lstNFAInitial);
		lstlstUnmarked.Add(lstFirst);
		dfa.iInitial := gen_new_state();
		mapDFAStateNum.Add(lstFirst, dfa.iInitial);
		WHILE ~lstlstUnmarked.IsEmpty() DO
			lstAState := lstlstUnmarked.Get(0);
			lstlstUnmarked.Remove(0);
			lstlstMarked.Add(lstAState);
			IF lstAState.IndexOf(nfa.iFinal) # -1 THEN
				IF mapDFAStateNum.Contains(lstAState) THEN
					dfa.lstFinal.Add(mapDFAStateNum.Get(lstAState).iState)
				END
			END;
			FOR iInput := 0 TO nfa.lstInputs.Count - 1 DO
				lstNext := EpsClosure(nfa,
					Move(nfa, lstAState, nfa.lstInputs.Get(iInput)));
				IF (lstlstUnmarked.IndexOf(lstNext) = -1) &
					(lstlstMarked.IndexOf(lstNext) = -1)
				THEN
					lstlstUnmarked.Add(lstNext);
					mapDFAStateNum.Add(lstNext, gen_new_state())
				END;
				IF mapDFAStateNum.Contains(lstAState) THEN
					trans := RegExpMaps.NewTransition(
						mapDFAStateNum.Get(lstAState).iState,
						nfa.lstInputs.Get(iInput));
					IF mapDFAStateNum.Contains(lstNext) & ~dfa.mapTransition.Contains(trans) THEN
						dfa.mapTransition.Add(trans,
							mapDFAStateNum.Get(lstNext).iState)
					END
				END
			END 
		END;
		dfa.nStates := mapDFAStateNum.Count;
		RETURN dfa
	END SubsetConstruct;

END RegExpSubsetConstruct.

