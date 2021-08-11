/*

#  BIOIMAGING - INEB/i3S
Eduardo Conde-Sousa (econdesousa@gmail.com)

## particle analysis inside stroke

* intersect sroke with cortex
* symetry across manually create line (dividing brain hemispheres)
* segmentation with ilastik
* computations
 
 
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
#@ boolean (label="Automatic ROI name (by replacing  \"Cy5.tif\" by \"ROI.zip\")?", value = false) autoROIname
#@ boolean (label="keep all ROIs (debug mode)?", value = false) keepROIs

var xpoints;
var ypoints;
var selectionXpoints;
var selectionXpoints;
var width;
var height;
var m;
var b;
var infTh = 1000000;


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
lineROI = 1;
refletionROI = 0;
selectImage(id);

/*
# Rename ROIs
*/
roiManager("Select", 0);
roiManager("rename", "stroke");
roiManager("Select", 1);
roiManager("rename", "line");
roiManager("Select", 2);
roiManager("rename", "right_cortex");
roiManager("Select", 3);
roiManager("rename", "left_cortex");
roiManager("UseNames", "true");

/*
# Clean up possible ROI mistakes
*/
run("Select None");
while (roiManager("count")>4){
	roiManager("select", 4);
	roiManager("delete");
}

/*
# Merge left and right ROI
*/
roiManager("Select", newArray(2 ,3));
roiManager("combine");
roiManager("add");
roiManager("select", 4);
roiManager("rename", "all");

/*
# reflect stroke ROI
*/

reflectTargetROI(lineROI, refletionROI);

function reflectTargetROI(lineROI, refletionROI){
	line=getReflectionLine(lineROI);
	roiManager("select", refletionROI);
	getSelectionCoordinates(selectionXpoints, selectionYpoints);
	
	outputXpoints=newArray(lengthOf(selectionXpoints));
	outputYpoints=newArray(lengthOf(selectionYpoints));

	for (pt = 0; pt < lengthOf(selectionXpoints); pt++) {
		originalPointX=selectionXpoints[pt];
		originalPointY=selectionYpoints[pt];
		secPoint=getPerpendicularIntersect(originalPointX,originalPointY,line,xpoints,ypoints);
		reflectVec = newArray(2);
		reflectVec[0] = secPoint[0]-originalPointX;
		reflectVec[1] = secPoint[1]-originalPointY;
		translatedPoint=newArray(2);
		translatedPoint[0]=originalPointX+2*reflectVec[0];
		translatedPoint[1]=originalPointY+2*reflectVec[1];
		outputXpoints[pt] = translatedPoint[0];
		outputYpoints[pt] = translatedPoint[1];
	}
	makeSelection(1,outputXpoints,outputYpoints);
	roiManager("add");
	roiManager("select", refletionROI);
	name=Roi.getName;
	roiManager("select", roiManager("count")-1);
	roiManager("rename", name+"_reflection");
	roiManager("show all");
}

function getReflectionLine(lineROI) { 

	roiManager("select", lineROI);
	getDimensions(width, height, channels, slices, frames);
	getSelectionCoordinates(xpoints, ypoints);
	m=(ypoints[1]-ypoints[0]) / (xpoints[1] - xpoints[0]);
	selectImage(id);
	
	if (m==0) { 			// horizontal line
		b=ypoints[0];
	}else {     
		if (m>infTh) {		// vertical line
			b=infTh;
		}else {				// diagonal line
			b=ypoints[1]-m*xpoints[1];
		}
	}
	out=newArray(2);
	out[0]=m;
	out[1]=b;
	return out;
}

function getPerpendicularIntersect(originalPointX,originalPointY,line,xpoints,ypoints) { 
	m=line[0];
	b=line[1];
	if (m == 0) { 			// horizontal line
		x=originalPointX; // same x
		y=line[1];		// y=b
	}else {
		if (abs(m) > infTh) { 	// vertical line
			x=xpoints[0];
			y=originalPointY;	
		}else {
			m1= -1/m;
			b1= originalPointY - (m1 * originalPointX);
			x=(b  - b1)/(m1 - m);
			y=m1*x+b1;
		}
	}
	out=newArray(2);
	out[0]=x;
	out[1]=y;
	return out;
}

/*
# Intersections
(between stroke and right cortex and between stroke_mirror and left cortex)
*/

