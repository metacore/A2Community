(*
// Copyright (c) www.scratchapixel.com August, 2007
// All rights reserved.
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
// * Redistributions of source code must retain the above copyright notice,
//   this list of conditions and the following disclaimer.
// * Redistributions in binary form must reproduce the above copyright notice,
//   this list of conditions and the following disclaimer in the documentation
//   and/or other materials provided with the distribution.
//
//  c++ -o render lesson6a.cpp -O3 -Wall

Translated to Active Oberon by Yaroslav Romanchenko (SAGE) August, 2008
*)

MODULE lesson1bench;

IMPORT
	Math, Events, Strings, Files, Commands, PreciseTimer,
	lesson1;

CONST

	DEBUGLOG = FALSE;
	
	TESTS = 10;

	EventClass = 3;
	EventSubclass = 3;
	moduleName = "Test";

	(* Color distance threshold for antialiasing *)
	DIST = 0.05;
	(* Antialiasing levels *)
	AA_LEVELS = 3;
	
	MAXBUFFER = 256;

TYPE

	cropWindow_t = RECORD
		xmin, ymin, xmax, ymax: REAL;
	END;

	screenWindow_t = RECORD
		left, right, top, bottom: REAL;
	END;

	options_t = RECORD
		(* // camera options_t *)
		imageWidth: LONGINT;
		imageHeight: LONGINT;
		bucketSizeX, bucketSizeY: LONGINT;
		cropWindow: cropWindow_t;
		fieldOfView: REAL;
		(* // display options_t *)
		displayName: ARRAY MAXBUFFER OF CHAR;
		gamma: REAL;
		backgroundColor: lesson1.Color;
	END;

	frameBuffer_t = POINTER TO ARRAY OF lesson1.Color;

	RenderContext = POINTER TO RECORD
		options: options_t;
		frameAspectRatio: REAL;
		(* // multi-threading related *)
		nBucketsX, nBucketsY: LONGINT;
		nComputedBuckets, nBucketsTotal: LONGINT;
		nActiveThreads, nThreadsTotal: LONGINT;
		(* pthread_mutex_t threadMutex; *)
		(* // frameBuffer *)
		FrmBuf: frameBuffer_t;
		screenWindow: screenWindow_t;
		(* // to compute prim ray_t direction *)
		dx, dy: REAL;
		angle: REAL;
	END;

	ThreadData = POINTER TO RECORD
		id: LONGINT;
		rc: RenderContext;
		nThreadComputedBuckets: LONGINT;
		nSecondaryRays: LONGINT;
	END;

	Bucket = RECORD
		x0, y0, x1, y1: LONGINT;
		nSecondaryRays: LONGINT;
		(* Line pixel buffers for antialising purposes
		  They will be initated once per computing thread *)
		FrmLineCur, FrmLinePrev: frameBuffer_t;
	END;

	CalcThread = OBJECT
	VAR
		td: ThreadData;
		bi, by, bx: LONGINT;
		b: Bucket;
		str1, str2: ARRAY 64 OF CHAR;
		FrmLineCur, FrmLinePrev: frameBuffer_t;

	PROCEDURE &New(td: ThreadData);
	BEGIN
		SELF.td := td;
		IncActiveThreads(td.rc);
	END New;

	BEGIN {ACTIVE}
		td.nSecondaryRays := 0;
		NEW(FrmLineCur, rc.options.imageWidth);
		NEW(FrmLinePrev, rc.options.imageWidth);
		WHILE GetNextBucket(td.rc, bi) DO
			INC(td.nThreadComputedBuckets);
			(* // compute Bucket coordinates *)
			bx := bi MOD td.rc.nBucketsX; (* // column index *)
			by := bi DIV td.rc.nBucketsY; (* // row index *)
			b.x0 := bx * td.rc.options.bucketSizeX;
			b.x1 := b.x0 + td.rc.options.bucketSizeX - 1;
			b.y0 := by * td.rc.options.bucketSizeY;
			b.y1 := b.y0 + td.rc.options.bucketSizeY - 1;
			
			IF DEBUGLOG THEN
				COPY("CalcThread # ", str1);
				Strings.IntToStr(td.id, str2);
				Strings.Append(str1, str2);
				Strings.Append(str1, ", computing bucket # ");
				Strings.IntToStr(bi, str2);
				Strings.Append(str1, str2);
				Strings.Append(str1, "...");
				Log(Events.Information, 0, str1, TRUE);
			END;
			
			b.FrmLineCur := FrmLineCur;
			b.FrmLinePrev := FrmLinePrev;
			RenderBucket(td.rc, b);
			INC(td.nSecondaryRays, b.nSecondaryRays);
		END;
		DecActiveThreads(td.rc);
	END CalcThread;

VAR
	context: Commands.Context;
	rc: RenderContext;
	
PROCEDURE Log(type, code : SHORTINT; msg: ARRAY OF CHAR; showOnKernelLog : BOOLEAN);
VAR message : Events.Message;
BEGIN
	COPY(msg, message);
	Events.AddEvent(moduleName, type, EventClass, EventSubclass, code, message, showOnKernelLog);
END Log;

PROCEDURE ceil(x: REAL): LONGINT;
BEGIN
	RETURN -ENTIER(-x)
END ceil;

PROCEDURE floor(x: REAL): LONGINT;
BEGIN
	RETURN ENTIER(x)
END floor;

PROCEDURE clamp(x, l, h: REAL): REAL;
BEGIN
	IF x > h THEN
		RETURN h
	ELSIF x < l THEN
		RETURN l
	ELSE
		RETURN x
	END
END clamp;

PROCEDURE pow(x, y: REAL): REAL;
BEGIN
	IF x = 0.0 THEN
		RETURN 0.0
	ELSE
		RETURN Math.exp(y * Math.ln(x))
	END
END pow;

PROCEDURE tan(x: REAL): REAL;
BEGIN
	RETURN Math.sin(x) / Math.cos(x)
END tan;

(* // math functions *)

PROCEDURE Pow2(nPow: LONGINT): LONGINT;
VAR
	i, nRes: LONGINT;
BEGIN
	nRes := 1;
	FOR i := 0 TO nPow - 1 DO
		nRes := nRes * 2
	END;
	RETURN nRes
END Pow2;

PROCEDURE Refine(rc: RenderContext; fX, fY: REAL; nLevel: LONGINT; CONST cFrmBuf: lesson1.Color): lesson1.Color;
VAR
	fDelta: REAL;
	ray00, ray10, ray01, ray11: lesson1.Ray;
	c00, c10, c01, c11, cAvg: lesson1.Color;
	fDist00, fDist10, fDist01, fDist11, fSum: REAL;
BEGIN

	fDelta := 1 / Pow2(AA_LEVELS - nLevel + 2);

	(* Trace additional 4 rays *)
	lesson1.ComputeSecondaryRays(
		fX, fY, fDelta,
	  rc.options.imageWidth, rc.options.imageHeight,
	  rc.frameAspectRatio,
	  ray00, ray10, ray01, ray11);
	  
	c00 := lesson1.Trace(ray00, 0, lesson1.objects, lesson1.numObjects,
		lesson1.light, lesson1.bgColor);
	c10 := lesson1.Trace(ray10, 0, lesson1.objects, lesson1.numObjects,
		lesson1.light, lesson1.bgColor);
	c01 := lesson1.Trace(ray01, 0, lesson1.objects, lesson1.numObjects,
		lesson1.light, lesson1.bgColor);
	c11 := lesson1.Trace(ray11, 0, lesson1.objects, lesson1.numObjects,
		lesson1.light, lesson1.bgColor);
		
	lesson1.clamp(c00);
	lesson1.clamp(c10);
	lesson1.clamp(c01);
	lesson1.clamp(c11);

	IF nLevel > 1 THEN
		IF lesson1.Distance(cFrmBuf, c00) > DIST THEN
			c00 := Refine(rc, fX - fDelta, fY - fDelta, nLevel - 1, c00);
		END;
		
		IF lesson1.Distance(cFrmBuf, c10) > DIST THEN
			c10 := Refine(rc, fX + fDelta, fY - fDelta, nLevel - 1, c10);
		END;
		
		IF lesson1.Distance(cFrmBuf, c01) > DIST THEN
			c01 := Refine(rc, fX - fDelta, fY + fDelta, nLevel - 1, c01);
		END;
		
		IF lesson1.Distance(cFrmBuf, c11) > DIST THEN
			c11 := Refine(rc, fX + fDelta, fY + fDelta, nLevel - 1, c11)
		END
	END;
	
	fDist00 := lesson1.Distance(cFrmBuf, c00);
	fDist10 := lesson1.Distance(cFrmBuf, c10);
	fDist01 := lesson1.Distance(cFrmBuf, c01);
	fDist11 := lesson1.Distance(cFrmBuf, c11);
	
	IF (fDist00 > DIST) OR (fDist10 > DIST) OR (fDist01 > DIST) OR (fDist11 > DIST) THEN
		
		fSum := fDist00 + fDist10 + fDist01 + fDist11;
		
		fDist00 := fDist00 / fSum;
		fDist10 := fDist10 / fSum;
		fDist01 := fDist01 / fSum;
		fDist11 := fDist11 / fSum;

		cAvg.r := (c00.r * fDist00 + c10.r * fDist10 + c01.r * fDist01 + c11.r * fDist11 + cFrmBuf.r) * 0.5;
		cAvg.g := (c00.g * fDist00 + c10.g * fDist10 + c01.g * fDist01 + c11.g * fDist11 + cFrmBuf.g) * 0.5;
		cAvg.b := (c00.b * fDist00 + c10.b * fDist10 + c01.b * fDist01 + c11.b * fDist11 + cFrmBuf.b) * 0.5;

		RETURN cAvg

	END;

	RETURN cFrmBuf

END Refine;

PROCEDURE RenderBucket(rc: RenderContext; VAR b: Bucket);
VAR
	i, j, nPix, w: LONGINT;
	ray: lesson1.Ray;
	pix: lesson1.Color;
	bBucketEdge: BOOLEAN;
	FrmTmp: frameBuffer_t;
BEGIN

	(* First pass of rendering *)
	FOR j := b.y0 TO b.y1 DO
		FOR i := b.x0 TO b.x1 DO
			(* Index of pixel in Frame Buffer *)
			nPix := j * rc.options.imageWidth + i;
			(* Compute primary ray *)
			lesson1.ComputePrimaryRay(i, j, rc.options.imageWidth, rc.options.imageHeight,
				rc.frameAspectRatio, ray);
			(* Trace ray *)
			rc.FrmBuf[nPix] := lesson1.Trace(ray, 0, lesson1.objects, lesson1.numObjects,
				lesson1.light, lesson1.bgColor);
			(* Limit values *)
			lesson1.clamp(rc.FrmBuf[nPix]);
		END
	END;
	
	(* Antialiasing *)
	w := rc.options.imageWidth;
	b.nSecondaryRays := 0;
	FOR j := b.y0 TO b.y1 DO
		FOR i := b.x0 TO b.x1 DO
			b.FrmLineCur[i] := rc.FrmBuf[j * w + i]
		END;	
		FOR i := b.x0 TO b.x1 DO
			(* Index of pixel in Frame Buffer *)
			nPix := j * w + i;
			pix := rc.FrmBuf[nPix];
			(* Pixel is on edge of bucket frame *)
			bBucketEdge := (i = b.x0) OR (j = b.y0) OR (i = b.x1) OR (j = b.y1);
			IF bBucketEdge OR
				(~bBucketEdge &
					((lesson1.Distance(pix, b.FrmLinePrev[i - 1]) > DIST) OR
					(lesson1.Distance(pix, b.FrmLinePrev[i]) > DIST) OR
					(lesson1.Distance(pix, b.FrmLinePrev[i + 1]) > DIST) OR
					(lesson1.Distance(pix, b.FrmLineCur[i - 1]) > DIST) OR
					(lesson1.Distance(pix, b.FrmLineCur[i + 1]) > DIST) OR
					(lesson1.Distance(pix, rc.FrmBuf[(j + 1) * w + (i - 1)]) > DIST) OR
					(lesson1.Distance(pix, rc.FrmBuf[(j + 1) * w + i]) > DIST) OR
					(lesson1.Distance(pix, rc.FrmBuf[(j + 1) * w + (i + 1)]) > DIST)))
			THEN
				INC(b.nSecondaryRays, 4);
				(*rc.FrmBuf[nPix] := lesson1.color(0.0, 0.0, 1.0)*)
				rc.FrmBuf[nPix] := Refine(rc, i + 0.5, j + 0.5, AA_LEVELS, rc.FrmBuf[nPix]);
			END
		END;
		FrmTmp := b.FrmLinePrev;
		b.FrmLinePrev := b.FrmLineCur;
		b.FrmLineCur := FrmTmp;
	END;
END RenderBucket;

PROCEDURE GetNextBucket(rc: RenderContext; VAR bi: LONGINT): BOOLEAN;
BEGIN 
(*  pthread_mutex_lock(&rc->threadMutex); *)
	BEGIN {EXCLUSIVE}
		bi := rc.nComputedBuckets;
		INC(rc.nComputedBuckets);
	END;
(*  pthread_mutex_unlock(&rc->threadMutex); *)
	RETURN bi < rc.nBucketsTotal;
END GetNextBucket;

PROCEDURE IncActiveThreads(rc: RenderContext);
BEGIN {EXCLUSIVE}
	INC(rc.nActiveThreads)
END IncActiveThreads;

PROCEDURE DecActiveThreads(rc: RenderContext);
BEGIN {EXCLUSIVE}
	DEC(rc.nActiveThreads)
END DecActiveThreads;

PROCEDURE Render(rc: RenderContext);
VAR
	w, h, xmin, ymin, xmax, ymax: LONGINT;
	iThread, iTest, iPix: LONGINT;
	threads: POINTER TO ARRAY OF CalcThread;
	td: ThreadData;
	t: HUGEINT;
	str: ARRAY 16 OF CHAR;
BEGIN
	(* // compute screen window coordinates *)
	w := rc.options.imageWidth;
	h := rc.options.imageHeight;
	rc.frameAspectRatio := w / h;
	IF rc.frameAspectRatio > 1 THEN
		rc.screenWindow.left := -rc.frameAspectRatio;
		rc.screenWindow.right := rc.frameAspectRatio;
		rc.screenWindow.top := 1;
		rc.screenWindow.bottom := -1
	ELSE
		rc.screenWindow.left := -1;
		rc.screenWindow.right := 1;
		rc.screenWindow.top := 1/rc.frameAspectRatio;
		rc.screenWindow.bottom := -1/rc.frameAspectRatio
	END;

	(* // transform ray_t to pixel space to world space *)
	rc.dx := (rc.screenWindow.right - rc.screenWindow.left)/w;
	rc.dy := (rc.screenWindow.top - rc.screenWindow.bottom)/h;

	(* // compute prim ray_t scaling factor based on field of view *)
	rc.angle := tan(rc.options.fieldOfView * 0.5 * Math.pi / 180.0);

	(* // compute crop window coordinates in raster space *)
	xmin := ceil(rc.options.cropWindow.xmin * w);
	ymin := ceil(rc.options.cropWindow.ymin * h);
	xmax := ceil(rc.options.cropWindow.xmax * w);
	ymax := ceil(rc.options.cropWindow.ymax * h);
	
	rc.nThreadsTotal := 1;
	
	WHILE rc.nThreadsTotal < 17 DO
	
		NEW(threads, rc.nThreadsTotal);
	
		rc.nBucketsX := rc.nThreadsTotal * 2(*ceil((xmax-xmin)/rc.options.bucketSize)*);
		rc.nBucketsY := rc.nThreadsTotal * 2(*ceil((ymax-ymin)/rc.options.bucketSize)*);
		rc.nBucketsTotal := rc.nBucketsX * rc.nBucketsY;
		rc.options.bucketSizeX := rc.options.imageWidth DIV (rc.nThreadsTotal * 2);
		rc.options.bucketSizeY := rc.options.imageHeight DIV (rc.nThreadsTotal * 2);
		
		context.out.String("nThreadsTotal: ");
		context.out.Int(rc.nThreadsTotal, 1);
		context.out.String(", bucket size: ");
		context.out.Int(rc.options.bucketSizeX, 1);
		context.out.String(" x ");
		context.out.Int(rc.options.bucketSizeY, 1);
		context.out.String(", nBucketsTotal: ");
		context.out.Int(rc.nBucketsTotal, 1);

		t := PreciseTimer.GetTicks();
		
		FOR iTest := 0 TO TESTS - 1 DO
			rc.nComputedBuckets := 0;
			rc.nActiveThreads := 0;
			FOR iThread := 0 TO rc.nThreadsTotal - 1 DO
				NEW(td);
				td.id := iThread;
				td.rc := rc;
				td.nThreadComputedBuckets := 0;
				NEW(threads^[iThread], td)
			END;
			BEGIN {EXCLUSIVE}
				AWAIT(rc.nActiveThreads = 0)
			END;
		END;
		
		Strings.FloatToStr(PreciseTimer.GetTime(PreciseTimer.GetTicks() - t) / TESTS, 0, 4, 0, str);
		context.out.String(", time elapsed: ");
		context.out.String(str);
		context.out.Ln;
		context.out.String("nThreadComputedBuckets: [");
		FOR iThread := 0 TO rc.nThreadsTotal - 1 DO
			IF iThread # 0 THEN
				context.out.String(", ");
			END;
			context.out.Int(threads^[iThread].td.nThreadComputedBuckets, 1);
		END;
		context.out.String("]");
		context.out.Ln;
		context.out.String("nSecondaryRays: [");
		FOR iThread := 0 TO rc.nThreadsTotal - 1 DO
			IF iThread # 0 THEN
				context.out.String(", ");
			END;
			context.out.Int(threads^[iThread].td.nSecondaryRays, 1);
		END;
		context.out.String("]");
		context.out.Ln;
		
		rc.nThreadsTotal := rc.nThreadsTotal * 2; 
		
	END;

	(* KernelLog.String("Threads terminated"); KernelLog.Ln; *)

	(* //gamma correction *)
	IF rc.options.gamma # 1 THEN
		FOR iPix := 0 TO w * h - 1 DO
			rc.FrmBuf[iPix].r := pow(rc.FrmBuf[iPix].r, rc.options.gamma);
			rc.FrmBuf[iPix].g := pow(rc.FrmBuf[iPix].g, rc.options.gamma);
			rc.FrmBuf[iPix].b := pow(rc.FrmBuf[iPix].b, rc.options.gamma)
		END
	END;
	
	(* //output statistics in XML *)

	(* // free memory
	free(td);
	free(threads); *)
END Render;

PROCEDURE SaveToFile(pix: frameBuffer_t; w: LONGINT; h: LONGINT; CONST dspyName: ARRAY OF CHAR);
VAR
	fileName: ARRAY MAXBUFFER OF CHAR;
	file: Files.File;
	stream: Files.Writer;
	r, g, b: CHAR;
	p: lesson1.Color;
	i, j: LONGINT;
BEGIN
	Strings.Concat(dspyName, ".ppm", fileName);
	file := Files.New(fileName);
	IF file # NIL THEN
		Files.OpenWriter(stream, file, 0);
		stream.String("P6"); stream.Char(0DX);
		stream.Int(w, 0); stream.String(" "); stream.Int(h, 0); stream.Char(0DX);
		stream.Int(255, 0); stream.Char(0DX);
		FOR j := 0 TO h - 1 DO
			FOR i := 0 TO w - 1 DO
				p := pix[j * w + i];
				(* // clamp and quantize *)
				r := CHR(floor(clamp(p.r, 0, 1) * 255 + 0.5));
				g := CHR(floor(clamp(p.g, 0, 1) * 255 + 0.5));
				b := CHR(floor(clamp(p.b, 0, 1) * 255 + 0.5));
				stream.Char(r);
				stream.Char(g);
				stream.Char(b)
			END
		END;
		stream.Update;
		Files.Register(file)
	ELSE
		context.out.String("can't open ");
		context.out.String(fileName);
		context.out.Ln
	END
END SaveToFile;

(*
//------------------------------------------------------------------------------
// RI API
// Check the RenderMan Interface specification PDF file for more information
//------------------------------------------------------------------------------
*)

PROCEDURE RiBegin(): RenderContext;
BEGIN
	(* rc = (RenderContext* )malloc(sizeof(RenderContext)); *)
	NEW(rc);
	rc.options.imageWidth := 640;
	rc.options.imageHeight := 480;
	rc.options.cropWindow.xmin := 0;
	rc.options.cropWindow.ymin := 0;
	rc.options.cropWindow.xmax := 1;
	rc.options.cropWindow.ymax := 1;
	rc.options.fieldOfView := 90;
	rc.options.gamma := 1.0;
	(* char defaultDspyName[MAXBUFFER] = "untitled";
	strcpy((char* )options.displayName, defaultDspyName); *)
	COPY("untitled", rc.options.displayName);
	(* memset(&options.backgroundColor, 0x0, sizeof(color_t)); *)
	rc.options.backgroundColor.r := 0.0;
	rc.options.backgroundColor.g := 0.0;
	rc.options.backgroundColor.b := 0.0;
	RETURN rc;
END RiBegin;

PROCEDURE RiEnd;
BEGIN
	(* free((options_t* )rc->options);
	free(rc); *)
END RiEnd;

PROCEDURE RiWorldBegin(rc: RenderContext);
VAR
	tmp: REAL;
BEGIN
	(* // check if crop window coordinates are valid *)
	IF rc.options.cropWindow.xmin > rc.options.cropWindow.xmax THEN
		tmp := rc.options.cropWindow.xmin;
		rc.options.cropWindow.xmin := rc.options.cropWindow.xmax;
		rc.options.cropWindow.xmax := tmp
	END;
	IF rc.options.cropWindow.ymin > rc.options.cropWindow.ymax THEN
		tmp := rc.options.cropWindow.ymin;
		rc.options.cropWindow.ymin := rc.options.cropWindow.ymax;
		rc.options.cropWindow.ymax := tmp
	END;
	rc.options.cropWindow.xmin := MIN(1, MAX(0, rc.options.cropWindow.xmin));
	rc.options.cropWindow.ymin := MIN(1, MAX(0, rc.options.cropWindow.ymin));
	rc.options.cropWindow.xmax := MIN(1, MAX(0, rc.options.cropWindow.xmax));
	rc.options.cropWindow.ymax := MIN(1, MAX(0, rc.options.cropWindow.ymax));
END RiWorldBegin;

PROCEDURE RiWorldEnd(rc: RenderContext);
BEGIN
	(* // allocate memory for the frameBuffer *)
	NEW(rc.FrmBuf, rc.options.imageWidth * rc.options.imageHeight);
	Render(rc);
	SaveToFile(rc.FrmBuf, rc.options.imageWidth, rc.options.imageHeight,
		rc.options.displayName);
	(* free(rc.frameBuffer); <-- not needed*)
END RiWorldEnd;

PROCEDURE Main*(c: Commands.Context);
BEGIN
	IF rc = NIL THEN
		context := c;
		rc := RiBegin();
		RiWorldBegin(rc);
		RiWorldEnd(rc);
		RiEnd;
	END;
END Main;

BEGIN
	rc := NIL;
END lesson1bench.

lesson1bench.Main ~

SystemTools.Free lesson1bench lesson1 ~

Pentium(R) Dual-Core CPU T4200 @ 2.00 GHz:



Intel Core i5 650 @ 3.20 GHz (2 cores, 4 threads):

nThreadsTotal: 1, bucket size: 320 x 240, nBucketsTotal: 4, time elapsed:   0.9028
nThreadComputedBuckets: [4]
nSecondaryRays: [45108]
nThreadsTotal: 2, bucket size: 160 x 120, nBucketsTotal: 16, time elapsed:   0.4900
nThreadComputedBuckets: [8, 8]
nSecondaryRays: [32980, 29548]
nThreadsTotal: 4, bucket size: 80 x 60, nBucketsTotal: 64, time elapsed:   0.3715
nThreadComputedBuckets: [17, 20, 15, 12]
nSecondaryRays: [23652, 29636, 24656, 18920]
nThreadsTotal: 8, bucket size: 40 x 30, nBucketsTotal: 256, time elapsed:   0.4103
nThreadComputedBuckets: [55, 45, 48, 63, 8, 7, 14, 16]
nSecondaryRays: [35632, 29884, 30524, 39144, 4956, 4720, 9544, 9520]
nThreadsTotal: 16, bucket size: 20 x 15, nBucketsTotal: 1024, time elapsed:   0.4822
nThreadComputedBuckets: [95, 203, 155, 11, 46, 139, 39, 37, 99, 31, 33, 32, 0, 32, 40, 32]
nSecondaryRays: [29996, 57096, 43752, 3604, 12264, 39892, 11228, 10992, 27296, 8408, 8964, 8672, 0, 9408, 11044, 9516]
