/*
 * bioImaging - 04/07/2019
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
 * Fiber Segmentation (histogram/distribution skewed to the left)
 * ########################################################################## 
 * 
 * 
 * 
 */
 
 
 
 
#@ Integer (label="Channel",value=1) channel
#@ Float (label="Brightness  Contrats Saturation",value=0,95) saturation
#@ Integer (label="Number of Brightness & Contrast Iterations",value=4) nBC
#@ Integer (label="Flatfield Correction Radius",value=200) flatfield
#@ Integer (label="Local Contrast Enhance Radius",value=10) lcer	
#@ Integer (label="Median Filter Radius",value=10) mfr	
#@ Integer (label="Laplacian Radius",value=10) laplRad
#@ Integer (label="Tubeness Radius",value=10) TubnessRad
#@ Integer (label="Remove Fibers Lesser Than:",value=10) minFiberSize
#@ Boolean (label="Hide Images While Running?",value=true) BatchMode
#@ Boolean (label="Test Mode?",value=false) tMode
#@ File (label="Select The Output Directory", style="directory",value="") outDir
#@ File[]  (label="Select Working Files", style="file") listOfPaths


if (tMode){listOfPaths=newArray(listOfPaths[0]);}
if (listOfPaths.length>1){setBatchMode(true);}
for (file = 0; file < listOfPaths.length; file++) {
	clearWindows("settings");
	open(listOfPaths[file]);
	showProgress(file/listOfPaths.length);
	filamentDetector(channel,saturation,flatfield,lcer,mfr,laplRad,outDir,BatchMode,minFiberSize);
	if (listOfPaths.length>1){
		run("Close All");
	}
}




function displaySettings() {
	title1 = "settings"; 
	title2 = "["+title1+"]"; 
	f=title2; 
	run("New... ", "name="+title2+" type=Table"); 
	print(f,"\\Headings:Parameter\tValue");
	print(f,"channel\t"+d2s(channel,0));
	print(f,"B&C saturation\t"+d2s(saturation,3));
	print(f,"Number of Brightness & Contrast Iterations\t"+ d2s(nBC,0));
	print(f,"Flatfield radius\t"+d2s(flatfield,0));
	print(f,"Local Contrast Enhance Radius\t"+d2s(lcer,0));
	print(f,"Median Filter Radius\t"+d2s(mfr,0));
	print(f,"Laplacian Radius\t"+d2s(laplRad,0));
	print(f,"Tubeness Radius\t"+d2s(TubnessRad,0));
	print(f,"Min Fiber Length\t"+d2s(minFiberSize,0));
	print(f,"outDir\t"+outDir);
	
}

