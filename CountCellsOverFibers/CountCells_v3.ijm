/*
 * bioImaging - 22/07/2019
 * INEB -  Instituto Nacional de Engenharia Biomedica
 * i3S - Instituto de Investigacao e Inovacao em Saude
 * 
 * author:
 * Eduardo Conde-Sousa
 * econdesousa@ineb.up.pt
 * econdesousa@gmail.com
 * 
 * 
 *
 * ########################################################################## 
 * Count Cells
 * ########################################################################## 
 * 
 * 
 * 
 */

run("Colors...", "foreground=black background=white selection=green");
if( roiManager("count")>0){
	roiManager("reset");
}
 
#@ Integer (label="Noise Tolerance: ",value=2000) NoiseTol
#@ File (label="Select The ROI Directory", style="directory",value="") roiDIR
#@ File[]  (label="Select Working Files", style="file") listOfPaths
#@ File (label="Select The Output Directory", style="directory",value="") outDir

batch=false;
if (listOfPaths.length>1){
	setBatchMode(true);
	batch=true;
	if (!File.exists(outDir)){
		File.makeDirectory(outDir);
	}
}
displaySettings();
for (file = 0; file < listOfPaths.length; file++) {
	clearWindows("");
	clearWindows("all");
	iter=file+1;
	print("Image "+iter+" of "+listOfPaths.length+":"+listOfPaths[file]);
	open(listOfPaths[file]);
	showProgress(file/listOfPaths.length);
	procFile(NoiseTol,roiDIR,listOfPaths[file],outDir);
	if (listOfPaths.length>1){
		run("Close All");
	}
}
if (batch){
	clearWindows("");
}

function procFile(NoiseTol,roiDIR,workingFile,outDir){
	mainImageID=getImageID();
	mainImageName=File.getName(workingFile);
	rename("mainWindow");
	roiManager("open", roiDIR+File.separator+mainImageName+".roi");
	roiManager("select", 0);
	run("Create Mask");
	rename("fibers");
	run("Analyze Particles...", "  show=Nothing summarize");
	// roiMASK: mask containing fibers locations
	rename("roiMASK");
	selectWindow("mainWindow");
	run("Z Project...", "projection=[Max Intensity]");
	run("Split Channels");
	selectWindow("C1-MAX_mainWindow");
	rename("red");
	selectWindow("C2-MAX_mainWindow");
	rename("green");
	run("Find Maxima...", "noise="+NoiseTol+" output=[Point Selection]");
	run("Create Mask");
	selectWindow("green");
	close();
	selectWindow("Mask");
	rename("green");
	// until here "green" is a mask with all cells.
	// now, we will remove cells outide fibers
	imageCalculator("AND", "green","roiMASK");
	selectWindow("green");
	run("Set Measurements...", "  redirect=None decimal=2");
	run("Analyze Particles...", "size=0-Infinity show=Masks summarize"); // a copy of mask is created
	selectWindow("red");
	run("Find Maxima...", "noise="+NoiseTol+" output=[Point Selection]");
	run("Create Mask");
	selectWindow("red");
	close();
	selectWindow("Mask");
	rename("red");
	// until here "red" is a mask with all cells.
	// now, we will remove cells outide fibers
	imageCalculator("AND", "red","roiMASK");
	selectWindow("red");
	run("Set Measurements...", "  redirect=None decimal=2");
	run("Analyze Particles...", "size=0-Infinity show=Masks summarize"); // a copy of mask is created
	
	selectWindow("Mask of green"); // copy created before
	run("Create Selection");
	roiManager("add")
	roiManager("select", roiManager("count")-1);
	run("Enlarge...", "enlarge=1");
	run("Create Mask");
	selectWindow("Mask of green");
	close();
	rename("Mask of green");
	roiManager("delete");
	run("Create Selection");
	roiManager("add")
	roiManager("select", roiManager("count")-1);
	roiManager("rename", "green_"+NoiseTol);
	selectWindow("Mask of red");
	run("Create Selection");
	roiManager("add")
	roiManager("select", roiManager("count")-1);
	run("Enlarge...", "enlarge=1");
	run("Create Mask");
	selectWindow("Mask of red");
	close();
	rename("Mask of red");
	roiManager("delete");
	run("Create Selection");
	roiManager("add")
	roiManager("select", roiManager("count")-1);
	roiManager("rename", "red_"+NoiseTol);
	selectWindow("red");
	close();
	selectWindow("green");
	close();
	selectWindow("roiMASK");
	rename("fibres");
	selectWindow("Mask of red");
	rename("red_Fibers");
	selectWindow("Mask of green");
	rename("green_Fibers");
	run("Images to Stack", "name=Stack title=[] use");
	rename("out_"+NoiseTol+"_"+mainImageName);
	selectImage(mainImageID);
	run("Duplicate...", "title=mainWindow2 duplicate");
	run("Z Project...", "projection=[Max Intensity]");
	run("Split Channels");
	selectWindow("C1-MAX_mainWindow2");
	rename("red");
	selectWindow("C2-MAX_mainWindow2");
	rename("green");
	selectWindow("mainWindow2");
	close();
	run("Enhance Contrast", "saturated=0.35");
	run("Apply LUT");
	roiManager("select", 0);
	run("Add Selection...");
	roiManager("select", 1);
	run("Add Selection...");
	selectWindow("red");
	run("Enhance Contrast", "saturated=0.35");
	run("Apply LUT");
	roiManager("select", 0);
	run("Add Selection...");
	roiManager("select", 2);
	run("Add Selection...");
	run("Images to Stack", "name=Stack title=[] use");
	rename("Stack_out_"+NoiseTol+"_"+mainImageName);
	imOut1ID=getImageID();
	run("Grays");
	selectImage(mainImageID);
	rename(mainImageName);
	selectImage(imOut1ID);
	ind=lastIndexOf(mainImageName, ".tif");
	mainImageName=substring(mainImageName, 0, ind);
	if (batch){
		saveAs("tiff", outDir+File.separator+mainImageName+"_NoiseTol_"+NoiseTol+".tif");
		selectWindow("Summary");
		saveAs("text", outDir+File.separator+mainImageName+"_NoiseTol_"+NoiseTol+".txt");
		roiManager("select", newArray(0,1,2));
		roiManager("save selected", outDir+File.separator+mainImageName+"_NoiseTol_"+NoiseTol+".zip");
	}
}

