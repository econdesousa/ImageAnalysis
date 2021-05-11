/*

#  BIOIMAGING - INEB/i3S
Eduardo Conde-Sousa (econdesousa@gmail.com)

****************************************************
## Mitochondrial stats
****************************************************

1. mitochondrial segmentation with
 * difference of gaussian
 * ilastik
2. mitochodrial classification
 * ilastik
3. Nuclei segmentation
 * Stardist (after smoothing and rescaling)
4. Distance between mitochroria and closest nucleus
 * 3D ImageJ suite

### requirements
* CLIJ2
* 3D ImageJ suite
* Ilastik

### code version
1

### last modification
11/05/2021

### Attribution:
If you use this macro please add in the acknowledgements of your papers and/or thesis (MSc and PhD) the reference to Bioimaging and the project PPBI-POCI-01-0145-FEDER-022122.
As a suggestion you may use the following sentence:
 * The authors acknowledge the support of the i3S Scientific Platform Bioimaging, member of the national infrastructure PPBI - Portuguese Platform of Bioimaging (PPBI-POCI-01-0145-FEDER-022122).

*/

/*
# Setup
*/

close("\\Others");
run("Select None");
resetNonImageWindows();
projectName = File.openDialog("Select ilastik object classification project");
sigma1x = 1.5;
sigma2x = 2;
scaleFactor = 2;
run("CLIJ2 Macro Extensions", "cl_device=");
Ext.CLIJ2_clear();

/*
# call main function
*/

main=getTitle();
proc1file(main,1,sigma1x,sigma2x,projectName,2,scaleFactor);


function proc1file(main,chMito,sigma1x,sigma2x,projectName,chDapi,scaleFactor){
	mainImageID=getImageID();
	close("\\Others");
	Stack.setChannel(chMito);
	procMITO(main,sigma1x,sigma2x,projectName);
	selectImage(mainImageID);
	Stack.setChannel(chDapi);
	procDAPI(main,chDapi,scaleFactor);
	selectImage(mainImageID);
	getVoxelSize(width, height, depth, unit);
	for (im = 1; im <= nImages; im++) {
		selectImage(im);
		setVoxelSize(width, height, depth, unit);
	}
	selectImage(mainImageID);
	outputName=newArray("Puncta","Rods","Networks");
	for (gr = 1; gr <= 3; gr++) {
		run("Tile");
		selectImage(mainImageID);
		mask = "labelMask_"+gr;
		distMitoNuc(main,mask,chMito,outputName[gr-1]);
	}
	
	run("Tile");
	run("Show All");
}


/*
# other functions
*/
function procMITO(main,sigma1x,sigma2x,projectName) { 
		
	image_1 = main;
	id=getImageID();
	diffOfGaussian(sigma1x,sigma2x);
	//saveas("tif", outDir + File.separator + filelist[i]);
	id1=getImageID();
	selectImage(id);rename("main");
	selectImage(id1);rename(image_1);
	Ext.CLIJ2_push(image_1);
	run("Run Object Classification Prediction", "projectfilename="+projectName+" inputimage=["+image_1+"] inputproborsegimage=["+image_1+"] secondinputtype=Segmentation");
	//saveAs("tif", outDir + File.separator + filelist[i]+"_labelmap.tif");
	labelmap=getTitle();
	Ext.CLIJ2_push(labelmap);
	outline = image_1+"_outlines";
	Ext.CLIJx_visualizeOutlinesOnOriginal(image_1, labelmap, outline);
	Ext.CLIJ2_pull(outline);
	run("Hi");	
	//saveas("tif",outDir + File.separator + filelist[i]+"_outlines.tif");
	close();
	selectWindow(labelmap);
	labelMask="labelMask";
	run("glasbey_on_dark");
	for (label_index = 1;label_index <=3;label_index++){
		Ext.CLIJ2_maskLabel(labelmap, labelmap, labelMask, label_index);
		Ext.CLIJ2_pullBinary(labelMask);
		rename(labelMask+"_"+label_index);
		//saveas("tif",outDir + File.separator + filelist[i]+"_labelMask_"+label_index);//close();
	}	
	selectImage(id1);close();
	selectImage(id);rename(image_1);run("Tile");
}



