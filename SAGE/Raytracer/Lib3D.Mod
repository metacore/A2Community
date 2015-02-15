(**
	3D library by Yaroslav Romanchenko (SAGE), 2015
*)

MODULE Lib3D;

IMPORT

	Math;

CONST

	MAXBUFFER* = 256;

	(* Material types *)
	MATTE* = 1;
	DIFFUSE* = 2;
	GLASS* = 3;

	INFINITY = 1.0E6;
	EPSILON = 1.0E-6;
	
	X = 0;
	Y = 1;
	Z = 2;
	
	R = 0;
	G = 1;
	B = 2;
	
	px00 = 0;
	px10 = 1;
	px01 = 2;
	px11 = 3;
	
	TEST_CULL = TRUE;
	
TYPE

	(**
		Base type that may represent
		a point (x,y,z), a vector (x,y,z),
		a color (r,g,b)
		or any set of 4 values
		for that vector operations should
		be applied.
		From this point of view 4th member
		involved in all operations also.
	*)
	Vector* = ARRAY 4 OF REAL;
	
	(**
		Ray of light with origin point
		and direction
	*)
	Ray* = RECORD
		pt*, vn*: Vector
	END;
	
	(**
		Hit structure that holds full information
		about hit: distance, point and normal
	*)
	Hit = RECORD
		dist: REAL;
		pt, vn: Vector;
	END;

	Object = OBJECT
	VAR
		center: Vector;
		radius, radius2: REAL;
		color: Vector;
		materialType: INTEGER;
		isLight: BOOLEAN;
		indexOfRefraction: REAL;

		intersect: IntersectFunction;
		
	PROCEDURE &New(center: Vector; radius: REAL; color: Vector; iMatType: INTEGER; bLight: BOOLEAN);
	BEGIN
		SELF.center := center;
		SELF.radius := radius;
		radius2 := radius * radius;
		SELF.color := color;
		SELF.materialType := iMatType;
		isLight := bLight;
		indexOfRefraction := 1.3;
		intersect := IntersectObject;
	END New;
	
	END Object;
	
	Objects = POINTER TO ARRAY OF Object;
	
	(*
	Cone = OBJECT(Object)
	VAR
		height: REAL;

	PROCEDURE &New(pt: Vector; radius: REAL; color: Vector; iMatType: INTEGER; bLight: BOOLEAN);
	BEGIN
		New^(pt, radius, color, iMatType, bLight);
		intersect := IntersectHandler;
	END New;

	PROCEDURE IntersectHandler(object: Object; CONST ray: Ray; VAR t: REAL): BOOLEAN;
	BEGIN
		RETURN IntersectCone(ray.pt, ray.vn,
			object.center, object.radius, object(Cone).height, t)
	END IntersectHandler;
	
	END Cone;
	
	Cylinder = OBJECT(Object)
	VAR
		zmin, zmax: REAL;
		
	PROCEDURE &New(pt: Vector; radius: REAL; color: Vector; iMatType: INTEGER; bLight: BOOLEAN);
	BEGIN
		New^(pt, radius, color, iMatType, bLight);
		intersect := IntersectHandler;
	END New;

	PROCEDURE IntersectHandler(object: Object; CONST ray: Ray; VAR t: REAL): BOOLEAN;
	BEGIN
		RETURN IntersectCylinder(ray.pt, ray.vn,
			object.center, object.radius, object(Cylinder).zmin, object(Cylinder).zmax, t)
	END IntersectHandler;
	
	END Cylinder;
	*)
	
	Disk = OBJECT(Object)
	VAR
		vn: Vector;
		
	PROCEDURE &New(center: Vector; radius: REAL; color: Vector; iMatType: INTEGER; bLight: BOOLEAN);
	BEGIN
		New^(center, radius, color, iMatType, bLight);
		intersect := IntersectHandler;
	END New;

	PROCEDURE IntersectHandler(object: Object; CONST ray: Ray; VAR hit: Hit): BOOLEAN;
	BEGIN
		RETURN IntersectDisk(ray.pt, ray.vn,
			object.center, object(Disk).vn, object.radius, hit)
	END IntersectHandler;
	
	END Disk;
	
	(*
	Sphere = OBJECT(Object)
	
	PROCEDURE &New(pt: Vector; radius: REAL; color: Vector; iMatType: INTEGER; bLight: BOOLEAN);
	BEGIN
		New^(pt, radius, color, iMatType, bLight);
		intersect := IntersectHandler;
	END New;

	PROCEDURE IntersectHandler(object: Object; CONST ray: Ray; VAR t: REAL): BOOLEAN;
	BEGIN
		RETURN IntersectSphere(ray.pt, ray.vn,
			object.center, object.radius, t)
	END IntersectHandler;
	
	END Sphere;
	*)
	
	(**
		Light source
	*)
	Light = RECORD
		object*: Object
	END;
	
	CropWindow* = RECORD
		xmin*, ymin*, xmax*, ymax*: REAL;
	END;
	
	Options* = RECORD
		(* camera options *)
		imageWidth*: LONGINT;
		imageHeight*: LONGINT;
		frameAspectRatio*: REAL;
		bucketSizeX*, bucketSizeY*: LONGINT;
		cropWindow*: CropWindow;
		fieldOfView*: REAL;
		nTracingDepth*: LONGINT; (* Depth of tracing *)
		(* Antialiasing options *)
		fAAThreshold*: REAL; (* Color distance threshold *)
		nAALevels*: LONGINT; (* Antialiasing levels *)
		bShowAAPixels*: BOOLEAN;
		(* display options *)
		displayName*: ARRAY MAXBUFFER OF CHAR;
		gamma*: REAL;
	END;
	
	ScreenWindow* = RECORD
		left*, right*, top*, bottom*: REAL;
	END;

	FrameBuffer* = POINTER TO ARRAY OF Vector;

	TraceFunction* = PROCEDURE {DELEGATE}
		(rc: RenderContext; ray: Ray; depth: LONGINT): Vector;
	IntersectFunction* = PROCEDURE {DELEGATE}
		(object: Object; CONST ray: Ray; VAR hit: Hit): BOOLEAN;

	RenderContext* = POINTER TO RECORD
		options*: Options;
		(* multi-threading related *)
		nBucketsX*, nBucketsY*: LONGINT;
		nComputedBuckets*, nBucketsTotal*: LONGINT;
		nActiveThreads*, nThreadsTotal*: LONGINT;
		(* frame buffer *)
		FrmBuf*: FrameBuffer;
		screenWindow*: ScreenWindow;
		(* to compute prim ray_t direction *)
		dx*, dy*: REAL;
		angle*: REAL;
		(* world *)
		nObjects*: LONGINT;
		objects*: Objects;
		light*: Light;
		clBackground*: Vector;
		funcTrace*: TraceFunction;
	END;

	Bucket* = RECORD
		x0*, y0*, x1*, y1*: LONGINT;
		nSecondaryRays*: LONGINT;
		(* Line pixel buffers for antialising purposes
		  They will be initated once per computing thread *)
		FrmLineCur*, FrmLinePrev*: FrameBuffer;
	END;

