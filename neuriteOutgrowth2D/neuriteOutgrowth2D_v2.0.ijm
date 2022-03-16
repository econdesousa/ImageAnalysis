/*

#  BIOIMAGING - INEB/i3S
Eduardo Conde-Sousa (econdesousa@gmail.com)

## neurite outgrowth 2D

 
### code version
2.0.0
	Log 2.0.0
		ROI manager manually create and imported
		apply median filter and background subtract
	Log 1.3.0
		Possibility of measure Intensity from Signal image
		Possibility of apply median Filter to remove noise on Mask
	Log 1.2.0
		quantifications start now from a circle obtained automatically
		ROI and Segmenation images are saved by default
	Log 1.1.0
		updated to 2D
		changed to semi-automatic to increase reliability

### last modification
22/02/2022

### Requirements
* imagej version 1.53f
* update sites:
	* IJPB-plugins


### Attribution:
If you use this macro please add in the acknowledgements of your papers and/or thesis (MSc and PhD) the reference to Bioimaging and the project PPBI-POCI-01-0145-FEDER-022122.
As a suggestion you may use the following sentence:
 * The authors acknowledge the support of the i3S Scientific Platform Bioimaging, member of the national infrastructure PPBI - Portuguese Platform of Bioimaging (PPBI-POCI-01-0145-FEDER-022122).

*/



/*
 * Setup
 */
var Label			= newArray(0);
var Mean			= newArray(0);
var StdDev			= newArray(0);
var Max				= newArray(0);
var Min				= newArray(0);
var Median			= newArray(0);
var Mode			= newArray(0);
var NumberOfVoxels	= newArray(0);
var Volume			= newArray(0);
var Dist_units		= newArray(0);
var Dist_px			= newArray(0);



var nIter = 40;
var stepSize = 100;
saveTmpIm = false;

Dialog.create("Set-up");
Dialog.addNumber("Max number of rings", nIter);
Dialog.addNumber("Number of pixels between consecutive rings", stepSize);
Dialog.addCheckbox("Save Mask Image", saveTmpIm);
Dialog.show();

nIter 		= Dialog.getNumber();
stepSize 	= Dialog.getNumber();
saveTmpIm 	= Dialog.getCheckbox();

/*
 *  Clear all
 */
function resetNonImageWindows(){
	list = getList("window.titles");
	for (i = 0; i < lengthOf(list); i++) {
		selectWindow(list[i]);run("Close");
	}
}
resetNonImageWindows();

roiManager("reset");
close("*");

/*
 * Open files and filter image 
 */
imageFileName = File.openDialog("Select Signal Image");
path=File.getParent(imageFileName)+File.separator;
imName=File.getName(imageFileName);
roiFileName = File.openDialog("Select ROIs");
open(imageFileName);
signalName = getTitle();
rename("signal");
run("Despeckle");
run("Subtract Background...", "rolling=5");
roiManager("Open", roiFileName);


// Select all rois
// and create labelled mask
nRois = roiManager("count");
roiArray = newArray(nRois);
for (i = 0; i < nRois; i++) {
	roiArray[i]=i;
}
roiManager("Select", roiArray);
roiManager("Combine");
run("Make Inverse");
run("Create Mask");
id=getImageID();
run("Connected Components Labeling", "connectivity=4 type=[8 bits]");
setMinAndMax(0, 4);
run("glasbey_on_dark");
saveAs("Tiff", path+imName+"_MASKlbl.tif");
rename("MASKlbl");
getDimensions(w, h, channels, slices, frames);
getVoxelSize(width, height, depth, unit);
selectImage(id);close();
if (saveTmpIm) {
	newImage("MaskFinal", "8-bit black", w, h, nIter);
	setVoxelSize(width, height, depth, unit);
}
else {
	newImage("MaskFinal", "8-bit black", w, h, 1);
	setVoxelSize(width, height, depth, unit);
}
newImage("tmp", "8-bit black", w, h, 0);
setVoxelSize(width, height, depth, unit);


for (iter = 0; iter < nIter; iter++) {
	print(iter);
	
	selectWindow("MASKlbl");
	roiManager("Select", roiManager("count")-1);
	run("Enlarge...", "enlarge="+stepSize+" pixel");
	roiManager("add");
	run("Copy");
	selectWindow("MaskFinal");
	if (saveTmpIm) {
		Stack.setSlice(iter+1);
	}
	roiManager("Select", roiManager("count")-1);
	run("Paste");
	if (iter > 0) {
		roiManager("Select", roiManager("count")-2);
		run("Set...", "value=0");
	}
	run("Select All");
	run("Copy");
	selectWindow("tmp");
	run("Select All");
	run("Paste");
	setMinAndMax(0, 4);
	run("glasbey_on_dark");
	run("Intensity Measurements 2D/3D", "input=[signal] labels=tmp mean stddev max min median mode numberofvoxels volume");
	selectWindow("signal-intensity-measurements");
	
	tmp=Table.getColumn("Label");
	if (lengthOf(tmp)==4){
		Label=Array.concat(Label,tmp);
		
		
		tmp=Table.getColumn("Mean");
		Mean=Array.concat(Mean,tmp);
	
		tmp=Table.getColumn("StdDev");
		StdDev=Array.concat(StdDev,tmp);
		
		tmp = Table.getColumn("Max");
		Max=Array.concat(Max,tmp);
	
		tmp = Table.getColumn("Min");
		Min=Array.concat(Min,tmp);
	
		tmp=Table.getColumn("Median");
		Median=Array.concat(Median,tmp);
	
		tmp = Table.getColumn("Mode");
		Mode=Array.concat(Mode,tmp);
	
		tmp = Table.getColumn("NumberOfVoxels");
		NumberOfVoxels=Array.concat(NumberOfVoxels,tmp);
	
		tmp = Table.getColumn("Volume");
		Volume=Array.concat(Volume,tmp);

		for (ct = 0; ct < 4; ct++) {
			Dist_px		=Array.concat(Dist_px, stepSize * iter);
			Dist_units	=Array.concat(Dist_units, width * stepSize * iter);
		}
		

	}else {
		break;
	}
}
selectWindow("tmp");close();

if (saveTmpIm) {
	
	selectWindow("MaskFinal");
	run("Select None");
	selectWindow("MaskFinal");
	setMinAndMax(0, 4);
	run("glasbey_on_dark");
	for (i = nIter; i > iter; i--) {
		Stack.setSlice(i);run("Delete Slice");
	}
	
	saveAs("Tiff", path+imName+"_MASKlbl_iter.tif");
}

Array.show("Results", Label, Dist_px, Dist_units, Mean, StdDev, Max, Min, Median, Mode, NumberOfVoxels, Volume);
saveAs("Results", path+imName+"_results.csv");
selectWindow("Log");
run("Close");
resetNonImageWindows();
close("*");
print("DONE!");