function procDAPI(main,channel,scaleFactor){
	//run("Duplicate...", "title=DAPI duplicate channels="+channel);
	getVoxelSize(width, height, depth, unit);
	mainID=getImageID();

	run("Duplicate...", "title=DAPI duplicate channels=2");
	dapiID=getImageID();
	run("Gaussian Blur...", "sigma=5");
	run("Scale...", "x="+(1/scaleFactor)+" y="+(1/scaleFactor)+" interpolation=None average create");
	dapiScaledID=getImageID();
	run("Command From Macro", "command=[de.csbdresden.stardist.StarDist2D], args=['input':'DAPI-1', 'modelChoice':'Versatile (fluorescent nuclei)', 'normalizeInput':'true', 'percentileBottom':'1.0', 'percentileTop':'100.0', 'probThresh':'0.39999999999999997', 'nmsThresh':'0.4', 'outputType':'Label Image', 'nTiles':'1', 'excludeBoundary':'2', 'roiPosition':'Stack', 'verbose':'false', 'showCsbdeepProgress':'false', 'showProbAndDist':'false'], process=[false]");
	selectWindow("Label Image");
	run("Scale...", "x="+scaleFactor+" y="+scaleFactor+" interpolation=None average create");
	selectWindow("Label Image");close();
	selectWindow("Label Image-1");rename("Label Image");
	
	run("Label Boundaries");
	run("Options...", "iterations=1 count=1 black do=Dilate");
	run("Invert");
	//waitForUser("1");
	selectWindow("Label Image");
	setThreshold(1, pow(2,bitDepth())-1);
	run("Convert to Mask");
	imageCalculator("AND", "Label Image","Label-bnd");
	setVoxelSize(width, height, depth, unit);
	rename("DAPImaskTMP");
	selectImage(dapiScaledID);close();
	//selectWindow("Label Image");close();
	selectWindow("Label-bnd");close();
	run("Set Measurements...", "area mean min display redirect=None decimal=3");
	run("Analyze Particles...", "size=1000-Infinity pixel show=Masks");
	if (is("Inverting LUT")) run("Invert LUT");
	rename("DAPImask");
	selectWindow("DAPImaskTMP");close();
	selectWindow("DAPI");close();
	run("Tile");
	selectWindow(main);
}


function distMitoNuc(main,mask,chMito,output) { 
	selectWindow(main);
	run("Duplicate...", "title=Mito duplicate channels="+chMito);
	selectWindow(mask);
	run("Connected Components Labeling", "connectivity=4 type=float");
	label_map="label_map";
	rename(label_map);
	// statistics of labelled pixels
	run("Intensity Measurements 2D/3D", "input=Mito labels=label_map mean max min median mode volume");
	//Table.rename("Mito-intensity-measurements", "Results");
	selectWindow("DAPImask");
	run("Connected Components Labeling", "connectivity=4 type=float");
	run("3D Distances", "image_a=label_map image_b=DAPImask-lbl compute=Closest_1 closest=Border(slow) border");

	selectWindow("Distances_Border");
	Dist=Table.getColumn("Distance_1");
	run("Close");
	selectWindow("Mito-intensity-measurements");
	Labels=Table.getColumn("Label");
	Mean=Table.getColumn("Mean");
	Max=Table.getColumn("Max");
	Min=Table.getColumn("Min");
	Mode=Table.getColumn("Mode");
	Area=Table.getColumn("Volume");
	Median=Table.getColumn("Median");
	run("Close");

	Table.create(output);
	Table.setColumn("Label", Labels);
	Table.setColumn("Area", Area);
	Table.setColumn("Mean", Mean);
	Table.setColumn("Max", Max);
	Table.setColumn("Min", Min);
	Table.setColumn("Median", Median);
	Table.setColumn("Mode", Mode);
	Table.setColumn("Distance2Nuc", Dist);
	selectWindow("Mito");close();
	selectWindow("DAPImask-lbl");close();
	selectWindow("label_map");close();
}



function diffOfGaussian(sigma1x,sigma2x) { 
	image_1 = getTitle();
	Ext.CLIJ2_pushCurrentZStack(image_1);
	
	// Difference Of Gaussian2D
	sigma1y = sigma1x;
	sigma2y = sigma2x;
	Ext.CLIJ2_differenceOfGaussian2D(image_1, image_difference_of_gaussian2d, sigma1x, sigma1y, sigma2x, sigma2y);
	Ext.CLIJ2_release(image_1);
	
	Ext.CLIJ2_pull(image_difference_of_gaussian2d);
	Ext.CLIJ2_release(image_difference_of_gaussian2d);
}



function resetNonImageWindows(){
	list = getList("window.titles");
	for (i = 0; i < lengthOf(list); i++) {
		selectWindow(list[i]);run("Close");
	}
}








