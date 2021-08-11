


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


**NOTE**: the images below have a small pixel range, so they are apparently black

# initialize variables

```java

var xpoints;
var ypoints;
var selectionXpoints;
var selectionXpoints;
var width;
var height;
var m;
var b;
var infTh = 1000000;
```

# Reset all

```java
requires("1.52a");
close("*");
roiManager("reset");
resetNonImageWindows("ROI");
```

# open data and set up variables

```java
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

```
<a href="image_1628692691635.png"><img src="image_1628692691635.png" width="250" alt="160_Cy5.tif"/></a>

# Rename ROIs

```java
roiManager("Select", 0);
roiManager("rename", "stroke");
roiManager("Select", 1);
roiManager("rename", "line");
roiManager("Select", 2);
roiManager("rename", "right_cortex");
roiManager("Select", 3);
roiManager("rename", "left_cortex");
roiManager("UseNames", "true");

```

# Clean up possible ROI mistakes

```java
run("Select None");
while (roiManager("count")>4){
	roiManager("select", 4);
	roiManager("delete");
}

```

# Merge left and right ROI

```java
roiManager("Select", newArray(2 ,3));
roiManager("combine");
roiManager("add");
roiManager("select", 4);
roiManager("rename", "all");

```

# reflect stroke ROI

```java

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

```

# Intersections
(between stroke and right cortex and between stroke_mirror and left cortex)

```java

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

```

# Clean Up unnecessary ROIs

```java
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

```

# Run ilastik

```java
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

```
<a href="image_1628692950464.png"><img src="image_1628692950464.png" width="250" alt="mask"/></a>
<a href="image_1628692953325.png"><img src="image_1628692953325.png" width="250" alt="Result of mask"/></a>

# Get Stats