function ImportSettingsTable(fileName){
	lineseparator = "\n";
	cellseparator = "\t";

	lines=split(File.openAsString(fileName), lineseparator);
	
	//line[0] <==> header
	//starting from line[1]
	settingsVec=newArray(9);
	for (i=1; i<lines.length; i++) {
	   items=split(lines[i], cellseparator);
	   settingsVec[i-1]=items[1];
	}

	channel		= settingsVec[0];
	saturation	= settingsVec[1];
	nBC			= settingsVec[2];
	/* data bellow isn't to be used here
	flatfield	= settingsVec[3];
	lcer		= settingsVec[4];
	mfr			= settingsVec[5];
	laplRad		= settingsVec[6];
	TubnessRad	= settingsVec[7];
	minFiberSize= settingsVec[8];
	items=split(lines[i++], cellseparator);
	outDir		= items[2];
	*/

	outVec= newArray(channel,saturation,nBC);
	return outVec;

		
}




function clearWindows(type){
	if (type=="all"){
		run("Close All");
	} 
	if (type=="settings"){
		windows = getList("window.titles"); 
	   	for (i=0; i<windows.length; i++){
	   		if (windows[i] == "settings"){
	   			selectWindow(windows[i]);	run("Close");
	   		}
   		}
	}
	windows = getList("window.titles"); 
   	for (i=0; i<windows.length; i++){
   		if (windows[i] != "settings"){
   			if (windows[i] != "Log"){
   				selectWindow(windows[i]);	run("Close");
   			}
   		}
   	}
   	run("Clear Results");
   	roiManager("reset");
   	run("Collect Garbage");
}


function displaySettings() {
	print("\\Clear");
	print("===================================================================");
	print("Settings:");
	print("===================================================================");
	print("Noise Tolerance:    "+ NoiseTol);
	print("ROI Directory:        "+roiDIR);
	print("Output Directory:   "+outDir);
	print("===================================================================");
	print("===================================================================");
	print(" ");
	print(" ");
}


run("Colors...", "foreground=black background=white selection=yellow");