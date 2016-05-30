Before compilation add root "Work" and "Work/Resources"
folders to Paths.Search parameter (in listed sequence) in aosg.ini (or better
do a copy named "myaos.ini" and make changes in it)

To enable a dark color scheme in PET add "Branch" folder to Paths.Search parameter
and add this to Configuration.XML:

		<Section name="Applications">
			<Section name="PET">
				<Section name="General">
					<Setting name="BackgroundColor" value="0004080FFH"/>

*** A2 sources improvements and small modifications ("Branch") ***

Compiler.Compile -b=AMD --objectFile=Generic --newObjectFile
		--mergeSections --symbolFileExtension=.SymW --objectFileExtension=.GofW

	Branch/PETTrees.Mod
	Branch/PET.Mod ~

*** Bindings ***

Compiler.Compile -b=AMD --objectFile=Generic --newObjectFile
		--mergeSections --symbolFileExtension=.SymW --objectFileExtension=.GofW

	Bindings/BASS/I386.BASScpu.Mod
	Bindings/BASS/Win32.BASS.Mod
	Bindings/Win32.Pipe.Mod ~

*** Libraries ***

Compiler.Compile -b=AMD --objectFile=Generic --newObjectFile
		--mergeSections --symbolFileExtension=.SymW --objectFileExtension=.GofW

	Libs/AAGraphics.Mod
	Libs/CanvasTools.Mod

	Libs/Vector.Mod
	Libs/NewContainers.Mod
	
	Libs/MathUtils.Mod
	Libs/Win32.PreciseTimer.Mod
	Libs/ZipLoader.Mod
	
	(* deprecated *)
	Libs/Containers.Mod ~

*** Components ***

Compiler.Compile -b=AMD --objectFile=Generic --newObjectFile
		--mergeSections --symbolFileExtension=.SymW --objectFileExtension=.GofW

	Components/WMChart.Mod
	Components/WMComboBox.Mod
	Components/WMDropDownLists.Mod
	Components/WMLCD.Mod
	Components/WMLEDLadder.Mod ~

*** Dialogs ***

Compiler.Compile -b=AMD --objectFile=Generic --newObjectFile
		--mergeSections --symbolFileExtension=.SymW --objectFileExtension=.GofW

	Dialogs/WMColorPicker.Mod ~
	
*** Examples ***

Compiler.Compile -b=AMD --objectFile=Generic --newObjectFile
		--mergeSections --symbolFileExtension=.SymW --objectFileExtension=.GofW
		
	Examples/RegExp/RegExpNFA.Mod
	Examples/RegExp/RegExpMaps.Mod
	Examples/RegExp/RegExpDFA.Mod
	Examples/RegExp/RegExpSubsetConstruct.Mod
	Examples/RegExp/RegExpParse.Mod

	Examples/WMAAGraphicsExample.Mod ~

*** Tools ***

Compiler.Compile -b=AMD --objectFile=Generic --newObjectFile
		--mergeSections --symbolFileExtension=.SymW --objectFileExtension=.GofW

	Tools/ImportCollector.Mod
	Tools/ImportGraph.Mod
	Tools/WinStarter.Mod ~

*** Demos ***

Compiler.Compile -b=AMD --objectFile=Generic --newObjectFile
		--mergeSections --symbolFileExtension=.SymW --objectFileExtension=.GofW

	Demos/WMAStar.Mod
	Demos/WMAStarSet.Mod
	Demos/WMBass3DTest.Mod
	Demos/WMBassDSPTest.Mod
	Demos/WMColorLines.Mod
	Demos/WMFM.Mod
	Demos/WMRaycaster.Mod
	Demos/WMRaycasterMaze.Mod
	Demos/WMXmas.Mod ~

Run demos

	WMAStar.Open ~
	WMAStarSet.Open ~
	WMBass3DTest.Open ~
	WMBassDSPTest.Open ~
	WMColorLines.Open ~
	WMRaycaster.Open ~
	WMRaycasterMaze.Open ~
	WMXmas.Open ~