```java
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


```
<a href="image_1628692958087.png"><img src="image_1628692958087.png" width="250" alt="mask"/></a>
<a href="image_1628692960837.png"><img src="image_1628692960837.png" width="250" alt="Result of mask"/></a>
<table>
<tr><th>Label</th><th>Area</th><th>Mean</th><th>Min</th><th>Max</th><th>X</th><th>Y</th><th>IntDen</th><th>Median</th><th>RawIntDen</th></tr>
<tr><td>160_Cy5.tif:right_cortex</td><td>0.000000044</td><td>123.000000000</td><td>119</td><td>127</td><td>0.578818828</td><td>0.027383067</td><td>0.000005390</td><td>127</td><td>246</td></tr>
<tr><td>160_Cy5.tif:right_cortex</td><td>0.000000088</td><td>123.250000000</td><td>119</td><td>128</td><td>0.595470693</td><td>0.037004144</td><td>0.000010801</td><td>123</td><td>493</td></tr>
<tr><td>160_Cy5.tif:right_cortex</td><td>0.000000022</td><td>124.000000000</td><td>124</td><td>124</td><td>0.562092954</td><td>0.038706335</td><td>0.000002717</td><td>124</td><td>124</td></tr>
<tr><td>160_Cy5.tif:right_cortex</td><td>0.000000022</td><td>122.000000000</td><td>122</td><td>122</td><td>0.598060983</td><td>0.039150385</td><td>0.000002673</td><td>122</td><td>122</td></tr>
<tr><td>160_Cy5.tif:right_cortex</td><td>0.000000022</td><td>122.000000000</td><td>122</td><td>122</td><td>0.619079337</td><td>0.039890468</td><td>0.000002673</td><td>122</td><td>122</td></tr>
<tr><td>160_Cy5.tif:right_cortex</td><td>0.000000044</td><td>121.000000000</td><td>119</td><td>123</td><td>0.634621078</td><td>0.043960924</td><td>0.000005302</td><td>123</td><td>242</td></tr>
<tr><td>160_Cy5.tif:right_cortex</td><td>0.000000022</td><td>123.000000000</td><td>123</td><td>123</td><td>0.623223801</td><td>0.046551214</td><td>0.000002695</td><td>123</td><td>123</td></tr>
<tr><td>160_Cy5.tif:right_cortex</td><td>0.000000022</td><td>119.000000000</td><td>119</td><td>119</td><td>0.602945530</td><td>0.047143280</td><td>0.000002607</td><td>119</td><td>119</td></tr>
<tr><td>160_Cy5.tif:right_cortex</td><td>0.000000022</td><td>118.000000000</td><td>118</td><td>118</td><td>0.598653049</td><td>0.047587330</td><td>0.000002585</td><td>118</td><td>118</td></tr>
<tr><td>160_Cy5.tif:right_cortex</td><td>0.000000044</td><td>121.500000000</td><td>119</td><td>124</td><td>0.634843102</td><td>0.048549438</td><td>0.000005324</td><td>124</td><td>243</td></tr>
<tr><td>160_Cy5.tif:right_cortex</td><td>0.000000044</td><td>117.500000000</td><td>117</td><td>118</td><td>0.608200118</td><td>0.051139728</td><td>0.000005149</td><td>118</td><td>235</td></tr>
<tr><td>160_Cy5.tif:right_cortex</td><td>0.000000022</td><td>121.000000000</td><td>121</td><td>121</td><td>0.749037892</td><td>0.052619893</td><td>0.000002651</td><td>121</td><td>121</td></tr>
<tr><td>160_Cy5.tif:right_cortex</td><td>0.000000022</td><td>121.000000000</td><td>121</td><td>121</td><td>0.707149201</td><td>0.053063943</td><td>0.000002651</td><td>121</td><td>121</td></tr>
<tr><td>160_Cy5.tif:right_cortex</td><td>0.000000022</td><td>121.000000000</td><td>121</td><td>121</td><td>0.774644760</td><td>0.055580225</td><td>0.000002651</td><td>121</td><td>121</td></tr>
<tr><td>160_Cy5.tif:right_cortex</td><td>0.000000022</td><td>120.000000000</td><td>120</td><td>120</td><td>0.761767318</td><td>0.055728242</td><td>0.000002629</td><td>120</td><td>120</td></tr>
<tr><td>160_Cy5.tif:right_cortex</td><td>0.000000022</td><td>115.000000000</td><td>115</td><td>115</td><td>0.644686205</td><td>0.061352872</td><td>0.000002520</td><td>115</td><td>115</td></tr>
<tr><td>160_Cy5.tif:right_cortex</td><td>0.000000022</td><td>121.000000000</td><td>121</td><td>121</td><td>0.776716992</td><td>0.064017170</td><td>0.000002651</td><td>121</td><td>121</td></tr>
<tr><td>160_Cy5.tif:right_cortex</td><td>0.000000022</td><td>120.000000000</td><td>120</td><td>120</td><td>0.665556542</td><td>0.065497336</td><td>0.000002629</td><td>120</td><td>120</td></tr>
<tr><td>160_Cy5.tif:right_cortex</td><td>0.000000022</td><td>122.000000000</td><td>122</td><td>122</td><td>0.775532860</td><td>0.066237419</td><td>0.000002673</td><td>122</td><td>122</td></tr>
<tr><td>160_Cy5.tif:right_cortex</td><td>0.000000022</td><td>123.000000000</td><td>123</td><td>123</td><td>0.776124926</td><td>0.067125518</td><td>0.000002695</td><td>123</td><td>123</td></tr>
<tr><td>160_Cy5.tif:right_cortex</td><td>0.000000044</td><td>126.000000000</td><td>126</td><td>126</td><td>0.783747780</td><td>0.069641800</td><td>0.000005521</td><td>126</td><td>252</td></tr>
<tr><td>160_Cy5.tif:right_cortex</td><td>0.000000022</td><td>125.000000000</td><td>125</td><td>125</td><td>0.797143280</td><td>0.071566015</td><td>0.000002739</td><td>125</td><td>125</td></tr>
<tr><td>160_Cy5.tif:right_cortex</td><td>0.000000022</td><td>120.000000000</td><td>120</td><td>120</td><td>0.767539964</td><td>0.072010065</td><td>0.000002629</td><td>120</td><td>120</td></tr>
<tr><td>160_Cy5.tif:right_cortex</td><td>0.000000022</td><td>118.000000000</td><td>118</td><td>118</td><td>0.748149793</td><td>0.072306098</td><td>0.000002585</td><td>118</td><td>118</td></tr>
<tr><td>160_Cy5.tif:right_cortex</td><td>0.000000044</td><td>120.500000000</td><td>116</td><td>125</td><td>0.834665483</td><td>0.077782712</td><td>0.000005280</td><td>125</td><td>241</td></tr>
<tr><td>160_Cy5.tif:right_cortex</td><td>0.000000022</td><td>117.000000000</td><td>117</td><td>117</td><td>0.707297217</td><td>0.083407342</td><td>0.000002563</td><td>117</td><td>117</td></tr>
<tr><td>160_Cy5.tif:right_cortex</td><td>0.000000153</td><td>122.571428571</td><td>118</td><td>125</td><td>0.592732386</td><td>0.085923623</td><td>0.000018798</td><td>124</td><td>858</td></tr>
<tr><td>160_Cy5.tif:right_cortex</td><td>0.000000044</td><td>122.500000000</td><td>122</td><td>123</td><td>0.859680284</td><td>0.092732386</td><td>0.000005368</td><td>123</td><td>245</td></tr>
<tr><td>160_Cy5.tif:right_cortex</td><td>0.000000044</td><td>120.000000000</td><td>118</td><td>122</td><td>0.900088810</td><td>0.107015986</td><td>0.000005258</td><td>122</td><td>240</td></tr>
<tr><td>160_Cy5.tif:right_cortex</td><td>0.000000022</td><td>126.000000000</td><td>126</td><td>126</td><td>0.869819420</td><td>0.109162226</td><td>0.000002761</td><td>126</td><td>126</td></tr>
<tr><td>160_Cy5.tif:right_cortex</td><td>0.000000022</td><td>118.000000000</td><td>118</td><td>118</td><td>0.903567200</td><td>0.127220249</td><td>0.000002585</td><td>118</td><td>118</td></tr>
<tr><td>160_Cy5.tif:right_cortex</td><td>0.000000022</td><td>119.000000000</td><td>119</td><td>119</td><td>0.949452339</td><td>0.171329189</td><td>0.000002607</td><td>119</td><td>119</td></tr>
<tr><td>160_Cy5.tif:right_cortex</td><td>0.000000022</td><td>118.000000000</td><td>118</td><td>118</td><td>0.988676732</td><td>0.330150977</td><td>0.000002585</td><td>118</td><td>118</td></tr>
<tr><td>160_Cy5.tif:right_cortex</td><td>0.000000044</td><td>123.000000000</td><td>121</td><td>125</td><td>0.981941978</td><td>0.434724689</td><td>0.000005390</td><td>125</td><td>246</td></tr>
<tr><td>160_Cy5.tif:right_cortex</td><td>0.000000022</td><td>121.000000000</td><td>121</td><td>121</td><td>0.883140912</td><td>0.539594435</td><td>0.000002651</td><td>121</td><td>121</td></tr>
<tr><td>160_Cy5.tif:left_cortex</td><td>0.000000088</td><td>121.000000000</td><td>119</td><td>124</td><td>0.428248964</td><td>0.018835110</td><td>0.000010604</td><td>121</td><td>484</td></tr>
<tr><td>160_Cy5.tif:left_cortex</td><td>0.000000022</td><td>125.000000000</td><td>125</td><td>125</td><td>0.476539372</td><td>0.018872114</td><td>0.000002739</td><td>125</td><td>125</td></tr>
<tr><td>160_Cy5.tif:left_cortex</td><td>0.000000022</td><td>121.000000000</td><td>121</td><td>121</td><td>0.479943754</td><td>0.020944346</td><td>0.000002651</td><td>121</td><td>121</td></tr>
<tr><td>160_Cy5.tif:left_cortex</td><td>0.000000022</td><td>117.000000000</td><td>117</td><td>117</td><td>0.400606868</td><td>0.023608644</td><td>0.000002563</td><td>117</td><td>117</td></tr>
<tr><td>160_Cy5.tif:left_cortex</td><td>0.000000044</td><td>123.500000000</td><td>121</td><td>126</td><td>0.502960332</td><td>0.024200710</td><td>0.000005412</td><td>126</td><td>247</td></tr>
<tr><td>160_Cy5.tif:left_cortex</td><td>0.000000044</td><td>121.000000000</td><td>120</td><td>122</td><td>0.503700414</td><td>0.024348727</td><td>0.000005302</td><td>122</td><td>242</td></tr>
<tr><td>160_Cy5.tif:left_cortex</td><td>0.000000022</td><td>126.000000000</td><td>126</td><td>126</td><td>0.308688573</td><td>0.025680876</td><td>0.000002761</td><td>126</td><td>126</td></tr>
<tr><td>160_Cy5.tif:left_cortex</td><td>0.000000022</td><td>127.000000000</td><td>127</td><td>127</td><td>0.326154529</td><td>0.026272943</td><td>0.000002782</td><td>127</td><td>127</td></tr>
<tr><td>160_Cy5.tif:left_cortex</td><td>0.000000022</td><td>120.000000000</td><td>120</td><td>120</td><td>0.311944938</td><td>0.026865009</td><td>0.000002629</td><td>120</td><td>120</td></tr>
<tr><td>160_Cy5.tif:left_cortex</td><td>0.000000022</td><td>117.000000000</td><td>117</td><td>117</td><td>0.493857312</td><td>0.027161042</td><td>0.000002563</td><td>117</td><td>117</td></tr>
<tr><td>160_Cy5.tif:left_cortex</td><td>0.000000022</td><td>119.000000000</td><td>119</td><td>119</td><td>0.377664298</td><td>0.027309059</td><td>0.000002607</td><td>119</td><td>119</td></tr>
<tr><td>160_Cy5.tif:left_cortex</td><td>0.000000044</td><td>122.000000000</td><td>120</td><td>124</td><td>0.494671403</td><td>0.032341622</td><td>0.000005346</td><td>124</td><td>244</td></tr>
<tr><td>160_Cy5.tif:left_cortex</td><td>0.000000022</td><td>126.000000000</td><td>126</td><td>126</td><td>0.329262877</td><td>0.032489639</td><td>0.000002761</td><td>126</td><td>126</td></tr>
<tr><td>160_Cy5.tif:left_cortex</td><td>0.000000044</td><td>123.000000000</td><td>122</td><td>124</td><td>0.302841918</td><td>0.032933689</td><td>0.000005390</td><td>124</td><td>246</td></tr>
<tr><td>160_Cy5.tif:left_cortex</td><td>0.000000022</td><td>121.000000000</td><td>121</td><td>121</td><td>0.498593843</td><td>0.033377738</td><td>0.000002651</td><td>121</td><td>121</td></tr>
<tr><td>160_Cy5.tif:left_cortex</td><td>0.000000022</td><td>123.000000000</td><td>123</td><td>123</td><td>0.475947306</td><td>0.033525755</td><td>0.000002695</td><td>123</td><td>123</td></tr>
<tr><td>160_Cy5.tif:left_cortex</td><td>0.000000066</td><td>120.666666667</td><td>118</td><td>123</td><td>0.512260707</td><td>0.034956582</td><td>0.000007931</td><td>121</td><td>362</td></tr>
<tr><td>160_Cy5.tif:left_cortex</td><td>0.000000022</td><td>117.000000000</td><td>117</td><td>117</td><td>0.354129663</td><td>0.035005921</td><td>0.000002563</td><td>117</td><td>117</td></tr>
<tr><td>160_Cy5.tif:left_cortex</td><td>0.000000022</td><td>124.000000000</td><td>124</td><td>124</td><td>0.494449378</td><td>0.035746004</td><td>0.000002717</td><td>124</td><td>124</td></tr>
<tr><td>160_Cy5.tif:left_cortex</td><td>0.000000022</td><td>124.000000000</td><td>124</td><td>124</td><td>0.295515098</td><td>0.036338070</td><td>0.000002717</td><td>124</td><td>124</td></tr>
<tr><td>160_Cy5.tif:left_cortex</td><td>0.000000044</td><td>122.000000000</td><td>121</td><td>123</td><td>0.381512729</td><td>0.036560095</td><td>0.000005346</td><td>123</td><td>244</td></tr>
<tr><td>160_Cy5.tif:left_cortex</td><td>0.000000022</td><td>120.000000000</td><td>120</td><td>120</td><td>0.432430432</td><td>0.039594435</td><td>0.000002629</td><td>120</td><td>120</td></tr>
<tr><td>160_Cy5.tif:left_cortex</td><td>0.000000022</td><td>121.000000000</td><td>121</td><td>121</td><td>0.263395500</td><td>0.039890468</td><td>0.000002651</td><td>121</td><td>121</td></tr>
<tr><td>160_Cy5.tif:left_cortex</td><td>0.000000044</td><td>120.000000000</td><td>119</td><td>121</td><td>0.244671403</td><td>0.045515098</td><td>0.000005258</td><td>121</td><td>240</td></tr>
<tr><td>160_Cy5.tif:left_cortex</td><td>0.000000022</td><td>120.000000000</td><td>120</td><td>120</td><td>0.302619893</td><td>0.046255181</td><td>0.000002629</td><td>120</td><td>120</td></tr>
<tr><td>160_Cy5.tif:left_cortex</td><td>0.000000044</td><td>120.500000000</td><td>119</td><td>122</td><td>0.255106572</td><td>0.050325636</td><td>0.000005280</td><td>122</td><td>241</td></tr>
<tr><td>160_Cy5.tif:left_cortex</td><td>0.000000044</td><td>120.000000000</td><td>119</td><td>121</td><td>0.264875666</td><td>0.051953819</td><td>0.000005258</td><td>121</td><td>240</td></tr>
<tr><td>160_Cy5.tif:left_cortex</td><td>0.000000022</td><td>124.000000000</td><td>124</td><td>124</td><td>0.434798697</td><td>0.055136175</td><td>0.000002717</td><td>124</td><td>124</td></tr>
<tr><td>160_Cy5.tif:left_cortex</td><td>0.000000022</td><td>119.000000000</td><td>119</td><td>119</td><td>0.538706335</td><td>0.056912374</td><td>0.000002607</td><td>119</td><td>119</td></tr>
<tr><td>160_Cy5.tif:left_cortex</td><td>0.000000044</td><td>123.000000000</td><td>120</td><td>126</td><td>0.307134399</td><td>0.058984606</td><td>0.000005390</td><td>126</td><td>246</td></tr>
<tr><td>160_Cy5.tif:left_cortex</td><td>0.000000066</td><td>118.333333333</td><td>115</td><td>121</td><td>0.190670022</td><td>0.070431222</td><td>0.000007778</td><td>119</td><td>355</td></tr>
<tr><td>160_Cy5.tif:left_cortex</td><td>0.000000022</td><td>124.000000000</td><td>124</td><td>124</td><td>0.210109532</td><td>0.073638247</td><td>0.000002717</td><td>124</td><td>124</td></tr>
<tr><td>160_Cy5.tif:left_cortex</td><td>0.000000022</td><td>116.000000000</td><td>116</td><td>116</td><td>0.352945530</td><td>0.076006513</td><td>0.000002541</td><td>116</td><td>116</td></tr>
<tr><td>160_Cy5.tif:left_cortex</td><td>0.000000022</td><td>120.000000000</td><td>120</td><td>120</td><td>0.180210184</td><td>0.079558911</td><td>0.000002629</td><td>120</td><td>120</td></tr>
<tr><td>160_Cy5.tif:left_cortex</td><td>0.000000022</td><td>120.000000000</td><td>120</td><td>120</td><td>0.200784488</td><td>0.080298993</td><td>0.000002629</td><td>120</td><td>120</td></tr>
<tr><td>160_Cy5.tif:left_cortex</td><td>0.000000088</td><td>123.500000000</td><td>120</td><td>126</td><td>0.178063943</td><td>0.081705151</td><td>0.000010823</td><td>125</td><td>494</td></tr>
<tr><td>160_Cy5.tif:left_cortex</td><td>0.000000022</td><td>117.000000000</td><td>117</td><td>117</td><td>0.171033156</td><td>0.081927176</td><td>0.000002563</td><td>117</td><td>117</td></tr>
<tr><td>160_Cy5.tif:left_cortex</td><td>0.000000022</td><td>123.000000000</td><td>123</td><td>123</td><td>0.199748372</td><td>0.082075192</td><td>0.000002695</td><td>123</td><td>123</td></tr>
<tr><td>160_Cy5.tif:left_cortex</td><td>0.000000044</td><td>122.500000000</td><td>119</td><td>126</td><td>0.162892244</td><td>0.087033748</td><td>0.000005368</td><td>126</td><td>245</td></tr>
<tr><td>160_Cy5.tif:left_cortex</td><td>0.000000022</td><td>119.000000000</td><td>119</td><td>119</td><td>0.176805802</td><td>0.089624038</td><td>0.000002607</td><td>119</td><td>119</td></tr>
<tr><td>160_Cy5.tif:left_cortex</td><td>0.000000022</td><td>120.000000000</td><td>120</td><td>120</td><td>0.193827709</td><td>0.089920071</td><td>0.000002629</td><td>120</td><td>120</td></tr>
<tr><td>160_Cy5.tif:left_cortex</td><td>0.000000022</td><td>123.000000000</td><td>123</td><td>123</td><td>0.156083481</td><td>0.093620485</td><td>0.000002695</td><td>123</td><td>123</td></tr>
<tr><td>160_Cy5.tif:left_cortex</td><td>0.000000022</td><td>121.000000000</td><td>121</td><td>121</td><td>0.176361753</td><td>0.097468917</td><td>0.000002651</td><td>121</td><td>121</td></tr>
<tr><td>160_Cy5.tif:left_cortex</td><td>0.000000044</td><td>122.000000000</td><td>121</td><td>123</td><td>0.128996448</td><td>0.116489047</td><td>0.000005346</td><td>123</td><td>244</td></tr>
<tr><td>160_Cy5.tif:left_cortex</td><td>0.000000022</td><td>121.000000000</td><td>121</td><td>121</td><td>0.105165779</td><td>0.154159266</td><td>0.000002651</td><td>121</td><td>121</td></tr>
<tr><td>160_Cy5.tif:left_cortex</td><td>0.000000022</td><td>125.000000000</td><td>125</td><td>125</td><td>0.082075192</td><td>0.164668443</td><td>0.000002739</td><td>125</td><td>125</td></tr>
<tr><td>160_Cy5.tif:left_cortex</td><td>0.000000044</td><td>122.000000000</td><td>119</td><td>125</td><td>0.081705151</td><td>0.165260509</td><td>0.000005346</td><td>125</td><td>244</td></tr>
<tr><td>160_Cy5.tif:left_cortex</td><td>0.000000022</td><td>125.000000000</td><td>125</td><td>125</td><td>0.078226761</td><td>0.174141504</td><td>0.000002739</td><td>125</td><td>125</td></tr>
<tr><td>160_Cy5.tif:left_cortex</td><td>0.000000022</td><td>123.000000000</td><td>123</td><td>123</td><td>0.084295441</td><td>0.193975725</td><td>0.000002695</td><td>123</td><td>123</td></tr>
<tr><td>160_Cy5.tif:left_cortex</td><td>0.000000022</td><td>122.000000000</td><td>122</td><td>122</td><td>0.061204855</td><td>0.226095323</td><td>0.000002673</td><td>122</td><td>122</td></tr>
<tr><td>160_Cy5.tif:left_cortex</td><td>0.000000044</td><td>120.000000000</td><td>120</td><td>120</td><td>0.056616341</td><td>0.247335702</td><td>0.000005258</td><td>120</td><td>240</td></tr>
<tr><td>160_Cy5.tif:left_cortex</td><td>0.000000022</td><td>120.000000000</td><td>120</td><td>120</td><td>0.063721137</td><td>0.254662522</td><td>0.000002629</td><td>120</td><td>120</td></tr>
<tr><td>160_Cy5.tif:left_cortex</td><td>0.000000022</td><td>132.000000000</td><td>132</td><td>132</td><td>0.069197750</td><td>0.307060391</td><td>0.000002892</td><td>132</td><td>132</td></tr>
<tr><td>160_Cy5.tif:left_cortex</td><td>0.000000022</td><td>117.000000000</td><td>117</td><td>117</td><td>0.068605684</td><td>0.324378330</td><td>0.000002563</td><td>117</td><td>117</td></tr>
<tr><td>160_Cy5.tif:left_cortex</td><td>0.000000044</td><td>120.000000000</td><td>117</td><td>123</td><td>0.067717584</td><td>0.337921847</td><td>0.000005258</td><td>123</td><td>240</td></tr>
<tr><td>160_Cy5.tif:left_cortex</td><td>0.000000022</td><td>116.000000000</td><td>116</td><td>116</td><td>0.088291889</td><td>0.370263470</td><td>0.000002541</td><td>116</td><td>116</td></tr>
<tr><td>160_Cy5.tif:left_cortex</td><td>0.000000022</td><td>120.000000000</td><td>120</td><td>120</td><td>0.147646536</td><td>0.445603908</td><td>0.000002629</td><td>120</td><td>120</td></tr>
<tr><td>160_Cy5.tif:left_cortex</td><td>0.000000022</td><td>122.000000000</td><td>122</td><td>122</td><td>0.157119597</td><td>0.447232090</td><td>0.000002673</td><td>122</td><td>122</td></tr>
<tr><td>160_Cy5.tif:stroke_in</td><td>0.000000044</td><td>122.500000000</td><td>122</td><td>123</td><td>0.859680284</td><td>0.092732386</td><td>0.000005368</td><td>123</td><td>245</td></tr>
<tr><td>160_Cy5.tif:stroke_in</td><td>0.000000044</td><td>120.000000000</td><td>118</td><td>122</td><td>0.900088810</td><td>0.107015986</td><td>0.000005258</td><td>122</td><td>240</td></tr>
<tr><td>160_Cy5.tif:stroke_in</td><td>0.000000022</td><td>126.000000000</td><td>126</td><td>126</td><td>0.869819420</td><td>0.109162226</td><td>0.000002761</td><td>126</td><td>126</td></tr>
<tr><td>160_Cy5.tif:stroke_in</td><td>0.000000022</td><td>118.000000000</td><td>118</td><td>118</td><td>0.903567200</td><td>0.127220249</td><td>0.000002585</td><td>118</td><td>118</td></tr>
<tr><td>160_Cy5.tif:stroke_in</td><td>0.000000022</td><td>119.000000000</td><td>119</td><td>119</td><td>0.949452339</td><td>0.171329189</td><td>0.000002607</td><td>119</td><td>119</td></tr>
<tr><td>160_Cy5.tif:stroke_mirror_in</td><td>0.000000022</td><td>121.000000000</td><td>121</td><td>121</td><td>0.263395500</td><td>0.039890468</td><td>0.000002651</td><td>121</td><td>121</td></tr>
<tr><td>160_Cy5.tif:stroke_mirror_in</td><td>0.000000044</td><td>120.000000000</td><td>119</td><td>121</td><td>0.244671403</td><td>0.045515098</td><td>0.000005258</td><td>121</td><td>240</td></tr>
<tr><td>160_Cy5.tif:stroke_mirror_in</td><td>0.000000044</td><td>120.500000000</td><td>119</td><td>122</td><td>0.255106572</td><td>0.050325636</td><td>0.000005280</td><td>122</td><td>241</td></tr>
<tr><td>160_Cy5.tif:stroke_mirror_in</td><td>0.000000044</td><td>120.000000000</td><td>119</td><td>121</td><td>0.264875666</td><td>0.051953819</td><td>0.000005258</td><td>121</td><td>240</td></tr>
<tr><td>160_Cy5.tif:stroke_mirror_in</td><td>0.000000066</td><td>118.333333333</td><td>115</td><td>121</td><td>0.190670022</td><td>0.070431222</td><td>0.000007778</td><td>119</td><td>355</td></tr>
<tr><td>160_Cy5.tif:stroke_mirror_in</td><td>0.000000022</td><td>124.000000000</td><td>124</td><td>124</td><td>0.210109532</td><td>0.073638247</td><td>0.000002717</td><td>124</td><td>124</td></tr>
<tr><td>160_Cy5.tif:stroke_mirror_in</td><td>0.000000022</td><td>120.000000000</td><td>120</td><td>120</td><td>0.180210184</td><td>0.079558911</td><td>0.000002629</td><td>120</td><td>120</td></tr>
<tr><td>160_Cy5.tif:stroke_mirror_in</td><td>0.000000022</td><td>120.000000000</td><td>120</td><td>120</td><td>0.200784488</td><td>0.080298993</td><td>0.000002629</td><td>120</td><td>120</td></tr>
<tr><td>160_Cy5.tif:stroke_mirror_in</td><td>0.000000088</td><td>123.500000000</td><td>120</td><td>126</td><td>0.178063943</td><td>0.081705151</td><td>0.000010823</td><td>125</td><td>494</td></tr>
<tr><td>160_Cy5.tif:stroke_mirror_in</td><td>0.000000022</td><td>117.000000000</td><td>117</td><td>117</td><td>0.171033156</td><td>0.081927176</td><td>0.000002563</td><td>117</td><td>117</td></tr>
<tr><td>160_Cy5.tif:stroke_mirror_in</td><td>0.000000022</td><td>123.000000000</td><td>123</td><td>123</td><td>0.199748372</td><td>0.082075192</td><td>0.000002695</td><td>123</td><td>123</td></tr>
<tr><td>160_Cy5.tif:stroke_mirror_in</td><td>0.000000044</td><td>122.500000000</td><td>119</td><td>126</td><td>0.162892244</td><td>0.087033748</td><td>0.000005368</td><td>126</td><td>245</td></tr>
<tr><td>160_Cy5.tif:stroke_mirror_in</td><td>0.000000022</td><td>119.000000000</td><td>119</td><td>119</td><td>0.176805802</td><td>0.089624038</td><td>0.000002607</td><td>119</td><td>119</td></tr>
<tr><td>160_Cy5.tif:stroke_mirror_in</td><td>0.000000022</td><td>120.000000000</td><td>120</td><td>120</td><td>0.193827709</td><td>0.089920071</td><td>0.000002629</td><td>120</td><td>120</td></tr>
<tr><td>160_Cy5.tif:stroke_mirror_in</td><td>0.000000022</td><td>123.000000000</td><td>123</td><td>123</td><td>0.156083481</td><td>0.093620485</td><td>0.000002695</td><td>123</td><td>123</td></tr>
<tr><td>160_Cy5.tif:stroke_mirror_in</td><td>0.000000022</td><td>121.000000000</td><td>121</td><td>121</td><td>0.176361753</td><td>0.097468917</td><td>0.000002651</td><td>121</td><td>121</td></tr>
<tr><td>160_Cy5.tif:stroke_mirror_in</td><td>0.000000044</td><td>122.000000000</td><td>121</td><td>123</td><td>0.128996448</td><td>0.116489047</td><td>0.000005346</td><td>123</td><td>244</td></tr>
</table>

