


#  BIOIMAGING - INEB/i3S
Eduardo Conde-Sousa (econdesousa@gmail.com)

## Cell density assessement

* 3D cell segmentation from DAPI channel using ilastik pixel classification workflow
* Cell type evaluated from other channels
* output
	* Cell density map (DAPI) 
	* Cell density map (other markers)
 
### code version
0.1

### last modification
24/03/2021 at 16:03:16 (GMT)

### Attribution:
If you use this macro please add in the acknowledgements of your papers and/or thesis (MSc and PhD) the reference to Bioimaging and the project PPBI-POCI-01-0145-FEDER-022122.
As a suggestion you may use the following sentence:
 * The authors acknowledge the support of the i3S Scientific Platform Bioimaging, member of the national infrastructure PPBI - Portuguese Platform of Bioimaging (PPBI-POCI-01-0145-FEDER-022122).


```java

```

# setup

```java

var inputfile="C:/Users/ecsso/Dropbox/PostDoc/INEB/colaboracoes/20210204_RitaSantos_Perpetua/data/Quantificações IFs_Rita Santos/CD45 (verde) canal 0 ou 1_ CD19 (vermelho) canal 1 ou 2_ Núcleos (cinzento) canal 2 ou 3/E18.5/tmp.lif"
//"C:/Users/ecsso/Dropbox/PostDoc/INEB/colaboracoes/20210204_RitaSantos_Perpetua/data/tiffs/DAPI/series_2_tmp.tif"
var modelPath="C:/Users/ecsso/Dropbox/PostDoc/INEB/colaboracoes/20210204_RitaSantos_Perpetua/macro/ilastik/DAPI.ilp";
var smallTh=0.5;
var largeTh=0.9;
var smoothScale = 1;
var series = 1;
var x1 = 12;var y1 = 662;var width1 = 888;var height1 = 362;
var isReg2Crop=false;
inputfile = replace(inputfile, "series_2", "series_"+series);
run("CLIJ2 Macro Extensions", "cl_device=[]");
Ext.CLIJ2_clear();
close("*");
resetNonImageWindows();
run("Record...");

```

# load data original data

```java

setBatchMode(true);
run("Bio-Formats Importer", "open=["+inputfile+"] color_mode=Colorized rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT series_"+series);
origID=getImageID();
run("Duplicate...", "title=CD45 duplicate channels=2");
setBatchMode("show");
setMinAndMax(0, 5000);
run("Green");
selectImage(origID);
run("Duplicate...", "title=CD19 duplicate channels=3");
setBatchMode("show");
setMinAndMax(0, 5000);
run("Red");
selectImage(origID);
run("Duplicate...", "title=DAPI duplicate channels=4");
selectImage(origID);close();
selectWindow("DAPI");
setBatchMode(false);

if (isReg2Crop) cropRegion(x1, y1, width1, height1);
dapiID=getImageID();

```
<a href="image_1618414979548.png"><img src="image_1618414979548.png" width="250" alt="CD45"/></a>
<a href="image_1618414981789.png"><img src="image_1618414981789.png" width="250" alt="CD19"/></a>
<a href="image_1618414983352.png"><img src="image_1618414983352.png" width="250" alt="DAPI"/></a>

# Threshold intensity data
DAPI channel is kept as is while other channels are thresholded (after smoothing)

```java
selectWindow("CD45");
run("Gaussian Blur 3D...", "x=3 y=3 z=3");
stackThresh("Otsu dark");
selectWindow("CD19");
run("Gaussian Blur 3D...", "x=3 y=3 z=3");
stackThresh("Otsu dark");


```
<a href="image_1618414985391.png"><img src="image_1618414985391.png" width="250" alt="CD45"/></a>
<a href="image_1618414985715.png"><img src="image_1618414985715.png" width="250" alt="CD19"/></a>

# Predictions (from Ilastik)
1. Create Prediction 
2. Get only channel of interest 
3. Filter

```java
run("Run Pixel Classification Prediction", "projectfilename="+modelPath+" inputimage=DAPI pixelclassificationtype=Probabilities");
//inputfileH5=substring(inputfile, 0,lastIndexOf(inputfile, "tif"))+"h5";
//run("Import HDF5", "select="+inputfileH5+" datasetname=/exported_data axisorder=zyxc");
if (isReg2Crop) cropRegion(x1, y1, width1, height1);

predID=getImageID();
selectImage(predID);run("Duplicate...", "title=maskRestrict duplicate channels=1");
maskRestrictID=getImageID();
selectImage(predID);close();
selectImage(dapiID);
getVoxelSize(width, height, depth, unit);
selectImage(maskRestrictID);
setVoxelSize(width, height, depth, unit);
run("Gaussian Blur 3D...", "x="+smoothScale+" y="+smoothScale+" z="+smoothScale);

```
<a href="image_1618415067786.png"><img src="image_1618415067786.png" width="250" alt="maskRestrict"/></a>

