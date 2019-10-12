MODULE GenericsUse; (** AUTHOR ""; PURPOSE ""; *)

IMPORT
	Commands, SizeContainers := GenericsContainers(SIZE(*, C*));
	
PROCEDURE TestQueue(context: Commands.Context);
VAR
	queue: SizeContainers.Queue;
	i: SIZE;
BEGIN
	NEW(queue);
	FOR i := 0 TO 63 DO queue.Push(i) END;
	context.out.String("Popping sequentally added natural numbers from Queue (LIFO stack):"); context.out.Ln;
	WHILE queue.Pop(i) DO
		context.out.Int(i, 0); context.out.Char(20X)
	END;
	context.out.Ln
END TestQueue;

PROCEDURE TestDEQue(context: Commands.Context);
VAR
	deque: SizeContainers.DEQue;
	i: SIZE;
BEGIN
	NEW(deque);
	FOR i := 0 TO 63 DO deque.Push(i) END;
	context.out.String("Popping sequentally added natural numbers from DEQue (FIFO stack):"); context.out.Ln;
	WHILE deque.Pop(i) DO
		context.out.Int(i, 0); context.out.Char(20X)
	END;
	context.out.Ln
END TestDEQue;

PROCEDURE Do*(context: Commands.Context);
BEGIN
	TestQueue(context);
	TestDEQue(context);
END Do;

(*PROCEDURE C(l, r: SIZE): BOOLEAN;
BEGIN
	RETURN l < r
END C;*)

BEGIN

END GenericsUse.

GenericsUse.Do ~
System.Free GenericsUse ~