VAR
	ZeroVector-: Vector;

(** Vector operations *)

(** Vector constructor *)
PROCEDURE vector(x, y, z, dummy = 0 : REAL): Vector;
VAR
	v: Vector;
BEGIN
	v[0] := x;
	v[1] := y;
	v[2] := z;
	v[3] := dummy;
	RETURN v
END vector;

(** Vector length
	length := Math.sqrt(v[0] * v[0] + v[1] * v[1] + v[2] * v[2] + v[3] * v[3])
*)
PROCEDURE length(CONST v: Vector): REAL;
BEGIN
	RETURN Math.sqrt(v[0] * v[0] + v[1] * v[1] + v[2] * v[2] + v[3] * v[3]);
END length;

(** Vector normalization
	fLen2 := v[0] * v[0] + v[1] * v[1] + v[2] * v[2] + v[3] * v[3];
	IF fLen2 > 0 THEN
		fInvSqrt := 1 / Math.sqrt(fLen2);
		v[0] := v[0] * fInvSqrt;
		v[1] := v[1] * fInvSqrt;
		v[2] := v[2] * fInvSqrt;
		v[3] := v[3] * fInvSqrt
	END
*)
PROCEDURE normalize*(VAR v: Vector);
VAR
	fLen2, fInvSqrt: REAL;
BEGIN
	fLen2 := v[0] * v[0] + v[1] * v[1] + v[2] * v[2] + v[3] * v[3];
	IF fLen2 > 0 THEN
		fInvSqrt := 1 / Math.sqrt(fLen2);
		v[0] := v[0] * fInvSqrt;
		v[1] := v[1] * fInvSqrt;
		v[2] := v[2] * fInvSqrt;
		v[3] := v[3] * fInvSqrt
	END
END normalize;

(** Vector dot product
	fDot := v1[0] * v2[0] + v1[1] * v2[1] + v1[2] * v2[2] + v1[3] * v2[3]
*)
PROCEDURE "+*"(CONST v1, v2: Vector): REAL;
BEGIN
	RETURN v1[0] * v2[0] + v1[1] * v2[1] + v1[2] * v2[2] + v1[3] * v2[3]
END "+*";

(** Vector cross product
	v3[0] := v1[1] * v2[2] - v1[2] * v2[1];
	v3[1] := v1[2] * v2[0] - v1[0] * v2[2];
	v3[2] := v1[0] * v2[1] - v1[1] * v2[0]
*)
PROCEDURE cross(VAR v3: Vector; CONST v1, v2: Vector);
BEGIN
	v3[0] := v1[1] * v2[2] - v1[2] * v2[1];
	v3[1] := v1[2] * v2[0] - v1[0] * v2[2];
	v3[2] := v1[0] * v2[1] - v1[1] * v2[0]