<table>
<tr><th>Slice</th><th>Count</th><th>Total Area</th><th>Average Size</th><th>%Area</th><th>Mean</th><th>IntDen</th><th>Median</th></tr>
<tr><td>mask</td><td>35</td><td>0.000001161</td><td>0.000000033</td><td>0.001373486</td><td>120.994897897</td><td>0.000004028</td><td>121.542857143</td></tr>
<tr><td>mask</td><td>58</td><td>0.000001797</td><td>0.000000031</td><td>0.002544122</td><td>121.413793103</td><td>0.000003760</td><td>121.879310345</td></tr>
<tr><td>mask</td><td>5</td><td>0.000000153</td><td>0.000000031</td><td>0.000777489</td><td>121.100000000</td><td>0.000003716</td><td>121.600000000</td></tr>
<tr><td>mask</td><td>17</td><td>0.000000592</td><td>0.000000035</td><td>0.003901531</td><td>120.872549169</td><td>0.000004210</td><td>121.470588235</td></tr>
</table>

<table>
<tr><th>Label</th><th>Count</th><th>AreaSegmentation[squareUnits]</th><th>RegionArea[squareUnits]</th><th>AreaFraction[%]</th><th>NumbPositivePixels</th><th>RawIntDen</th><th>IntDen</th><th>AverageSize[squareUnits]</th></tr>
<tr><td>right_cortex</td><td>35</td><td>0.000001161</td><td>0.084541960</td><td>0.001373486</td><td>53</td><td>6435</td><td>0.000140984</td><td>0.000000033</td></tr>
<tr><td>left_cortex</td><td>58</td><td>0.000001797</td><td>0.070614950</td><td>0.002544122</td><td>82</td><td>9955</td><td>0.000218103</td><td>0.000000031</td></tr>
<tr><td>stroke_in</td><td>5</td><td>0.000000153</td><td>0.019725334</td><td>0.000777489</td><td>7</td><td>848</td><td>0.000018579</td><td>0.000000031</td></tr>
<tr><td>stroke_mirror_in</td><td>17</td><td>0.000000592</td><td>0.015161753</td><td>0.003901531</td><td>26</td><td>3267</td><td>0.000071576</td><td>0.000000035</td></tr>
</table>


# Save results and Close all

```java

selectWindow("Results");
saveAs("Results", outDir + mainFileName+"_"+"ParticlesResults.csv");

selectWindow("Summary");
run("Close");

selectWindow("final results");
saveAs("Results", outDir + mainFileName+"_"+"Results.csv");

resetNonImageWindows("");

close("*");



```

# Auxiliary functions

```java

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
```



```
```