# Prediction masks
Method: hysteresis threshold with two thresholds
 * smallTh to generate maskRough
 * largeTh to generate maskRestrict

```java
selectImage(maskRestrictID);
run("Duplicate...", "title=maskRough duplicate");
maskRoughID=getImageID();

getMask(maskRoughID,smallTh, 1);
getMask(maskRestrictID, largeTh, 1);


```
<a href="image_1618415069520.png"><img src="image_1618415069520.png" width="250" alt="maskRestrict"/></a>
<a href="image_1618415069906.png"><img src="image_1618415069906.png" width="250" alt="maskRough"/></a>

# Marker Controlled Watershed
1. get inverted version of main image
2. Apply MorpholibJ's Marker-controlled Watershed 

```java
selectImage(dapiID);run("Duplicate...", "title=inverted duplicate channels=1");
selectWindow("inverted");
invertedID=getImageID();
run("Invert", "stack");
selectImage(dapiID);

label_map = "labeledImage";
run("Marker-controlled Watershed", "input=inverted marker=maskRestrict mask=maskRough binary calculate use");
rename(label_map);
run("glasbey_on_dark");
selectImage(maskRestrictID);close();
selectImage(maskRoughID);close();
selectImage(invertedID);close();



```
<pre>
> -> Compute marker labels
> -> Running watershed...
>   Extracting voxel values...
>   Extraction took 1369 ms.
>   Flooding from 1048299 voxels...
>   Flooding took: 6694 ms
> Watershed 3d took 9210 ms.
</pre>
<a href="image_1618415081815.png"><img src="image_1618415081815.png" width="250" alt="labeledImage"/></a>

# averageDistance

```java

Ext.CLIJ2_push(label_map);


//averageDistance(label_map,"labels_distance_",1,"Fire",false);
averageDistance(label_map,"labels_distance_",3,"Fire",false);
//averageDistance(label_map,"labels_distance_",9,"Fire",false);

```
<a href="image_1618415084457.png"><img src="image_1618415084457.png" width="250" alt="labeledImage"/></a>
<a href="image_1618415084979.png"><img src="image_1618415084979.png" width="250" alt="labels_distance_3"/></a>

# group cell by positivity at channel x

```java

cd45 = "CD45";
Ext.CLIJ2_push(cd45);
cd19 = "CD19";
Ext.CLIJ2_push(cd19);
number_of_dilations = 6;
threshold=0.1;


cd45PosCells="cd45PosCells";
cd19PosCells="cd19PosCells";

getPosNuc(cd45,label_map,number_of_dilations,threshold,cd45PosCells);
getPosNuc(cd19,label_map,number_of_dilations,threshold,cd19PosCells);



```
<a href="image_1618415089791.png"><img src="image_1618415089791.png" width="250" alt="CD45"/></a>
<a href="image_1618415090258.png"><img src="image_1618415090258.png" width="250" alt="CD19"/></a>
<a href="image_1618415090427.png"><img src="image_1618415090427.png" width="250" alt="ExtendedSpotsAfter_6_dilations"/></a>
<a href="image_1618415090861.png"><img src="image_1618415090861.png" width="250" alt="cd45PosCells"/></a>
<a href="image_1618415091218.png"><img src="image_1618415091218.png" width="250" alt="ExtendedSpotsAfter_6_dilations"/></a>
<a href="image_1618415091420.png"><img src="image_1618415091420.png" width="250" alt="cd19PosCells"/></a>

# clean up garbage

```java


//drawResult(label_map, dataVector,"dataVector");
//drawResult(label_map, aboveThreshMask,"aboveThreshMask");

run("Tile");


Ext.CLIJ2_clear();
run("Synchronize Windows");




```

# Convinient methods

