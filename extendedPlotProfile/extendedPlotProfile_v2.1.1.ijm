/*

#  BIOIMAGING - INEB/i3S
Eduardo Conde-Sousa (econdesousa@gmail.com)

## Extended Plot Profile

* Runs over all ROIs and get point coordinates
* For each it expands in 3D (image units) and add to 3d manager
* at the end it gets 3d quantif
 
 
### code version
2.1.1

	
### last modification
16/11/2021

### Requirements
* update sites (see https://imagej.net/plugins/morpholibj#installation):
	* IJPB-plugins
	* CLIJ2 (see also requirements for CLIJ)
	


### Attribution:
If you use this macro please add in the acknowledgements of your papers and/or thesis (MSc and PhD) the reference to Bioimaging and the project PPBI-POCI-01-0145-FEDER-022122.
As a suggestion you may use the following sentence:
 * The authors acknowledge the support of the i3S Scientific Platform Bioimaging, member of the national infrastructure PPBI - Portuguese Platform of Bioimaging (PPBI-POCI-01-0145-FEDER-022122).

please cite:
* this macro: https://doi.org/10.5281/zenodo.5706212
* SNT: https://www.nature.com/articles/s41592-021-01105-7
* CLIJ https://www.nature.com/articles/s41592-019-0650-1

*/

#@ Integer (label="Quantif channel:",value=1) quantifChannel
#@ float (value=5.0 , style="scroll bar", min=0, max=5, stepSize=0.1, label="neurite radius (in microns)", persist=true) nRadius
#@ boolean (label="downsample ROIs (NOT RECOMMENDED)") minDistFlag
#@ boolean (label="batchMode") batchModeFlag



/*
# Setup
*/

if (batchModeFlag) {
	setBatchMode(true);
}else {
	setBatchMode(false);
}

// if mindistRadius != 0 the a downsample will be applied
// to all points in ROIs
// here we select the minimum distance between two consecutive points

mindistRadius = 0;
if (minDistFlag) {
	mindistRadius = getNumber("distance between adjacent ROI points to consider", nRadius);
}


// if one image is open, check if it is the correct
// otherwise, close all and ask for a new image
if (nImages!=1){
	close("*");
	filePath = File.openDialog("open image");
	open(filePath);
	main = getTitle();
	dir=getDirectory("image");

}else {
	main = getTitle();
	dir=getDirectory("image");
	continueFlag = getBoolean("input image:\n" + main+"\nproceed ?");
	if (!continueFlag){
		exit("stopped by user");
	}
}


// if ROI manager already open and filled continue, otherwise ask for ROIs
if (roiManager("count")<1){
	roiPath = File.openDialog("open ROI");
	roiManager("open", roiPath);
}


// reset results table (if open)
resetResults();
function resetResults(){
	list = getList("window.titles");
	for (i = 0; i < lengthOf(list); i++) {
		if (indexOf(list[i],"Results")>=0) {
			selectWindow(list[i]);run("Close");
		}
	}
}


// get image name and duplicate the target channel
mainName=substring(main, 0,lastIndexOf(main, "."));
run("Duplicate...", "title="+mainName+" duplicate channels="+quantifChannel);
id=getImageID();


// Set output directory to a (new) folder named Results/IMAGENAME
outDir=dir+"results"+File.separator;
if (!File.exists(outDir)) {
	File.makeDirectory(outDir);
}
outDir=outDir + mainName + File.separator;
if (!File.exists(outDir)) {
	File.makeDirectory(outDir);
}


// voxel size
var width;
var height;
var depth; 		// original depth
var newDepth;	// depth after reslicing
var unit;
getVoxelSize(width, height, depth, unit);
// report parameters
print("\\Clear");
print("Quantif channel:",quantifChannel);
print("neurite radius (in "+unit+")", nRadius);
print("minimum distance between ROI points (in "+unit+")",mindistRadius);


// Each point of the ROIs (or downsample of it)
// will be enlarged by a fixed radius
// here we set the value in voxels from
// the user input in physical units
dilationNumber = nRadius / width;
print("neurite radius (in voxels)", dilationNumber);


/*
# check image dimensions
*/
var w;
var h;
var c;
var s;
var f;
Stack.getDimensions(w, h, c, s, f);
if (c>1 || f > 1){
	exit("Not prepared to deal with multiple time frames or channels");
}


/*
# Get roi(s) coordinates
*/
var xvec = newArray(); 		// these vectors will store ROI coordinates in voxel units
var yvec = newArray(); 
var zvec = newArray();
var xvecUnits = newArray(); // these vectors will store ROI coordinates in physical units
var	yvecUnits = newArray();
var	zvecUnits = newArray();