END cross;

(** Vector multipliation with scalar *)
PROCEDURE "*"(CONST v: Vector; f: REAL): Vector;
BEGIN
	RETURN vector(v[0] * f, v[1] * f, v[2] * f, v[3] * f)
END "*";
PROCEDURE "*"(f: REAL; CONST v: Vector): Vector;
BEGIN
	RETURN vector(v[0] * f, v[1] * f, v[2] * f, v[3] * f)
END "*";

(** Vector division by scalar *)
PROCEDURE "/"(CONST v: Vector; f: REAL): Vector;
BEGIN
	RETURN vector(v[X] / f, v[Y] / f, v[Z] / f, v[3] / f)
END "/";

(** Vector multiplication
	v3 := vector(v1[0] * v2[0], v1[1] * v2[1], v1[2] * v2[2], v1[3] * v2[3])
*)
PROCEDURE "*"(CONST v1, v2: Vector): Vector;
BEGIN
	RETURN vector(v1[0] * v2[0], v1[1] * v2[1], v1[2] * v2[2], v1[3] * v2[3])
END "*";

(** Vector substraction
	v3 := vector(v1[0] - v2[0], v1[1] - v2[1], v1[2] - v2[2], v1[3] - v2[3])
*)
PROCEDURE "-"(CONST v1, v2: Vector): Vector;
BEGIN
	RETURN vector(v1[0] - v2[0], v1[1] - v2[1], v1[2] - v2[2], v1[3] - v2[3])
END "-";

(** Vector addition
	v3 := vector(v1[0] + v2[0], v1[1] + v2[1], v1[2] + v2[2], v1[3] + v2[3])
*)
PROCEDURE "+"(CONST v1, v2: Vector): Vector;
BEGIN
	RETURN vector(v1[0] + v2[0], v1[1] + v2[1], v1[2] + v2[2], v1[3] + v2[3])
END "+";

(** Vector negation *)
PROCEDURE "-"(VAR v: Vector): Vector;
BEGIN
	RETURN vector(-v[0], -v[1], -v[2], -v[3])
END "-";

(** Point to point distance
	v := p1 - p2;
	dist := Math.sqrt(v +* v)
*)
PROCEDURE dist*(CONST p1, p2: Vector): REAL;
VAR
	v: Vector;
BEGIN
	v := p1 - p2;
	RETURN Math.sqrt(v +* v)
END dist;

(** Color clamp *)
PROCEDURE clamp*(VAR c: Vector);
BEGIN
	IF c[R] > 1.0 THEN
		c[R] := 1.0
	END;
	IF c[G] > 1.0 THEN  
		c[G] := 1.0
	END;
	IF c[B] > 1.0 THEN  
		c[B] := 1.0
	END
END clamp;

PROCEDURE ComputePrimaryRay*(rc: RenderContext; i, j: LONGINT; VAR ray: Ray);
VAR
	f: REAL;
	angle: REAL;
	dx: REAL;
	dy: REAL; 
BEGIN
	f := rc.options.fieldOfView * 0.5 * Math.pi / 180.0;
	angle := Math.sin(f) / Math.cos(f);
	ray.pt := ZeroVector;
	dx := 2 * rc.options.frameAspectRatio / rc.options.imageWidth;
	dy := 2 / rc.options.imageHeight;
	ray.vn := vector(angle * ((i + 0.5) * dx - rc.options.frameAspectRatio),
		angle * (-(j + 0.5) * dy + 1), 1);
	normalize(ray.vn)
END ComputePrimaryRay;

PROCEDURE ComputeSecondaryRays*(rc: RenderContext;
	i, j, fDelta: REAL; VAR ray00, ray10, ray01, ray11: Ray);
VAR
	f: REAL;
	angle: REAL;
	dx: REAL;
	dy: REAL;
BEGIN
	f := rc.options.fieldOfView * 0.5 * Math.pi / 180.0;
	angle := Math.sin(f) / Math.cos(f);
	ray00.pt := ZeroVector;
	ray10.pt := ZeroVector;
	ray01.pt := ZeroVector;
	ray11.pt := ZeroVector;
	dx := 2 * rc.options.frameAspectRatio / rc.options.imageWidth;
	dy := 2 / rc.options.imageHeight;
	
	ray00.vn := vector(angle * ((i - fDelta) * dx - rc.options.frameAspectRatio),
		angle * (-(j - fDelta) * dy + 1), 1);
	ray10.vn := vector(angle * ((i + fDelta) * dx - rc.options.frameAspectRatio),
	  angle * (-(j - fDelta) * dy + 1), 1);
	ray01.vn := vector(angle * ((i - fDelta) * dx - rc.options.frameAspectRatio),
	  angle * (-(j + fDelta) * dy + 1), 1);
	ray11.vn := vector(angle * ((i + fDelta) * dx - rc.options.frameAspectRatio),
	  angle * (-(j + fDelta) * dy + 1), 1);

	normalize(ray00.vn);
	normalize(ray10.vn);
	normalize(ray01.vn);
	normalize(ray11.vn)
