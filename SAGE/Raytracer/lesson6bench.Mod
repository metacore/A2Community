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

MODULE lesson6bench;

IMPORT
	Math, Events, Strings, Files, Commands, PreciseTimer,
	lesson1;

CONST

	DEBUGLOG = FALSE;
	
	TESTS = 50;

	EventClass = 3;
	EventSubclass = 3;
	
	moduleName = "Test";

	MAXBUFFER = 256;
	EPSILON = 0.000001;
	TEST_CULL = TRUE;

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
		frameBuffer: frameBuffer_t;
		screenWindow: screenWindow_t;
		(* // to compute prim ray_t direction *)
		dx, dy: REAL;
		angle: REAL;
	END;

	ThreadData = POINTER TO RECORD
		id: LONGINT;
		rc: RenderContext;
		nThreadComputedBuckets: LONGINT;
	END;

	Bucket = RECORD
		x0, y0, x1, y1: LONGINT;
	END;

	CalcThread = OBJECT
	VAR
		td: ThreadData;
		bi, by, bx: LONGINT;
		b: Bucket;
		str1, str2: ARRAY 64 OF CHAR;

	PROCEDURE &New(td: ThreadData);
	BEGIN
		SELF.td := td;
		IncActiveThreads(td.rc);
	END New;

	BEGIN {ACTIVE}
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
			
			renderBucket(td.rc, b)
		END;
		DecActiveThreads(td.rc);
	END CalcThread;

VAR
	context: Commands.Context;
	rc: RenderContext;
	tri: ARRAY 3 OF lesson1.Vector;
	col: ARRAY 3 OF lesson1.Color;
	
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

PROCEDURE vecNormalize(VAR v: lesson1.Vector);
VAR
	len, lenInv: REAL;
BEGIN
	len := v.x * v.x + v.y * v.y + v.z * v.z;
	IF len > 0.0 THEN
		lenInv := 1.0 / Math.sqrt(len);
		v.x := v.x * lenInv;
		v.y := v.y * lenInv;
		v.z := v.z * lenInv;
		(*
		KernelLog.Enter;
		KernelLog.Ln;
		LogFloat(v.x);
		LogFloat(v.y);
		LogFloat(v.z);
		KernelLog.Ln;
		KernelLog.Exit;
		*)
	END;

END vecNormalize;

PROCEDURE vecSub(VAR c: lesson1.Vector; CONST a: lesson1.Vector; CONST b: lesson1.Vector);
BEGIN
	c.x := a.x - b.x;
	c.y := a.y - b.y;
	c.z := a.z - b.z
END vecSub;

PROCEDURE vecCross(VAR c: lesson1.Vector; CONST a: lesson1.Vector; CONST b: lesson1.Vector);
BEGIN
	c.x := a.y * b.z - a.z * b.y;
	c.y := a.z * b.x - a.x * b.z;
	c.z := a.x * b.y - a.y * b.x
END vecCross;

PROCEDURE vecDot(VAR c: REAL; CONST a: lesson1.Vector; CONST b: lesson1.Vector);
BEGIN
	c := a.x*b.x + a.y*b.y + a.z*b.z
END vecDot;

PROCEDURE intersectTriangle(CONST va: lesson1.Vector; CONST vb: lesson1.Vector; CONST vc: lesson1.Vector; CONST rayOrig: lesson1.Vector; CONST rayDir: lesson1.Vector; VAR t, u, v: REAL): BOOLEAN;
VAR
	e1, e2, pvec, tvec, qvec: lesson1.Vector;
	det, inv_det: REAL;
BEGIN
	(* // implementation of the Moller-Trumbore algorithm *)
	vecSub(e1, vb, va);
	vecSub(e2, vc, va);
	
	vecCross(pvec, rayDir, e2);
	vecDot(det, e1, pvec);
	
	IF TEST_CULL THEN
		IF det < EPSILON THEN
			RETURN FALSE
		END
	ELSE
		IF (det > -EPSILON) & (det < EPSILON) THEN
			RETURN FALSE
		END
	END;
	
	(* // prepare to compute u *)
	vecSub(tvec, rayOrig, va);
	
	(* // do not mult by inv_det *)
	vecDot(u, tvec, pvec);
	
	IF (u < 0.0) OR (u > det) THEN (* // test bounds using det *)
		RETURN FALSE
	END;
	
	(* // prepare to compute v *)
	vecCross(qvec, tvec, e1);
	
	(* // do not mult by inv_det *)
	vecDot(v, rayDir, qvec);

	IF (v < 0) OR (v > det) OR (u + v > det) THEN (* // test bounds using det *)
		RETURN FALSE
	END;
	
	(* // ray intersects triangle, compute t and *normalize* u and v *)
	inv_det := 1.0 / det;
	
	vecDot(t, e1, qvec);
	
	t := t * inv_det;
	u := u * inv_det;
	v := v * inv_det;
	
	RETURN TRUE

END intersectTriangle;

PROCEDURE renderBucket(rc: RenderContext; CONST b: Bucket);
VAR
	i, j, nPix: LONGINT;
	t, u, v, w: REAL;
	ray: lesson1.Ray; (* // prim ray *)
BEGIN
	FOR j := b.y0 TO b.y1 DO
		FOR i := b.x0 TO b.x1 DO
			nPix := j * rc.options.imageWidth + i;
			ray.origin.x := 0.0;
			ray.origin.y := 0.0;
			ray.origin.z := 0.0;
			rc.frameBuffer[nPix] := rc.options.backgroundColor;
			ray.direction.x := ((i + 0.5) * rc.dx + rc.screenWindow.left) * rc.angle;
			ray.direction.y := (-(j + 0.5) * rc.dy + rc.screenWindow.top) * rc.angle;
			ray.direction.z := 1;
			vecNormalize(ray.direction); 
			IF intersectTriangle(tri[0], tri[1], tri[2], ray.origin, ray.direction, t, u, v) THEN
				(* // uncomment the following line to vizualize the barycentric coord. *)
				rc.frameBuffer[nPix].r := u;
				rc.frameBuffer[nPix].g := v;
				rc.frameBuffer[nPix].b := 0.0;
				(* // interpolate vertex color using barycentric coordinates *)
				w := 1 - u - v;
				rc.frameBuffer[nPix].r := w * col[0].r + u * col[1].r + v * col[2].r;
				rc.frameBuffer[nPix].g := w * col[0].g + u * col[1].g + v * col[2].g;
				rc.frameBuffer[nPix].b := w * col[0].b + u * col[1].b + v * col[2].b
			END
		END
	END
END renderBucket;

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
		
		rc.nThreadsTotal := rc.nThreadsTotal * 2; 
		
	END;

	(* KernelLog.String("Threads terminated"); KernelLog.Ln; *)

	(* //gamma correction *)
	IF rc.options.gamma # 1 THEN
		FOR iPix := 0 TO w * h - 1 DO
			rc.frameBuffer[iPix].r := pow(rc.frameBuffer[iPix].r, rc.options.gamma);
			rc.frameBuffer[iPix].g := pow(rc.frameBuffer[iPix].g, rc.options.gamma);
			rc.frameBuffer[iPix].b := pow(rc.frameBuffer[iPix].b, rc.options.gamma)
		END
	END;
	
	(* //output statistics in XML *)

	(* // free memory
	free(td);
	free(threads); *)
END Render;

PROCEDURE saveToFile(pix: frameBuffer_t; w: LONGINT; h: LONGINT; CONST dspyName: ARRAY OF CHAR);
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
END saveToFile;

(*
//------------------------------------------------------------------------------
// RI API
// Check the RenderMan Interface specification PDF file for more information
//------------------------------------------------------------------------------
*)

PROCEDURE RiBegin(): RenderContext;
VAR
	rc: RenderContext;
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
	rc.options.gamma := 1;
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
	NEW(rc.frameBuffer, rc.options.imageWidth * rc.options.imageHeight);
	Render(rc);
	saveToFile(rc.frameBuffer, rc.options.imageWidth, rc.options.imageHeight,
		rc.options.displayName);
	(* free(rc.frameBuffer); <-- not needed*)
END RiWorldEnd;

PROCEDURE Init;
BEGIN
	tri[0].x := -3.0; tri[0].y := -3.0; tri[0].z := 5.0;
	tri[1].x := 0.0; tri[1].y := 3.0; tri[1].z := 5.0;
	tri[2].x := 3.0; tri[2].y := -3.0; tri[2].z := 5.0;
	col[0].r := 1.0; col[0].g := 0.0; col[0].b := 0.0;
	col[1].r := 0.0; col[1].g := 1.0; col[1].b := 0.0;
	col[2].r := 0.0; col[2].g := 0.0; col[2].b := 1.0
END Init;

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
	Init
END lesson6bench.

lesson6bench.Main ~

SystemTools.Free lesson6bench lesson1 ~

Pentium(R) Dual-Core CPU T4200 @ 2.00 GHz:

nThreadsTotal: 1, bucket size: 320 x 240, nBucketsTotal: 4, time elapsed:   0.0672
nThreadComputedBuckets: [4]
nThreadsTotal: 2, bucket size: 160 x 120, nBucketsTotal: 16, time elapsed:   0.0335
nThreadComputedBuckets: [8, 8]
nThreadsTotal: 4, bucket size: 80 x 60, nBucketsTotal: 64, time elapsed:   0.0340
nThreadComputedBuckets: [0, 32, 32, 0]
nThreadsTotal: 8, bucket size: 40 x 30, nBucketsTotal: 256, time elapsed:   0.0344
nThreadComputedBuckets: [129, 80, 47, 0, 0, 0, 0, 0]
nThreadsTotal: 16, bucket size: 20 x 15, nBucketsTotal: 1024, time elapsed:   0.0364
nThreadComputedBuckets: [511, 0, 0, 513, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
