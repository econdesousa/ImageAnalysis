/*

#  BIOIMAGING - INEB/i3S
Eduardo Conde-Sousa (econdesousa@gmail.com)

## particle analysis Choroid Plexus

 
 
### code version
1.0 
	
### last modification
11/08/2021

### Requirements
* imagej version 1.52a
* update sites:
	* ilastik

### Attribution:
If you use this macro please add in the acknowledgements of your papers and/or thesis (MSc and PhD) the reference to Bioimaging and the project PPBI-POCI-01-0145-FEDER-022122.
As a suggestion you may use the following sentence:
 * The authors acknowledge the support of the i3S Scientific Platform Bioimaging, member of the national infrastructure PPBI - Portuguese Platform of Bioimaging (PPBI-POCI-01-0145-FEDER-022122).

*/



/*
# initialize variables
*/
#@ File (label="Select the input tif file",style="file") inputfile
#@ File (label="Select ilastik model path",style="file") ilastikProject
#@ boolean (label="crop image around ROIs (faster with same results)?", persistant=true, value = true) is2crop
#@ Integer (value = 5, label="Enlarge ROIs by ___ pixels") nPx
#@ boolean (label="Automatic ROI name (by replacing  \"Cy5.tif\" by \"ROI.zip\")?", value = true) autoROIname
#@ boolean (label="Close all at the end?", value = true) is2Close

var width;
var height;
var voxelwidth;
var voxelheight;
var voxeldepth;
var unit;


/*
# Reset all
*/
requires("1.52a");
close("*");
roiManager("reset");
resetNonImageWindows("ROI");


/*
# open data and set up variables
*/
mainFileName=File.getNameWithoutExtension(inputfile);
inDir=File.getDirectory(inputfile);
outDir = inDir + File.separator;
File.setDefaultDir(inDir);

if (autoROIname){
	roiManager("Open", replace(inputfile,"_Cy5.tif","_ROI.zip"));
}else {
	roiname = File.openDialog("Choose ROI");
	roiManager("Open", roiname);
}
open(inputfile);
id=getImageID();
getDimensions(width, height, channels, slices, frames);
getVoxelSize(voxelwidth, voxelheight, voxeldepth, unit);
function resize(){
	if (unit == "cm") {
		unit="µm";
		voxelwidth = voxelwidth * pow(10, 4);
		voxelheight = voxelheight * pow(10, 4);
		voxeldepth = voxeldepth ;// these are single slice images. doesn't make sense change voxeldepth
	}
	setVoxelSize(voxelwidth, voxelheight, voxeldepth, unit);
}
selectImage(id);



/*
# Clean up possible ROI mistakes
*/
run("Select None");
while (roiManager("count")>3){
	roiManager("select", 0);
	roiManager("delete");
}

/*
# Rename ROIs
*/
roiManager("Select", 0);
roiManager("rename", "right");
roiManager("Select", 1);
roiManager("rename", "left");
roiManager("Select", 2);
roiManager("rename", "center");

/*
# Run ilastik
*/
selectImage(id);
if (is2crop) cropImage();
function cropImage(){
	xm=0;ym=0;
	for (i = 0; i < roiManager("count")-1; i++) {
		roiManager("select", i);
		getSelectionCoordinates(xpoints, ypoints);
		Array.getStatistics(xpoints, xmin, xmax, mean, stdDev);
		if (xmax > xm) xm=xmax;
		Array.getStatistics(ypoints, ymin, ymax, mean, stdDev);	
		if (ymax > ym) ym=ymax;
	}
	if (1.1*xm >= width) {
		xm = width;
	}else {
		xm = floor(1.1*xm);
	}
	if (1.1*ym >= height) {
		hm = height;
	}else {
		ym = floor(1.1*ym);
	}
	
	makeRectangle(0, 0, xm, ym);
	run("Crop");
}

maskID = runIlastik("mask");
function runIlastik(outname) { // ilastikProject, voxelwidth, voxelheight, voxeldepth, unit are global vars defined at begining of the code
	orig=getTitle();
	run("Run Pixel Classification Prediction", "projectfilename=["+ilastikProject+"] inputimage=["+orig+"] pixelclassificationtype=Segmentation");
	rename(outname);
	setVoxelSize(voxelwidth, voxelheight, voxeldepth, unit);
	setThreshold(0, 1.5);
	run("Convert to Mask");
	if (is("Inverting LUT")) run("Invert LUT"); 
	maskID = getImageID();
	return maskID;
}