roiIntersect("stroke","all", "stroke_in",keepROIs);
roiIntersect("stroke_reflection","all", "stroke_mirror_in",keepROIs);


function roiIntersect(roi1Name, roi2Name,name,is2keep){
	roi1=getRoiIndex(roi1Name);
	roi2=getRoiIndex(roi2Name);
	n=roiManager("count");
	roiManager("Select", newArray(roi1,roi2));
	roiManager("AND");
	roiManager("add");
	roiManager("select", n);
	roiManager("rename", name);
	if (!is2keep){
		roiManager("select", roi1);
		roiManager("delete");
	}
}

/*
# Clean Up unnecessary ROIs
*/
cleanUp(keepROIs);
function cleanUp(keepROIs){
	if (!keepROIs) {
		roiManager("select", getRoiIndex("line"));
		roiManager("delete");
		
		roiManager("select", getRoiIndex("all"));
		roiManager("delete");
	}
}

if (keepROIs) {
	exit("code interrupted to check ROIS");
}

/*
# Run ilastik
*/
selectImage(id);
orig=getTitle();
run("Run Pixel Classification Prediction", "projectfilename=["+ilastikProject+"] inputimage=["+orig+"] pixelclassificationtype=Segmentation");
maskID = getImageID();
rename("mask");
run("Subtract...", "value=1");
setVoxelSize(voxelwidth, voxelheight, voxeldepth, unit);
imageCalculator("Multiply 32-bit", "mask",orig);
origFilteredID=getImageID();
origFilteredName=getTitle();
setVoxelSize(voxelwidth, voxelheight, voxeldepth, unit);

/*
# Get Stats
*/
run("Set Measurements...", "area mean min centroid integrated median display redirect=None decimal=9");
selectImage(maskID);
roiManager("Measure");
Label=Table.getColumn("Label");
for (i = 0; i < lengthOf(Label); i++) {
	Label[i]=replace(Label[i], "mask:", "");
}

Area=Table.getColumn("Area"); // area of the ROI
nPixels = Table.getColumn("RawIntDen"); // number of Segmented Pixels
for (i = 0; i < lengthOf(nPixels); i++) {
	nPixels[i]=floor(nPixels[i]);
}

intDen = Table.getColumn("IntDen"); // area of the segmented pixels

AreaFraction=newArray(lengthOf(intDen)); // proportion of segmented pixels per ROI
for (i = 0; i < lengthOf(intDen); i++) {
	AreaFraction[i]=100*intDen[i]/Area[i];
}

selectWindow("Results");
run("Clear Results");
selectImage(origFilteredID);
roiManager("Measure");
selectWindow("Results");
rawIntDen = Table.getColumn("RawIntDen");
for (i = 0; i < lengthOf(rawIntDen); i++) {
	rawIntDen[i]=floor(rawIntDen[i]);
}
intDen_v2 = Table.getColumn("IntDen");
run("Clear Results");

selectImage(maskID);
setThreshold(1, pow(2, bitDepth() )-1);
run("Convert to Mask");
run("Set Measurements...", "area mean min centroid integrated median display redirect=["+orig+"] decimal=9");
for (i = 0; i < roiManager("count"); i++) {
	selectImage(maskID);
	run("Select None");
	roiManager("select", i);
	run("Analyze Particles...", "display summarize");	
}
run("Set Measurements...", "area mean min centroid integrated median display redirect=None decimal=9");
selectWindow("Summary");
AverageSize = Table.getColumn("Average Size");
Count = Table.getColumn("Count");


Table.create("final results");
Table.setColumn("Label", Label);
Table.setColumn("Count", Count);
Table.setColumn("AreaSegmentation[squareUnits]", intDen);
Table.setColumn("RegionArea[squareUnits]", Area);
Table.setColumn("AreaFraction[%]", AreaFraction);
Table.setColumn("NumbPositivePixels", nPixels);

Table.setColumn("RawIntDen", rawIntDen);
Table.setColumn("IntDen", intDen_v2);
Table.setColumn("AverageSize[squareUnits]", AverageSize);


/*
# Save results and Close all
*/

selectWindow("Results");
saveAs("Results", outDir + mainFileName+"_"+"ParticlesResults.csv");

selectWindow("Summary");
run("Close");

selectWindow("final results");
saveAs("Results", outDir + mainFileName+"_"+"Results.csv");

resetNonImageWindows("");

close("*");



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