for (i = 0; i < roiManager("count"); i++) {
	selectImage(id);
	getVoxelSize(width, height, depth, unit);
	roiManager("select", i);
	Stack.getPosition(channel, slice, frame);
	getSelectionCoordinates(xpoints, ypoints);
	xvec = Array.concat(xvec,xpoints);
	yvec = Array.concat(yvec,ypoints);
	for (j = 0; j < lengthOf(xpoints); j++) {
		zvec = Array.concat(zvec,slice);
	}
}

/*
# create label image from ROI coords 
*/

label="label";
resliceImage(label,mainName);

function resliceImage(label,mainName){

	resliceFlag = false;
	if (abs(width/depth-1)>0.1 ) { // more than 10% difference between voxel width and depth
		resliceFlag = true;
	}

	if (resliceFlag) {
		newImage(label+"_garbage", "32-bit black", w, h, s);
		setVoxelSize(width, height, depth, unit);
		run("Reslice Z", "new="+width);
		rename(label);
		labelID=getImageID();
		selectWindow(label+"_garbage");
		close();	
		selectImage(labelID);
		for (iter = 0; iter < lengthOf(zvec); iter++) {
			zvec[iter] = round(zvec[iter] * depth / width -2 ); // rescale zvec to the new image size
		}
		selectWindow(mainName);rename(mainName+"_originalSize");
		id2close=getImageID();
		run("Reslice Z", "new="+width);
		rename(mainName);
		selectImage(id2close);close();
		selectWindow(mainName);
	}else {
		newImage(label, "32-bit black", w, h, s);
		setVoxelSize(width, height, depth, unit);
	}	
	getVoxelSize(width, height, newDepth, unit);
}


/*
# Rescale coords vectors
*/
scaleVecsImageUnits(xvec,yvec,zvec);
function scaleVecsImageUnits(xvec,yvec,zvec){
	xvecUnits = Array.copy(xvec);
	yvecUnits = Array.copy(yvec);
	zvecUnits = Array.copy(zvec);
	for (i = 0; i < lengthOf(xvecUnits); i++) {
		xvecUnits[i] = xvecUnits[i] * width;
		yvecUnits[i] = yvecUnits[i] * height;
		zvecUnits[i] = (zvecUnits[i]-1) * newDepth;
	}
}

/*
# get points indexes according to distance
*/

// only indexes of points separated by nRadius will be kept

vec = getDistanceConstrain(xvecUnits,yvecUnits,zvecUnits,mindistRadius);

function getDistanceConstrain(X,Y,Z,thresholdDist){
	vec=newArray(1);
	vec[0]= 0;
	ptx=X[0];
	pty=Y[0];
	ptz=Z[0];	
	for (i = 1; i < lengthOf(X); i++) {	
		sq1=pow(X[i]-ptx,2);
		sq2=pow(Y[i]-pty,2);
		sq3=pow(Z[i]-ptz,2);
		dist=sqrt(sq1+sq2+sq3);
		if (dist >= thresholdDist) {
			vec= Array.concat(vec,i);
			ptx=X[i];
			pty=Y[i];
			ptz=Z[i];
		}
	}
	return vec;
}

/*
# fill labels
*/
fillLabels(label,xvec,yvec,zvec,vec);
 
function fillLabels(label,xvec,yvec,zvec,vec) {

	selectWindow(label);
	

	for (i = 0; i < lengthOf(vec); i++) {
		Stack.setSlice(round(zvec[vec[i]]  ));
		makeOval(xvec[vec[i]], yvec[vec[i]], 1, 1);
		j=i+1;
		run("Set...","value="+j);
	}

	setMinAndMax(0, j);
	run("glasbey_on_dark");
}

// Get centroids and distance between centrois
run("Analyze Regions 3D", "centroid surface_area_method=[Crofton (13 dirs.)] euler_connectivity=26");
X=Table.getColumn("Centroid.X");
Y=Table.getColumn("Centroid.Y");
Z=Table.getColumn("Centroid.Z");
Table.rename("CENTROIDS");
selectWindow("CENTROIDS");run("Close");


/*
# Dilate Labels
*/

dilateLabelsCLIJ(label, dilationNumber);