END ComputeSecondaryRays;

PROCEDURE IntersectObject(object: Object; CONST ray: Ray; VAR hit: Hit): BOOLEAN;
VAR
	oc: Vector;
	oc2, tca, d2, thc: REAL;
	outside: BOOLEAN;
BEGIN
	(* use geometric method *)
	oc := object.center - ray.pt;
	(* square distance to center of sphere *)
	oc2 := oc +* oc;

	(* distance to point on ray closest to sphere center *)
	tca := oc +* ray.vn;
	
	outside := (oc2 > object.radius2);
	IF (tca < 0) & outside THEN  
		RETURN FALSE
	END;
	
	(* square distance from sphere center to closest point on ray *)
	d2 := oc2 - tca * tca; 
	(* square distance from perpendicular bisector to center *)
	thc := object.radius2 - d2; 
	
	IF thc < 0 THEN 
		RETURN FALSE
	END;
	IF outside THEN 
		hit.dist := tca - Math.sqrt(thc)
	ELSE
		hit.dist := tca + Math.sqrt(thc)
	END;
	
	IF hit.dist <= 0 THEN  
		RETURN FALSE
	END;
	
	hit.pt := ray.pt + ray.vn * hit.dist;
	hit.vn := hit.pt - object.center;
	normalize(hit.vn);
	
	RETURN TRUE
END IntersectObject;

PROCEDURE IntersectTriangle*(CONST va, vb, vc: Vector; rayOrig, rayDir: Vector; VAR t, u, v: REAL): BOOLEAN;
VAR
	v0_to_v1, v0_to_v2, n, v0_to_p, ab_x_ap, v1_to_v2, v1_to_p, bc_x_bp, v2_to_p, ca_x_cp: Vector;
	nd, d, v_num, u_num, denom: REAL;
	p: Vector;
