MODULE BASScpu; (** AUTHOR "SAGE"; PURPOSE "BASS 2.4 A2 OS Wrapper - CPU specific types"; *)

TYPE
	DWORD = LONGINT;
	PAnsiChar = ADDRESS;
	HSAMPLE = LONGINT;		(* sample handle *)
	HPLUGIN = LONGINT;		(* Plugin handle *)

	(* Channel info structure *)
	BASS_CHANNELINFO* = RECORD
		freq*: DWORD;					(* default playback rate *)
		chans*: DWORD;					(* channels *)
		flags*: SET;						(* BASS_SAMPLE/STREAM/MUSIC/SPEAKER flags *)
		ctype*: SET;						(* type of channel *)
		origres*: DWORD;				(* original resolution *)
		plugin*: HPLUGIN;			(* plugin *)
		sample*: HSAMPLE;			(* sample *)
#IF I386 THEN
#ELSIF AMD64 THEN
		padding*: DWORD;
#ELSE
		unimplemented
#END
		filename*: PAnsiChar;	(* filename *)
	END;

	BASS_PLUGINFORM* = RECORD
		ctype*: DWORD;				(* channel type *)
#IF I386 THEN
#ELSIF AMD64 THEN
		padding*: DWORD;
#ELSE
		unimplemented
#END
		name*: PAnsiChar;		(* format description *)
		exts*: PAnsiChar;		(* file extension filter ( *.ext1;*.ext2;etc...) *)
	END;

END BASScpu.