function dilateLabelsCLIJ(label, dilationNumber) { 

	run("CLIJ2 Macro Extensions", "cl_device=[]");
	selectWindow(label);
	getVoxelSize(width, height, newDepth, unit);
	run("Select None");
	Ext.CLIJ2_push(label);
	//close();
	output = label+"Dilated";
	Ext.CLIJ2_dilateLabels(label, output, dilationNumber);
	Ext.CLIJ2_getMaximumOfAllPixels(label, j);
	Ext.CLIJ2_pull(output);
	setMinAndMax(0, j);
	run("glasbey_on_dark");
	Ext.CLIJ2_release(label);
	Ext.CLIJ2_release(output);
	Ext.CLIJ2_release(j);
	setVoxelSize(width, height, newDepth, unit);
}



/*
# Quantifications
*/

// measure 3D distance between consecutive points
dist = getDistance(X,Y,Z);

function getDistance(xvec,yvec,zvec){
	vec=newArray(lengthOf(xvec));
	vec[0]= 0;
	for (i = 1; i < lengthOf(vec); i++) {	
		sq1=pow(xvec[i]-xvec[i-1],2);
		sq2=pow(yvec[i]-yvec[i-1],2);
		sq3=pow(zvec[i]-zvec[i-1],2);
		vec[i]=sqrt(sq1+sq2+sq3);
	}
	return vec;
}

// Intensity Measurements
run("Intensity Measurements 2D/3D", "input="+mainName+" labels="+label+"Dilated"+" mean stddev max min median mode skewness volume");
Table.rename("Results");


// Complete Results table with centrois & distance info
selectWindow("Results");
Table.setColumn("X", X);
Table.setColumn("Y", Y);
Table.setColumn("Z", Z);
Table.setColumn("SpaceBetweenPoints", dist);
cumdist=newArray(lengthOf(dist));
for (i = 1; i < lengthOf(cumdist); i++) {
	cumdist[i]=cumdist[i-1]+dist[i];
}
selectWindow("Results");
Table.setColumn("NeuriteLength", cumdist);
selectWindow("Results");
meanIntensity=Table.getColumn("Mean");


/*
# Create and save an extended plot profile
*/

// Add a column with a sliding window average to results table
// sliding window size must be odd and no more than 10% of nResults
vecSmooth = resultsSlidingWindow("Mean",50);
function resultsSlidingWindow(colName,filterSize) {
	selectWindow("Results");
	N=nResults;
	if (filterSize>0.1*nResults) {
		filterSize=floor(0.1*nResults);
	}
	if (floor(filterSize/2)==filterSize/2){
		if (filterSize>2) {
			filterSize = filterSize - 1;
		}else {
			filterSize = filterSize + 1;
		}
	}



	vec=Table.getColumn(colName);
	vecSmooth=newArray(lengthOf(vec));
	appPRE=newArray((filterSize-1)/2);
	for (i = 0; i < lengthOf(appPRE); i++) {
		appPRE[i]=vec[0];
	}
	appPOST=newArray((filterSize-1)/2);
	for (i = 0; i < lengthOf(appPOST); i++) {
		appPOST[i]=vec[lengthOf(vec)-1];
	}
	vecApp=Array.concat(appPRE,vec, appPOST);
	for (st=0; st<lengthOf(vec); st++){
		v=Array.slice(vecApp,st,st+filterSize);
		Array.getStatistics(v, min, max, mean, stdDev);
		vecSmooth[st]=mean;
	}
	
	Table.setColumn(colName+"_slidingWindow_"+filterSize, vecSmooth);
	return vecSmooth;
}



// Create a plot profile
Plot.create("Extended plot profile", "length (" + unit +")", "Mean", cumdist, meanIntensity);
Plot.setColor("blue");
Plot.setLineWidth(2);
Plot.add("line", cumdist, vecSmooth );
Plot.setColor("black");

Plot.show();

/*
# Save Results
*/

// Save plot profile
saveAs("PNG", outDir+"profileExtended_ch"+quantifChannel+"_dist"+IJ.pad(mindistRadius, 2)+"_NeuriteRadius"+IJ.pad(nRadius, 2)+".png");





// Save Results table
selectWindow("Results");
Table.save(outDir +"Results_ch"+quantifChannel+"_dist"+IJ.pad(mindistRadius, 2)+"_NeuriteRadius"+IJ.pad(nRadius, 2)+".tsv");
Table.rename("Results");
if (batchModeFlag) run("Close");

// push Log window to front
// to let user know the code is DONE
theText = getInfo("log");
String.copy(theText);
selectWindow("Log");run("Close");
print("input file:");
print(dir+main);
print("");
print(theText);
print("Results saved at:");
print(outDir);
print("");
print("DONE!");