BEGIN
	(* compute triangle's normal *)
	v0_to_v1 := vb - va;
	v0_to_v2 := vc - va;
	(* doesn't need to normalized *)
	cross(n, v0_to_v1, v0_to_v2);

	(*
		step 1: find P
	*)

	(* if ray and plane are parallel, they don't intersect ! *)
	nd := n +* rayDir;
	IF nd = 0.0 THEN
		RETURN FALSE
	END;

	d := n +* va;
	t := (d - (n +* rayOrig)) / nd;
	IF t < 0.0 THEN
		RETURN FALSE (* triangle is behind the ray, return *)
	END;

	p[0] := rayOrig[0] + t * rayDir[0];
	p[1] := rayOrig[1] + t * rayDir[1];
	p[2] := rayOrig[2] + t * rayDir[2];

	(*
		step 2: inside-outside test
	*)

	(* edge 1 *)

	v0_to_p := p - va;
	cross(ab_x_ap, v0_to_v1, v0_to_p);
	v_num := n +* ab_x_ap;
	IF v_num < 0.0 THEN
		RETURN FALSE
	END;

	(* // edge 2 *)

	v1_to_v2 := vc - vb;
	v1_to_p := p - vb;
	cross(bc_x_bp, v1_to_v2, v1_to_p);
	IF n +* bc_x_bp < 0 THEN
		RETURN FALSE
	END;

	(* // edge 3 *)

	v2_to_p := p - vc;
	(* // reuse v0_to_v2 instead of computing v2_to_v0 but then inverse the order
	// in the cross product.
	// ca_x_cp=v0_to_v2 x v2_to_p ==>
	// ca_x_cp=v2_to_p  x v0_to_v2 *)
	cross(ca_x_cp, v2_to_p, v0_to_v2);
	u_num := n +* ca_x_cp;
	IF u_num < 0 THEN
		RETURN FALSE
	END;

	(* compute barycentric coordinates *)
	denom := n +* n;
	u := u_num / denom;
	v := v_num / denom;

	RETURN TRUE

END IntersectTriangle;

(* Implementation of the Moller-Trumbore algorithm *)
PROCEDURE IntersectTriangleMollerTrumbore*(CONST ptA, ptB, ptC, ptRay, vnRay: Vector; VAR t, u, v: REAL): BOOLEAN;
VAR
	vE1, vE2: Vector; (* Triangle edges *)
	vP, vT, vQ: Vector;
	fDet, fInvDet: REAL;
BEGIN
	
	vE1 := ptB - ptA;
	vE2 := ptC - ptA;
	
	cross(vP, vnRay, vE2);
	fDet := vE1 +* vP;
	
	IF TEST_CULL THEN
		IF fDet < EPSILON THEN
			RETURN FALSE
		END
	ELSE
		IF (fDet > -EPSILON) & (fDet < EPSILON) THEN
			RETURN FALSE
		END
	END;
	
	(* prepare to compute u *)
	vT := ptRay - ptA;
	
	(* do not mult by fInvDet *)
	u := vT +* vP;
	
	IF (u < 0) OR (u > fDet) THEN (* test bounds using fDet *)
		RETURN FALSE
	END;
	
	(* prepare to compute v *)
	cross(vQ, vT, vE1);
	
	(* do not mult by inv_det *)
	v := vnRay +* vQ;

	IF (v < 0) OR (v > fDet) OR (u + v > fDet) THEN (* test bounds using fDet *)
		RETURN FALSE
	END;
	
	(* ray intersects triangle, compute t and normalize u and v *)
	fInvDet := 1.0 / fDet;
	
	t := vE1 +* vQ;
	
	t := t * fInvDet;
	u := u * fInvDet;
	v := v * fInvDet;
	
	RETURN TRUE

END IntersectTriangleMollerTrumbore;

(*
(**
	Find roots of a quadratic equation. For floating point computation, this
	algorithm is more robust than the usual quadratic formula.
	Inputs:
		float a, b, c: quadratic equation coefficients
	Outputs:
		float r0, r1: solutions (roots) to the quadratic equation
	Return:
		TRUE if the discriminant is positive, FALSE otherwise
*)
PROCEDURE SolveQuadratic(a, b, c: REAL; VAR r0, r1: REAL): BOOLEAN;
VAR
	fDiscrim, q, f: REAL;
BEGIN
	(* Compute discriminant *)
	fDiscrim := b * b - 4.0 * a * c;
	IF fDiscrim < 0 THEN
		(* No real roots, return *)
		RETURN FALSE
	END;
	(* use the quadratic formula to find t0 and t1 *)
	IF b < 0 THEN
		q := -0.5 * (b - Math.sqrt(fDiscrim))
	ELSE
		q := -0.5 * (b + Math.sqrt(fDiscrim))
	END;
	r0 := q / a;
	r1 := c / q;
	IF r0 > r1 THEN (* swap *)
		f := r0;
		r0 := r1;
		r1 := f
	END;
	RETURN TRUE
END SolveQuadratic;

(**
	Compute ray-cone intersection (algebraic method)
*)
PROCEDURE IntersectCone(CONST ptRay, vnRay, pt: Vector; radius, height: REAL; VAR t: REAL): BOOLEAN;
VAR
	a, b, c, k, pz, t0, t1: REAL;
	o: Vector;
BEGIN
	
	(* Compute quadratic cone coefficients *)
	k := radius / height;
	k := k * k;
	a := vnRay[0] * vnRay[0] + vnRay[1] * vnRay[1] - k * vnRay[2] * vnRay[2];
	b := 2 * (vnRay[0] * ptRay[0] + vnRay[1] * ptRay[1] - k * vnRay[2] * (ptRay[2] - height));
	c := ptRay[0] * ptRay[0] + ptRay[1] * ptRay[1] - k * (ptRay[2] - height) * (ptRay[2] - height);

	IF ~SolveQuadratic(a, b, c, t0, t1) THEN
		RETURN FALSE
	END;
	t := t0;
	IF t0 < 0 THEN
		t := t1
	END;
	(* compute p.z *)
	o := ptRay - pt;
	pz := o[2] + t * vnRay[2];
	RETURN (pz >= 0) & (pz <= height)
END IntersectCone;

(**
	Compute the intersection of ray and a cylinder (algebraic method)
*)
PROCEDURE IntersectCylinder(CONST ptRay, vnRay, pt: Vector; radius, zmin, zmax: REAL; VAR t: REAL): BOOLEAN;
VAR
	a, b, c, pz, t0, t1: REAL;
	o: Vector;
BEGIN
	o := ptRay - pt;
	(* substitute ray parametric equation into eq 1 and compute *)
	a := vnRay[0] * vnRay[0] + vnRay[1] * vnRay[1];
	b := 2 * (vnRay[0] * o[0] + vnRay[1] * o[1]);
	c := o[0] * o[0] + o[1] * o[1] - radius * radius;
	IF ~SolveQuadratic(a, b, c, t0, t1) THEN
		RETURN FALSE
	END;
	t := t0;
	IF t0 < 0 THEN
		t := t1
	END;
	(* compute p.z *)
	pz := o[2] + t * vnRay[2];
	RETURN (pz >= zmin) & (pz <= zmax)
END IntersectCylinder;
*)

(**
	Compute ray-plane intersection
*)
PROCEDURE IntersectPlane(CONST ptRay, vnRay, pt, vn: Vector; VAR hit: Hit): BOOLEAN;
VAR
	denom, d: REAL;
BEGIN
	(* if the ray and the plane are parallel, reject intersection *)
	denom := vnRay +* vn;
	IF ABS(denom) < EPSILON THEN
		RETURN FALSE
	END;
	hit.vn := vn;
	(*IF denom < 0 THEN
		(* Correct normal on both sides *)
		hit.vn := -hit.vn;
		denom := vnRay +* hit.vn;
	END;*)
	(* compute d (we assume the plane normal is a unit vector) *)
	d := hit.vn +* pt;
	(* compute distance *)
	hit.dist := (d - (ptRay +* hit.vn)) / denom;
	IF hit.dist <= 0 THEN
		RETURN FALSE
	END;
	(*
	hit.pt[0] := (ptRay[0] + hit.dist * vnRay[0]) - pt[0];
	hit.pt[1] := (ptRay[1] + hit.dist * vnRay[1]) - pt[1];
	hit.pt[2] := (ptRay[2] + hit.dist * vnRay[2]) - pt[2];
	*)
	hit.pt := ptRay + hit.dist * vnRay;
	RETURN TRUE
END IntersectPlane;

PROCEDURE IntersectDisk(ptRay, vnRay, pt, vn: Vector; radius: REAL; VAR hit: Hit): BOOLEAN;
(*VAR
	dist2, rad2: REAL;*)
BEGIN
	IF IntersectPlane(ptRay, vnRay, pt, vn, hit) THEN
		(*dist2 := hit.pt +* hit.pt;
		rad2 := radius * radius;
		IF rad2 >= dist2 THEN*)
		IF dist(hit.pt, pt) <= radius THEN
			RETURN TRUE
		END
	END;
	RETURN FALSE
END IntersectDisk;

(*
PROCEDURE IntersectSphere(CONST ptRay, vnRay, pt: Vector; radius: REAL; VAR t: REAL): BOOLEAN;
VAR
	a, b, c, t0, t1: REAL;
	o: Vector;
BEGIN
	o := ptRay - pt;
	a := vnRay +* vnRay;
	b := 2 * (o +* vnRay);
	c := (o +* o) - radius * radius;
	IF ~SolveQuadratic(a, b, c, t0, t1) THEN
		RETURN FALSE
	END;
	t := t0;
	IF t0 < 0 THEN
		t := t1
	END;
	RETURN TRUE
END IntersectSphere;
*)

PROCEDURE snell(CONST incidentRay: Vector; CONST surfaceNormal: Vector; n1: REAL; n2: REAL; VAR reflectionDir: Vector; VAR refractionDir: Vector);
VAR
	n1n2: REAL;
	cost1: REAL;
	cost2: REAL;
BEGIN
	n1n2 := n1 / n2;
	
	cost1 := incidentRay +* surfaceNormal;
	
	cost2 := Math.sqrt(1.0 - (n1n2 * n1n2) * (1.0 - cost1 * cost1));
	reflectionDir := incidentRay - surfaceNormal * (2 * cost1);
	refractionDir := incidentRay * n1n2 + surfaceNormal * (cost2 - n1n2 * cost1)
END snell;

PROCEDURE fresnel(etai: REAL; etat: REAL; cosi: REAL; cost: REAL; VAR Kr: REAL);
VAR
	Rp: REAL;
	Rs: REAL;
BEGIN
	Rp := ((etat * cosi) - (etai * cost)) / ((etat * cosi) + (etai * cost)); 
	Rs := ((etai * cosi) - (etat * cost)) / ((etai * cosi) + (etat * cost)); 
	Kr := (Rp * Rp + Rs * Rs) * 0.5; 
END fresnel;

PROCEDURE Trace*(rc: RenderContext; ray: Ray; depth: LONGINT): Vector;
VAR
	bias: REAL;
	object: Object;
	hit, hitMin: Hit;
	k: INTEGER;
	reflectionRay, refractionRay: Ray;
	cosi: REAL;
	cost: REAL;
	Kr: REAL;
	reflectionColor: Vector;
	refractionColor: Vector;
	lightColor: Vector;
	shadowRay: Ray;
	isInShadow: BOOLEAN;
	exit: BOOLEAN;
	len: REAL;
	LdotN: REAL;
BEGIN
	IF depth > rc.options.nTracingDepth THEN 
		RETURN rc.clBackground
	END;
	
	bias := 0.001;
	hitMin.dist := INFINITY; 
	object := NIL;
	k := 0;
	WHILE k < rc.nObjects DO
		IF rc.objects[k].intersect(rc.objects[k], ray, hit) THEN 
			IF hit.dist < hitMin.dist THEN 
				hitMin := hit; 
				object := rc.objects[k]
			END
		END;
		INC(k)
	END;
	IF object = NIL THEN 
		RETURN rc.clBackground 
	END;
	
	IF object.materialType = GLASS THEN 
		(* compute reflection and refraction direction *)
		reflectionRay.pt := hitMin.pt + hitMin.vn * bias;
		refractionRay.pt := hitMin.pt - hitMin.vn * bias;
		snell(ray.vn, -hitMin.vn, 1.0, object.indexOfRefraction,
			reflectionRay.vn, refractionRay.vn); 
		normalize(reflectionRay.vn);
		normalize(refractionRay.vn);
		
		cosi := ray.vn +* (-hitMin.vn); 
		cost := refractionRay.vn +* (-hitMin.vn);
	
		fresnel(1.0, object.indexOfRefraction, cosi, cost, Kr); 
		IF Kr < 0.0 THEN
			Kr := 0.0
		ELSIF Kr > 1.0 THEN 
			Kr := 1.0
		END;
		reflectionColor := Trace(rc, reflectionRay, depth + 1); 
		refractionColor := Trace(rc, refractionRay, depth + 1); 
		RETURN object.color * refractionColor * (1 - Kr) + reflectionColor * Kr
	END;
	
	IF object.materialType = MATTE THEN 
		RETURN object.color
	END;

	isInShadow := FALSE;
	shadowRay.pt := hitMin.pt + hitMin.vn * bias;
	shadowRay.vn := rc.light.object.center - hitMin.pt; 
	len := length(shadowRay.vn); 
	normalize(shadowRay.vn);
 
	LdotN := shadowRay.vn +* hitMin.vn;
	
	IF LdotN < 0 THEN 
		RETURN ZeroVector
	END;
	lightColor := rc.light.object.color; 
	k := 0; exit := FALSE;
	WHILE (k < rc.nObjects) & ~exit DO
		IF ~(rc.objects[k]^.isLight) &
			(rc.objects[k].intersect(rc.objects[k], shadowRay, hitMin))
		THEN 
			IF rc.objects[k].materialType = GLASS THEN
				(* attenuate light color by glass color *)
				lightColor := lightColor * rc.objects[k].color; 
			ELSE
				isInShadow := TRUE; 
			END;
			exit := TRUE
		END;
			INC(k);
	END;
	lightColor := lightColor / (len * len); 
	IF isInShadow THEN
		RETURN ZeroVector
	ELSE
		RETURN object.color * lightColor * LdotN
	END
END Trace;

PROCEDURE Refine*(rc: RenderContext; fX, fY: REAL; nLevel: LONGINT; CONST cFrmBuf: Vector): Vector;
VAR
	fDelta: REAL;
	ray00, ray10, ray01, ray11: Ray;
	c00, c10, c01, c11, cAvg: Vector;
	fSum: REAL;
	(* [px00, px10, px01, px11] *)
	vDst: Vector; 
BEGIN

	fDelta := 1 / Pow2(rc.options.nAALevels - nLevel + 2);

	(* Trace additional 4 rays *)
	ComputeSecondaryRays(rc, fX, fY, fDelta,
	  ray00, ray10, ray01, ray11);
	  
	c00 := rc.funcTrace(rc, ray00, 0);
	c10 := rc.funcTrace(rc, ray10, 0);
	c01 := rc.funcTrace(rc, ray01, 0);
	c11 := rc.funcTrace(rc, ray11, 0);
		
	clamp(c00);
	clamp(c10);
	clamp(c01);
	clamp(c11);
	
	(* [px00, px10, px01, px11] *)
	vDst := vector(dist(cFrmBuf, c00), dist(cFrmBuf, c10),
		dist(cFrmBuf, c01), dist(cFrmBuf, c11));

	IF nLevel > 1 THEN
	
		IF vDst[px00] > rc.options.fAAThreshold THEN
			c00 := Refine(rc, fX - fDelta, fY - fDelta, nLevel - 1, c00);
			vDst[px00] := dist(cFrmBuf, c00)
		END;
		
		IF vDst[px10] > rc.options.fAAThreshold THEN
			c10 := Refine(rc, fX + fDelta, fY - fDelta, nLevel - 1, c10);
			vDst[px10] := dist(cFrmBuf, c10)
		END;
		
		IF vDst[px01] > rc.options.fAAThreshold THEN
			c01 := Refine(rc, fX - fDelta, fY + fDelta, nLevel - 1, c01);
			vDst[px01] := dist(cFrmBuf, c01)
		END;
		
		IF vDst[px11] > rc.options.fAAThreshold THEN
			c11 := Refine(rc, fX + fDelta, fY + fDelta, nLevel - 1, c11);
			vDst[px11] := dist(cFrmBuf, c11)
		END
		
	END;
	
	IF (vDst[px00] > rc.options.fAAThreshold) OR (vDst[px10] > rc.options.fAAThreshold) OR
	  (vDst[px01] > rc.options.fAAThreshold) OR (vDst[px11] > rc.options.fAAThreshold)
	THEN
		
		fSum := vDst[px00] + vDst[px10] + vDst[px01] + vDst[px11];
		vDst := vDst / fSum;
		
		cAvg := (c00 * vDst[px00] + c10 * vDst[px10] + c01 * vDst[px01] + c11 * vDst[px11] + cFrmBuf) / 2;

		RETURN cAvg

	END;

	RETURN cFrmBuf

END Refine;

PROCEDURE RenderBucket*(rc: RenderContext; VAR b: Bucket);
VAR
	i, j, nPix, w: LONGINT;
	ray: Ray;
	pix: Vector;
	bBucketEdge: BOOLEAN;
	FrmTmp: FrameBuffer;
BEGIN

	(* First pass of rendering *)
	FOR j := b.y0 TO b.y1 DO
		FOR i := b.x0 TO b.x1 DO
			(* Index of pixel in Frame Buffer *)
			nPix := j * rc.options.imageWidth + i;
			(* Compute primary ray *)
			ComputePrimaryRay(rc, i, j, ray);
			(* Trace ray *)
			rc.FrmBuf[nPix] := rc.funcTrace(rc, ray, 0);
			(* Limit values *)
			clamp(rc.FrmBuf[nPix]);
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
					((dist(pix, b.FrmLinePrev[i - 1]) > rc.options.fAAThreshold) OR
					(dist(pix, b.FrmLinePrev[i]) > rc.options.fAAThreshold) OR
					(dist(pix, b.FrmLinePrev[i + 1]) > rc.options.fAAThreshold) OR
					(dist(pix, b.FrmLineCur[i - 1]) > rc.options.fAAThreshold) OR
					(dist(pix, b.FrmLineCur[i + 1]) > rc.options.fAAThreshold) OR
					(dist(pix, rc.FrmBuf[(j + 1) * w + (i - 1)]) > rc.options.fAAThreshold) OR
					(dist(pix, rc.FrmBuf[(j + 1) * w + i]) > rc.options.fAAThreshold) OR
					(dist(pix, rc.FrmBuf[(j + 1) * w + (i + 1)]) > rc.options.fAAThreshold)))
			THEN
				INC(b.nSecondaryRays, 4);
				IF rc.options.bShowAAPixels THEN
					rc.FrmBuf[nPix] := vector(0.0, 0.0, 1.0)
				ELSE
					rc.FrmBuf[nPix] := Refine(rc, i + 0.5, j + 0.5,
						rc.options.nAALevels, rc.FrmBuf[nPix])
				END;
			END
		END;
		FrmTmp := b.FrmLinePrev;
		b.FrmLinePrev := b.FrmLineCur;
		b.FrmLineCur := FrmTmp;
	END;
END RenderBucket;

PROCEDURE GammaCorrection*(rc: RenderContext);
VAR
	iPix: LONGINT;
BEGIN
	IF rc.options.gamma # 1 THEN
		FOR iPix := 0 TO LEN(rc.FrmBuf^) - 1 DO
			rc.FrmBuf[iPix][0] := pow(rc.FrmBuf[iPix][0], rc.options.gamma);
			rc.FrmBuf[iPix][1] := pow(rc.FrmBuf[iPix][1], rc.options.gamma);
			rc.FrmBuf[iPix][2] := pow(rc.FrmBuf[iPix][2], rc.options.gamma)
		END
	END
END GammaCorrection;

PROCEDURE CreateObject*(center: Vector; radius: REAL; color: Vector;
	matType: INTEGER; isLight: BOOLEAN): Object;
VAR
	object: Object;
BEGIN
	NEW(object, center, radius, color, matType, isLight);
	RETURN object
END CreateObject;

(*
PROCEDURE CreateCone*(center: Vector; radius, height: REAL; color: Vector;
	matType: INTEGER; isLight: BOOLEAN): Object;
VAR
	object: Cone;
BEGIN
	NEW(object, center, radius, color, matType, isLight);
	object.height := height;
	RETURN object
END CreateCone;

PROCEDURE CreateCylinder*(center: Vector; radius, zmin, zmax: REAL; color: Vector;
	matType: INTEGER; isLight: BOOLEAN): Object;
VAR
	object: Cylinder;
BEGIN
	NEW(object, center, radius, color, matType, isLight);
	object.zmin := zmin;
	object.zmax := zmax;
	RETURN object
END CreateCylinder;
*)

PROCEDURE CreateDisk*(center: Vector; radius: REAL; vn: Vector; color: Vector;
	matType: INTEGER; isLight: BOOLEAN): Object;
VAR
	object: Disk;
BEGIN
	NEW(object, center, radius, color, matType, isLight);
	object.vn := vn;
	RETURN object
END CreateDisk;

(*
PROCEDURE CreateSphere*(center: Vector; radius: REAL; color: Vector;
	matType: INTEGER; isLight: BOOLEAN): Object;
VAR
	object: Sphere;
BEGIN
	NEW(object, center, radius, color, matType, isLight);
	RETURN object
END CreateSphere;
*)

PROCEDURE pow(x, y: REAL): REAL;
BEGIN
	IF x = 0.0 THEN
		RETURN 0.0
	ELSE
		RETURN Math.exp(y * Math.ln(x))
	END
END pow;

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

BEGIN
	ZeroVector := vector(0, 0, 0);
END Lib3D.

SystemTools.Free Lib3D ~