function setOptions()
{
	run("Options...", "iterations = 1 count = 1");
	run("Colors...", "foreground=white background=black selection=yellow");
	run("Appearance...", "  antialiased menu = 0");
	run("Overlay Options...", "stroke = red width = 1 fill = none");
	setOption("BlackBackground", false);
	run("Set Measurements...", "centroid area mean standard redirect=None decimal=4");
	run("Misc...", "divide=Infinity reverse");
	run("Clear Results");
	setBackgroundColor(0, 0, 0);
	setForegroundColor(255,255,255);
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

function zProjectionMax(ID) {
	selectImage(ID);
	if (nSlices>1){
		mainName = getTitle();
		run("Z Project...", "projection=[Max Intensity]");
		newID = getImageID;
		selectImage(ID); 
		close();
		selectImage(newID);
		rename(mainName);
		ID = newID;	
	}
	return ID
}

function SaturateImage(ID,saturation,nBC,BatchMode) {
	selectImage(ID);
	run("Duplicate...", "title=workingImage");
	if (BatchMode) { setBatchMode("hide"); }
	wiID=getImageID();
	for (i = 0; i < nBC; i++) {
		run("Enhance Contrast", "saturated="+saturation);
		run("Apply LUT");	
	}
	return wiID
}

//unused - just for tests
function getRidgeSegmenteations(tubID,BatchMode) {
	setOption("ScaleConversions", true);
	run("8-bit");
	run("Select None");
	for (i = 10; i <= 25; i=i+5) {
		selectImage(tubID);
		run("Ridge Detection", "line_width="+i+" high_contrast=200 low_contrast=100 correct_position estimate_width extend_line make_binary method_for_overlap_resolution=SLOPE sigma=7.72 lower_threshold=0 upper_threshold=0.17 minimum_line_length=50 maximum=0");
		if (BatchMode) { setBatchMode("hide"); }
		rename("ridge_Detected_segments_"+i);
		run("Create Selection");
		roiManager("Add");
		roiManager("select", roiManager("count")-1);
		roiManager("rename", "ridge_"+i);
	}
}
// unused - just for tests
// run all threshold methods just for comparisons 
function tubenessSegmentations(tubID,BatchMode) {
	thresh = getList("threshold.methods");
	for (i = 0; i < thresh.length; i++) {
		tubenessSegmentation(tubID,BatchMode,thresh[i]);
	}
}

function tubenessSegmentation(tubID,BatchMode,threshMethod) {
		selectImage(tubID);
		run("Duplicate...","title=temp");
		delID = getImageID();
		if (BatchMode) { setBatchMode("hide"); }	
		setAutoThreshold(threshMethod+" dark");
		setOption("BlackBackground", false);
		run("Convert to Mask");	
		run("Create Selection");
		roiManager("Add");
		roiManager("select", roiManager("count")-1);
		roiManager("rename", threshMethod );
		selectImage(delID);
		close();
}

function roiMerge(name,minFiberSize) {
	for (i = 0; i < roiManager("count"); i++) {
		roiManager("select", i);
		run("Create Mask");
		setBatchMode("hide");
		rename("margeMask_"+i);
		if (i>=1){
			imageCalculator("OR", "margeMask_0","margeMask_"+i);
		}
	}
	run("Create Selection");
	run("Create Mask");
	rename("tmpMask");
	run("Analyze Particles...", "size="+minFiberSize+"-Infinity show=Masks");
	run("Create Selection");
	roiManager("add");
	roiManager("select", roiManager("count")-1);
	roiManager("rename", name);
	selectWindow("tmpMask"); close();
	for (i = 0; i < roiManager("count")-1; i++) {
		selectWindow("margeMask_"+i); close();
	}
}


// Main function
function filamentDetector(channel,saturation,flatfield,lcer,mfr,laplRad,outDir,BatchMode,minFiberSize){
	setOptions();
	if (nImages==1){
		getDimensions(width, height, channels, slices, frames);
		if (channels>1){
			clearWindows("");
		}else {
			clearWindows("all");
		}
	}else{
		clearWindows("");
	}
	displaySettings();

	if(nImages==0){ open(""); }
	ID = getImageID;
	mainImageName=getTitle();
	run("Select None");
	ID = zProjectionMax(ID);
	selectImage(ID);
	
	setSlice(channel);
	run("Median...","radius=1"); // just a very small filtering kernel
	wiID = SaturateImage(ID,saturation,nBC,BatchMode);


	run("Duplicate...","title=temp");
	if (BatchMode) { setBatchMode("hide"); }
	tempID = getImageID;
	for (i = 0; i < nBC; i++) {
		run("Gaussian Blur...", "sigma="+flatfield);
		imageCalculator("Divide create 32-bit", "workingImage","temp");
		if (BatchMode) { setBatchMode("hide"); }
	}
	newID = getImageID;
	selectImage(tempID); close();
	selectImage(wiID); close();
	selectImage(newID);
	rename("workingImage");
	wiID=newID;
	if(bitDepth==32){
		resetMinAndMax;
		run("16-bit");
	}
	run("Enhance Local Contrast (CLAHE)", "blocksize="+lcer+" histogram=256 maximum=3 mask=*None* fast_(less_accurate)");
	run("Median...","radius="+mfr);



	// Segment fine features
	// (no need for image duplication because FeatureJ does that)
	run("FeatureJ Laplacian", "compute smoothing="+laplRad);
	lapID = getImageID; 
	selectImage(lapID);
	if (BatchMode) { setBatchMode("hide"); }
	setAutoThreshold("IsoData");setAutoThreshold("Li");
	setOption("BlackBackground", false);
	run("Convert to Mask");
	rename("Fine");
	run("Create Selection");
	roiManager("Add");
	roiManager("select", roiManager("count")-1);
	roiManager("rename", "lapacian")
	

	//	Segment rough features
	selectImage(wiID);
	run("Duplicate...", "title=roughSegmentation");
	rID = getImageID();
	if (BatchMode) { setBatchMode("hide"); }
	setAutoThreshold("IsoData dark");setAutoThreshold("Li dark");
	run("Convert to Mask");
	rename("Rough");
	run("Create Selection");
	roiManager("Add");
	roiManager("select", roiManager("count")-1);
	roiManager("rename", "rough");
	

	// take advantage of tubeness to complement segmentation
	selectImage(wiID);
	run("Tubeness", "sigma="+TubnessRad+" ");
	if (BatchMode) { setBatchMode("hide"); }
	rename("tubness");
	tubID = getImageID();
	tubenessSegmentation(tubID,BatchMode,"Li");

	//getRidgeSegmenteations(tubID,BatchMode);
	
	selectImage(wiID);
	run("Remove Overlay");


	// Combine all rois into one
	roiMerge(mainImageName,minFiberSize);

	// outputs
	if ( !tMode ){
		if (File.exists(outDir)){
			if (File.isDirectory(outDir) ){
				selectImage(wiID);
				run("Select None");
				saveAs("Tiff", outDir+File.separator+mainImageName);
				roiManager("select", roiManager("count")-1);
				roiManager("save selected", outDir+File.separator+mainImageName+".roi");
				selectWindow("settings");
				saveAs("Text", outDir+File.separator+"settings.txt");
			}
		}else{
			print("\\Clear");
			print("===================================================================");
			print("Directory doesn't exist");
			print("nothing was saved!");
			print("===================================================================");
		}
	}else{
		selectImage(wiID);
		setBatchMode("show");
		roiManager("select", roiManager("count")-1);
	}


}
	

