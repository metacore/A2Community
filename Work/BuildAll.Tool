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

Compiler.Compile -p=Win32G

	Branch/WMTextView.Mod
	Branch/PETTrees.Mod
	Branch/PET.Mod ~

*** Bindings ***

Compiler.Compile -p=Win32G

	Bindings/BASS/I386.BASScpu.Mod
	Bindings/BASS/Win32.BASS.Mod
	Bindings/Win32.Pipe.Mod ~

*** Libraries ***

Compiler.Compile -p=Win32G

	Libs/AAGraphics.Mod
	Libs/CanvasTools.Mod

	Libs/MathUtils.Mod
	Libs/Win32.PreciseTimer.Mod

	Libs/Generics.Mod

	(* deprecated *)
	Libs/Containers.Mod ~

*** Components ***

Compiler.Compile -p=Win32G

	Components/WMChart.Mod
	Components/WMComboBox.Mod
	Components/WMDropDownLists.Mod
	Components/WMLCD.Mod
	Components/WMLEDLadder.Mod ~

*** Dialogs ***

Compiler.Compile -p=Win32G

	Dialogs/WMColorPicker.Mod ~

*** Examples ***

Compiler.Compile -p=Win32G

	Examples/RegExp/RegExpNFA.Mod
	Examples/RegExp/RegExpMaps.Mod
	Examples/RegExp/RegExpDFA.Mod
	Examples/RegExp/RegExpSubsetConstruct.Mod
	Examples/RegExp/RegExpParse.Mod

	Examples/WMAAGraphicsExample.Mod ~

*** Tools ***

Compiler.Compile -p=Win32G

	Tools/ImportCollector.Mod
	Tools/ImportGraph.Mod
	Tools/WinStarter.Mod ~

*** Demos ***

Compiler.Compile -p=Win32G

	Demos/WMAStar.Mod
	Demos/WMAStarSet.Mod
	Demos/VisualContainer/VCTypes.Mod
	Demos/VisualContainer/VCObjects.Mod
	Demos/VisualContainer/WMVC.Mod
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


