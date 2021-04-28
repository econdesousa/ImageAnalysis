/*

#  BIOIMAGING - INEB/i3S
Eduardo Conde-Sousa (econdesousa@gmail.com)

****************************************************
## Get Centroids of Labeled Image
****************************************************

Departing from a Demo Labeled Image retunrs the 
centroids of labels

Requirements: CLIJ2 

### code version
1

### last modification
28/04/2021 at 17:41:23 (GMT)

### Attribution:
If you use this macro please add in the acknowledgements of your papers and/or thesis (MSc and PhD) the reference to Bioimaging and the project PPBI-POCI-01-0145-FEDER-022122.
As a suggestion you may use the following sentence:
 * The authors acknowledge the support of the i3S Scientific Platform Bioimaging, member of the national infrastructure PPBI - Portuguese Platform of Bioimaging (PPBI-POCI-01-0145-FEDER-022122).

*/


/*
# Get a Demo Labeled Image
 */
getDemoImage("Demo");
showZoom("Demo",5);
/*
# Get Centroids
 */
selectWindow("Demo");
getCentroids();
selectWindow("Demo");close();
selectWindow("MAX_Demo");close();
showZoom("Demo_centroids",5);

/*
Auxiliary Functions
*/
function getCentroids(){
	run("CLIJ2 Macro Extensions", "cl_device=[]");
	labels=getTitle();
	centroidsPointList="centroidsPointList";
	centroids="centroids";
	output = labels+"_centroids";
	
	Ext.CLIJ2_push(labels);
	Ext.CLIJ2_centroidsOfLabels(labels, centroidsPointList);
	
	Ext.CLIJ2_getDimensions(centroidsPointList, number_of_labels, dimensionality, garbage);
	
	Ext.CLIJ2_create2D(coordinates_and_index, number_of_labels + 1, dimensionality + 1, 32);
	Ext.CLIJ2_setRampX(coordinates_and_index);
	Ext.CLIJ2_paste2D(centroidsPointList, coordinates_and_index, 1, 0);
	
	
	// generate an output image, set it to 0 everywhwere
	Ext.CLIJ2_getDimensions(labels, width, height, depth);
	Ext.CLIJ2_create3D(output, width, height, depth, 32);
	Ext.CLIJ2_set(output, 0);
	
	
	// at every pixel position defined in the coordinate list above, write a number
	Ext.CLIJ2_writeValuesToPositions(coordinates_and_index, output);
	
	// visualise the output
	Ext.CLIJ2_pull(output);
	setMinAndMax(0, number_of_labels);
	run("glasbey_on_dark");
}	
	
function getDemoImage(name) { 	
	setBatchMode(true);
	newImage(name, "32-bit black", 500, 500, 40);
	setSlice(15);
	makeOval(250, 250, 1, 1);
	run("Set...", "value=1");
	im=getTitle();
	DilateLabel(im,4);
	setSlice(20);
	makeOval(99, 99, 1, 1);
	run("Set...", "value=2");
	DilateLabel(im,2);
	setTool("rectangle");
	setBatchMode(false);
	setMinAndMax(0, 2);
	run("glasbey_on_dark");
}


function DilateLabel(im,nDil){
	if (nDil<2) nDil=2;
	run("CLIJ2 Macro Extensions", "cl_device=[]");
	Ext.CLIJ2_push(im);
	selectWindow(im);close();
	Ext.CLIJ2_copy(im, flip);
	for (i = 0; i < floor(nDil/2); i++) {
		Ext.CLIJ2_onlyzeroOverwriteMaximumDiamond(flip, flop);
		Ext.CLIJ2_onlyzeroOverwriteMaximumDiamond(flop,flip);
	}Ext.CLIJ2_copy(flip, im);
	Ext.CLIJ2_pull(im);
	Ext.CLIJ2_release(flip);
	Ext.CLIJ2_release(flop);
}

function showZoom(name,zoom){
	setBatchMode(true);
	selectWindow(name);
	if (nSlices>1) {
		run("Z Project...", "projection=[Max Intensity]");
		id=getImageID();
		run("Morphological Filters", "operation=Dilation element=Disk radius=5");
		rename("MAX_"+name);
		selectImage(id);close();
		getStatistics(area, mean, min, max, std, histogram);
		setMinAndMax(0, max);
		run("glasbey_on_dark");
	}
	setBatchMode(false);
}
