
*** Bindings ***

Compiler.Compile -b=AMD

	Bindings\I386.BASScpu.Mod
	Bindings\Win32.BASS.Mod
	Bindings\Win32.Pipe.Mod ~

*** Components ***

Compiler.Compile -b=AMD

	Components\WMChart.Mod
	Components\WMLCD.Mod
	Components\WMLEDLadder.Mod ~

*** Demos ***

Compiler.Compile -b=AMD

	Demos\WMAStar.Mod
	Demos\WMAStarSet.Mod
	Demos\WMBass3DTest.Mod
	Demos\WMFM.Mod
	Demos\WMRaycaster.Mod
	Demos\WMRaycasterMaze.Mod
	Demos\WMXmas.Mod ~

*** Dialogs ***

Compiler.Compile -b=AMD
	Dialogs\WMColorPicker.Mod ~





















Lode`s Computer Graphics Raycasting Tutorial ported to Active Oberon

Compile:

Native A2:
	Compiler.Compile -b=AMD PreciseTimer.Mod WMRaycaster.Mod WMRaycasterMaze.Mod ~
WinAos:
	Compiler.Compile -b=AMD Win32.PreciseTimer.Mod WMRaycaster.Mod WMRaycasterMaze.Mod ~
	
Run:

	WMRaycaster.Open ~
	WMRaycasterMaze.Open ~





BASS 2.4.12 A2 OS (WinAos, UnixAos) Wrapper

Windows

x86:
	Compiler.Compile -b=AMD I386.BASScpu.Mod Win32.BASS.Mod ~
x64:
	Compiler.Compile -b=AMD --bits=64 AMD64.BASScpu.Mod Win32.BASS.Mod ~

Linux

x86:
	Compiler.Compile -b=AMD I386.BASScpu.Mod Linux.BASS.Mod ~
x64:
	Compiler.Compile -b=AMD --bits=64 AMD64.BASScpu.Mod Linux.BASS.Mod ~

Darwin

x86:
	Compiler.Compile -b=AMD I386.BASScpu.Mod Darwin.BASS.Mod ~
x64:
	Compiler.Compile -b=AMD --bits=64 AMD64.BASScpu.Mod Darwin.BASS.Mod ~

Demos

x86:
	Compiler.Compile -b=AMD
		MathUtils.Mod Containers.Mod AAGraphics.Mod
		WMDropDownLists.Mod WMBass3DTest.Mod ~
x64:
	Compiler.Compile -b=AMD --bits=64
		MathUtils.Mod Containers.Mod AAGraphics.Mod
		WMDropDownLists.Mod WMBass3DTest.Mod ~

	WMBass3DTest.Open ~

SystemTools.Free WMBass3DTest WMDropDownLists MathUtils
	Containers AAGraphics BASS BASScpu ~

Installation in Darwin:

1. Copy BASS folder, for example, to desktop
2. Start shell, get admin rights
	sudo -s
3. Copy libbass.dylib into /usr/lib
	cp Desktop/BASS/libbass.dylib /usr/lib/libbass.dylib
4. Check rights
	cd /usr/lib
	ls -l libbass.dylib
change if needed
	chmod 777 libbass.dylib
4. Go to working directory and run Aos
	cd /Users/User/Desktop/BASS
	aos