```java

function resetNonImageWindows(){
	list = getList("window.titles");
	for (i = 0; i < lengthOf(list); i++) {
		selectWindow(list[i]);run("Close");
	}
}

function show(input, text) {
	selectWindow(input);
	run("Duplicate...", "title=max_projection duplicate channels=4");
	run("Z Project...", "projection=[Max Intensity]");
	setColor(pow(2,bitDepth())-1);
	drawString(text, 20, 20);
}
function showCLIJ(input, text) {
	Ext.CLIJ2_maximumZProjection(input, max_projection);
	Ext.CLIJ2_pull(max_projection);
	setColor(pow(2,bitDepth())-1);
	drawString(text, 20, 20);
	Ext.CLIJ2_release(max_projection);
}

function cropRegion(x, y, w, h){
	makeRectangle(x, y, w, h);
	run("Crop");
}


function getMask(id, th1,th2) { 
	selectImage(id);
	setThreshold(th1, th2);
	run("Convert to Mask", "stack");
	if (is("Inverting LUT")) {
		run("Invert LUT");
	}
	run("Fill Holes", "stack");
}


function averageDistance(inputImage,outputName,nNeig,LUT,CalibrationBar){
	outputImage=outputName+nNeig;
	Ext.CLIJx_averageDistanceOfNClosestNeighborsMap(label_map, outputImage, nNeig);
	Ext.CLIJ2_pull(outputImage);
	Ext.CLIJ2_release(outputImage);
	run(LUT);
	if (CalibrationBar){
		run("Calibration Bar...", "location=[Upper Right] fill=White label=Black number=5 decimal=0 font=12 zoom=1 overlay");
	}
}

function stackThresh(method) { 
	setAutoThreshold(method+" stack");
	setOption("BlackBackground", true);
	run("Convert to Mask", "method=Otsu background=Dark black");
}


function labelDilation(imageIN,nDilations,is2pull,keepOnGPU) { 
	Ext.CLIJ2_copy(imageIN, flip);
	for (i = 0; i < floor(nDilations/2); i++) {
		Ext.CLIJ2_onlyzeroOverwriteMaximumDiamond(flip, flop);
		Ext.CLIJ2_onlyzeroOverwriteMaximumDiamond(flop, flip);
	}
	if (floor(nDilations/2)*2<nDilations){
		Ext.CLIJ2_onlyzeroOverwriteMaximumDiamond(flip, flop);
		Ext.CLIJ2_copy(flop, flip);
	}
	if (is2pull){
		Ext.CLIJ2_pull(flip);
		nameExtended="ExtendedSpotsAfter_" + (i * 2) + "_dilations";
		rename(nameExtended);
		run("glasbey_on_dark");
	}
	Ext.CLIJ2_release(flop);
	if (keepOnGPU){
		return flip;
	}else {
		Ext.CLIJ2_release(flip);
		return 0;
	}
}



function drawResult(label_map, measurement,outName) {
	// replace label in the label map with corresponding measurements
	Ext.CLIJ2_replaceIntensities(label_map, measurement, outName);
	// show the parametric image
	Ext.CLIJ2_pull(outName);
	run("Fire");
}



// This function takes a vector, binarizes it by thresholding 
// and visualizes the results as regions of interests:
function above_bellow_threshold_vector(vector, labelmap, threshold) {

	// threshold the vector in two vectors:
	Ext.CLIJ2_smallerConstant(vector, bellowThresh, threshold);
	Ext.CLIJ2_greaterOrEqualConstant(vector, aboveThresh, threshold);

	bellowThresh_map="bellowThresh";
	aboveThresh_map="aboveThresh";
	// visualise resulting binary images
	Ext.CLIJ2_replaceIntensities(labelmap, bellowThresh, bellowThresh_map);
	Ext.CLIJ2_replaceIntensities(labelmap, aboveThresh, aboveThresh_map);

	Ext.CLIJ2_pull(bellowThresh_map);
	Ext.CLIJ2_pull(aboveThresh_map);

}



function getPosNuc(markerImage,label_map,number_of_dilations,threshold,aboveThreshMask) {

	dataVector="MEAN_INTENSITY";
	
	
	dilatedMask = labelDilation(markerImage,number_of_dilations,true,true);
	Ext.CLIJ2_statisticsOfBackgroundAndLabelledPixels(dilatedMask, label_map);
	setResult(dataVector, 0, 0);//remove signal outside cells
	
	Ext.CLIJ2_pushResultsTableColumn(dataVector, dataVector);
	selectWindow("Results");run("Close");

	Ext.CLIJ2_replaceIntensities(label_map, dataVector, aboveThreshMask);
	Ext.CLIJ2_pull(aboveThreshMask);aboveThreshMask="aboveThreshMask";
	setThreshold(threshold, pow(2,bitDepth())-1 );
	setOption("BlackBackground", true);
	run("Convert to Mask", "method=Default background=Dark black");
}
```



```
```
