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

Translated to Active Oberon by Yaroslav Romanchenko (SAGE) June, 2008

*)

MODULE lesson1;

IMPORT

	Math, Files, Commands;
	
CONST

	imageWidth = 640;
	imageHeight = 480;
	
	MAX_OBJECTS = 3;
	MAX_DEPTH_LEVEL = 3;
	
	MATTE = 1;
	DIFFUSE = 2;
	GLASS = 3;
	
	INFINITY = SHORT(1.0D6);

TYPE

	Vector* = RECORD
		x*, y*, z*: REAL
	END;

	Color* = RECORD
		r*, g*, b*: REAL
	END;
	
	Ray* = RECORD
		origin*: Vector;
		direction*: Vector;
	END;
	
	Object = OBJECT
	VAR
		center: Vector;
		radius, radius2: REAL;
		color: Color;
		materialType: INTEGER;
		isLight: BOOLEAN;
		indexOfRefraction: REAL;
		
	PROCEDURE &New(c: Vector; r: REAL; col: Color; matType: INTEGER; l: BOOLEAN);
	BEGIN
		center := c;
		radius := r;
		radius2 := r * r;
		color := col;
		materialType := matType;
		isLight := l;
		indexOfRefraction := 1.3;
	END New;
	
	END Object;
	
	Objects = POINTER TO ARRAY OF Object;
	
	Light = RECORD
		object: Object
	END;

VAR
	object: Object;
	objects*: Objects;
	numObjects*: INTEGER;
	light*: Light;
	bgColor*: Color;

(** Vector **)

PROCEDURE vector(x, y, z: REAL): Vector;
VAR
	v: Vector;
BEGIN
	v.x := x;
	v.y := y;
	v.z := z;
	RETURN v
END vector;

PROCEDURE length(v: Vector): REAL;
BEGIN
	RETURN Math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z);
END length;

PROCEDURE dot(v1, v2: Vector): REAL;
BEGIN
	RETURN v1.x * v2.x + v1.y * v2.y + v1.z * v2.z
END dot;

PROCEDURE "*"(v: Vector; f: REAL): Vector;
BEGIN
	RETURN vector(v.x * f, v.y * f, v.z * f)
END "*";

PROCEDURE "-"(v1, v2: Vector): Vector;
BEGIN
	RETURN vector(v1.x - v2.x, v1.y - v2.y, v1.z - v2.z)
END "-";

PROCEDURE "+"(v1, v2: Vector): Vector;
BEGIN
	RETURN vector(v1.x + v2.x, v1.y + v2.y, v1.z + v2.z)
END "+";

PROCEDURE "-"(VAR v: Vector): Vector;
BEGIN
	RETURN vector(-v.x, -v.y, -v.z)
END "-";

PROCEDURE normalize(VAR v: Vector);
VAR
	len2, lenInv: REAL;
BEGIN
	len2 := v.x * v.x + v.y * v.y + v.z * v.z;
	IF len2 > 0.0 THEN
		lenInv := 1.0 / Math.sqrt(len2);
		v.x := v.x * lenInv;
		v.y := v.y * lenInv;
		v.z := v.z * lenInv
	END
END normalize;
	
(** Color **)

PROCEDURE color(r, g, b: REAL): Color;
VAR
	c: Color;
BEGIN
	c.r := r;
	c.g := g;
	c.b := b;
	RETURN c
END color;

PROCEDURE "*"(c: Color; f: REAL): Color;
BEGIN
	RETURN color(c.r * f, c.g * f, c.b * f)
END "*";

PROCEDURE "+"(c1, c2: Color): Color;
BEGIN
	RETURN color(c1.r + c2.r, c1.g + c2.g, c1.b + c2.b)
END "+";

PROCEDURE "*"(c1, c2: Color): Color;
BEGIN
	RETURN color(c1.r * c2.r, c1.g * c2.g, c1.b * c2.b)
END "*";

PROCEDURE clamp*(VAR c: Color);
BEGIN
	IF c.r > 1.0 THEN  
		c.r := 1.0
	END;
	IF c.g > 1.0 THEN  
		c.g := 1.0
	END;
	IF c.b > 1.0 THEN  
		c.b := 1.0
	END
END clamp;


PROCEDURE computePrimRay*(i, j, imageWidth, imageHeight: LONGINT; frameAspectRatio: REAL; VAR ray: Ray);
VAR
	fov: REAL;
	f: REAL;
	angle: REAL;
	dx: REAL;
	dy: REAL; 