selectImage(maskID);
intersectROIsV2();//intersectROIs();
function intersectROIsV2(){	
	run("Select None");
	getStatistics(area, mean, min, max, std, histogram);
	if (max >=1) {
		setThreshold(1, 255);
		run("Create Selection");
	}else {
		makePoint(0, 0);
	}
	roiManager("add");
	roiManager("select", roiManager("count")-1);
	roiManager("rename", "mask");
	roiMaskID = roiManager("count")-1;
	
	
	getDimensions(width, height, channels, slices, frames);
	newImage("Untitled", "8-bit black", width, height, 1);
	idUntitled = getImageID();
	
	selectImage(idUntitled);
	for (i = 0; i < roiMaskID; i++) {
			roiManager("select", i);
			run("Set...", "value=255");
			run("Select None");
			roiManager("select", roiMaskID);
			getStatistics(area, mean, min, max, std, histogram);
			if (max > 0) {
				roiManager("select", newArray(i,roiMaskID));
				roiManager("AND");
				roiManager("Update");
			}else {
				roiManager("select", i);
				getSelectionBounds(xtmp, ytmp, widthtmp, heighttmp);
				makePoint(xtmp, ytmp);
				roiManager("update");
			}
			selectImage(idUntitled);
			run("Select All");
			run("Set...", "value=0");
	}
	roiManager("deselect");
	roiManager("select", roiMaskID);
	roiManager("delete");
	run("Select None");
	selectImage(idUntitled);close();

}
function intersectROIs() { 
	run("Select None");
	setThreshold(1, 255);
	run("Create Selection");
	roiManager("add");
	//out=getBoolean("continuar", "sim", "nao");if (!out) exit("error message");	
	roiManager("select", roiManager("count")-1);
	roiManager("rename", "mask");
	roiMaskID = roiManager("count")-1;
	for (i = 0; i < roiMaskID; i++) {
		roiManager("select", newArray(i,roiMaskID));
		roiManager("AND");
		roiManager("Update");
	}
	roiManager("deselect");
	roiManager("select", roiMaskID);
	roiManager("delete");
	run("Select None");
}	
enlargeROIs(nPx);
function enlargeROIs(nPx){
	nROIs=roiManager("count");
	for (i = 0; i < nROIs; i++) {
		roiManager("select", i);
		rName=Roi.getName;
		run("Enlarge...", "enlarge="+nPx+" pixel");
		roiManager("add");
		roiManager("select", roiManager("count")-1);
		roiManager("rename", rName+"_enlaged_by_"+nPx+"_px");
		roiManager("deselect");
	}
}

/*
# Get Stats
*/
selectImage(id);
run("Set Measurements...", "area mean standard modal min centroid center perimeter bounding shape integrated median area_fraction display redirect=None decimal=9");
roiManager("Measure");

/*
# Edit results to remove single pixel ROIs
*/

selectWindow("Results");

str=Table.allHeadings;
str=split(str, "\t");


for (i = 0; i < nResults/2; i++) {
	val=getResult("Area", i);
	print(val);
	if (val < 0.00000001 ){
		for (j = 0; j < lengthOf(str); j++) {
			if (str[j]!="Label") {
				setResult(str[j],i,"0");
				setResult(str[j],i+3,"0");
			}
		}
	}
}


/*
# Save results and Close all
*/
selectWindow("Results");
saveAs("Results", outDir + mainFileName+"_"+"Results.csv");

roiManager("deselect");
roiManager("save", outDir + mainFileName+"_ROI_target_ChoroidPlexus.zip");

if (is2Close){
	resetNonImageWindows("");
	close("*");
}

/*
# Auxiliary functions
*/

function getRoiIndex(name){
	for (i = 0; i < roiManager("count"); i++) {
		roiManager("select", i);
		if (name == Roi.getName){
			return i;
		}
	}
	i=-1;
	return i;
}


function resetNonImageWindows(except){
	if (except=="") except="ksajlasfofjncsdklnxz ,mzxkjcaosjcdç.dnxX´~ OUGIAD X";

	list = getList("window.titles");
	for (i = 0; i < lengthOf(list); i++) {
		if (indexOf(list[i], except)==-1) {
			selectWindow(list[i]);run("Close");
		}
	}
}