BEGIN
	fov := 45;
	f := fov * 0.5 * Math.pi / 180.0;
	angle := Math.sin(f) / Math.cos(f);
	ray.origin := vector(0, 0, 0);
	dx := 2 * frameAspectRatio / imageWidth;
	dy := 2 / imageHeight;
	ray.direction := vector(angle * ((i + 0.5) * dx - frameAspectRatio), angle * (-(j + 0.5) * dy + 1), 1);
	normalize(ray.direction)
END computePrimRay;

PROCEDURE intersect(object: Object; ray: Ray; VAR t: REAL): BOOLEAN;
VAR
	oc: Vector;
	oc2: REAL;
	tca: REAL;
	outside: BOOLEAN;
	d2: REAL;
	thc: REAL;
BEGIN
	(* // use geometric method *)
	oc := object.center - ray.origin;
	(* // square distance to center of sphere *)
	oc2 := dot(oc, oc);
	(* // distance to point on ray closest to sphere center *)
	tca := dot(oc, ray.direction);
	
	outside := (oc2 > object.radius2);
	IF (tca < 0) & outside THEN  
		RETURN FALSE
	END;
	
	(* // square distance from sphere center to closest point on ray *)
	d2 := oc2 - tca * tca; 
	(* // square distance from perpendicular bisector to center *)
	thc := object.radius2 - d2; 
	
	IF thc < 0 THEN 
		RETURN FALSE
	END;
	IF outside THEN 
		t := tca - Math.sqrt(thc)
	ELSE
		t := tca + Math.sqrt(thc)
	END;
	
	IF t < 0 THEN  
		RETURN FALSE
	END;
	RETURN TRUE
END intersect;


PROCEDURE snell(incidentRay: Vector; surfaceNormal: Vector; n1: REAL; n2: REAL; VAR reflectionDir: Vector; VAR refractionDir: Vector);
VAR
	n1n2: REAL;
	cost1: REAL;
	cost2: REAL;
BEGIN
	n1n2 := n1 / n2;
	cost1 := dot(incidentRay, surfaceNormal);
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
	Kr := (Rp*Rp + Rs*Rs) * 0.5; 
END fresnel;

PROCEDURE Trace*(ray: Ray; depth: INTEGER; objects: Objects; numObjects: INTEGER; light: Light; bgColor: Color): Color;
VAR
	bias: REAL;
	object: Object;
	minDistance: REAL;
	pHit: Vector;
	nHit: Vector;
	t: REAL;
	k: INTEGER;
	reflectionRay, refractionRay: Ray;
	cosi: REAL;
	cost: REAL;
	Kr: REAL;
	reflectionColor: Color;
	refractionColor: Color;
	lightColor: Color;
	shadowRay: Ray;
	isInShadow: BOOLEAN;
	exit: BOOLEAN;
	len: REAL;
	LdotN: REAL;
BEGIN
	IF depth > MAX_DEPTH_LEVEL THEN 
		RETURN bgColor
	END;
	
	bias := 0.001;
	minDistance := INFINITY; 
	object := NIL;
	k := 0;
	WHILE k < numObjects DO
	
		IF intersect(objects[k], ray, t) THEN 
			IF t < minDistance THEN 
				minDistance := t; 
				object := objects[k]
			END
		END;
		INC(k)
	END;
	IF object = NIL THEN 
		RETURN bgColor 
	END;
	
	pHit := ray.origin + ray.direction * minDistance;
	nHit := pHit - object.center;
	normalize(nHit);
	
	IF object.materialType = GLASS THEN 
		(* // compute reflection and refraction direction *)
		reflectionRay.origin := pHit + nHit * bias;
		refractionRay.origin := pHit - nHit * bias;
		snell(ray.direction, -nHit, 1.0, object.indexOfRefraction, reflectionRay.direction, refractionRay.direction); 
		normalize(reflectionRay.direction);
		normalize(refractionRay.direction); 
		cosi := dot(ray.direction, -nHit); 
		cost := dot(refractionRay.direction, -nHit); 
		fresnel(1.0, object.indexOfRefraction, cosi, cost, Kr); 
		IF Kr < 0.0 THEN
			Kr := 0.0
		ELSIF Kr > 1.0 THEN 
			Kr := 1.0
		END;
		reflectionColor := Trace(reflectionRay, depth + 1, objects, numObjects, light, bgColor); 
		refractionColor := Trace(refractionRay, depth + 1, objects, numObjects, light, bgColor); 
		RETURN object.color * refractionColor * (1-Kr) + reflectionColor * Kr
	END;
	
	IF object.materialType = MATTE THEN 
		RETURN object.color
	END;

	isInShadow := FALSE;
	shadowRay.origin := pHit + nHit * bias;
	shadowRay.direction := light.object.center - pHit; 
	len := length(shadowRay.direction); 
	normalize(shadowRay.direction);
 
	LdotN := dot(shadowRay.direction, nHit); 
	IF LdotN < 0 THEN 
		RETURN color(0, 0, 0)
	END;
	lightColor := light.object.color; 
	k := 0; exit := FALSE;
	WHILE (k < numObjects) & ~exit DO
		IF (intersect(objects[k], shadowRay, t)) & ~(objects[k]^.isLight) THEN 
			IF objects[k].materialType = GLASS THEN 
				lightColor := lightColor * objects[k].color;  (* // attenuate light color by glass color *)
			ELSE
				isInShadow := TRUE; 
			END;
			exit := TRUE
		END;
			INC(k);
	END;
	lightColor := lightColor * (1.0 / (len*len)); 
	IF isInShadow THEN
		RETURN color(0, 0, 0)
	ELSE
		RETURN object.color * lightColor * LdotN
	END
END Trace;

PROCEDURE createNewObject(p: Vector; r: REAL; col: Color; matType: INTEGER; isLight: BOOLEAN;
	VAR objects: Objects; VAR numObjects: INTEGER): Object;
VAR
	object: Object;
BEGIN
	ASSERT(numObjects <= MAX_OBJECTS);
	NEW(object, p, r, col, matType, isLight);
	objects[numObjects] := object;
	INC(numObjects);
	RETURN object
END createNewObject;

PROCEDURE pow(x, y: REAL): REAL;
BEGIN
	IF x = 0.0 THEN
		RETURN 0.0
	ELSE
		RETURN Math.exp(y * Math.ln(x))
	END
END pow;

PROCEDURE Main*(c: Commands.Context);
VAR
	frameAspectRatio: REAL;
	i, j: INTEGER;
	bgColor: Color;
	primRay: Ray;
	pixel: Color;
	stream: Files.Writer;
	file: Files.File;
	r, g, b: CHAR;
	gamma: REAL;
BEGIN

	
	ASSERT(imageWidth >= imageHeight);
	
	file := Files.New("raytrace.ppm");
	Files.OpenWriter(stream, file, 0);
	
	stream.String("P6"); stream.String(" ");
	stream.Int(imageWidth, 0); stream.String(" ");
	stream.Int(imageHeight, 0); stream.String(" ");
	stream.Int(255, 0); stream.Char(0DX);

	gamma := 1.0; (* // mac *)
	
	frameAspectRatio := imageWidth / imageHeight; 

	
	FOR j := 0 TO imageHeight - 1 DO
		FOR i := 0 TO imageWidth - 1 DO
			(* // compute primary ray direction *)
			computePrimRay(i, j, imageWidth, imageHeight, frameAspectRatio, primRay); 
			pixel := Trace(primRay, 0, objects, numObjects, light, bgColor);
			clamp(pixel);
			
			pixel.r := 255 * pow(pixel.r, gamma);
			pixel.g := 255 * pow(pixel.g, gamma);
			pixel.b := 255 * pow(pixel.b, gamma);
			IF pixel.r > 255 THEN
				r := CHR(255)
			ELSE
				r := CHR(ENTIER(pixel.r))
			END;
			IF pixel.g > 255 THEN
				g := CHR(255)
			ELSE
				g := CHR(ENTIER(pixel.g))
			END;
			IF pixel.b > 255 THEN
				b := CHR(255)
			ELSE
				b := CHR(ENTIER(pixel.b))
			END;
			
			stream.Char(r);
			stream.Char(g);
			stream.Char(b)

		END
	END;
	
	stream.Update;
	Files.Register(file);
	
	c.out.Ln;
	c.out.String("Done!");
	c.out.Ln;
	
	(*  // clean memory *)
	(* Not needed in Active Oberon because of Garbage Collector *)

END Main;

BEGIN

	bgColor := color(0.5, 0.62, 0.78);
	numObjects := 0;
	NEW(objects, MAX_OBJECTS + 1);
	object := createNewObject(vector(0, 0, 15), 3, color(0.5, 0.7, 0.5), GLASS, FALSE, objects, numObjects);
	object := createNewObject(vector(-4.5, 4.5, 17), 1.8, color(1, 0.3, 0.3), DIFFUSE, FALSE, objects, numObjects);
	object := createNewObject(vector(2, -2, 19), 2, color(0.3, 1, 0.3), DIFFUSE, FALSE, objects, numObjects);
	light.object := createNewObject(vector(3, 3, 13), 0.5, color(50, 50, 50), MATTE, TRUE, objects, numObjects);

END lesson1.

SystemTools.Free lesson1~
lesson1.Main~