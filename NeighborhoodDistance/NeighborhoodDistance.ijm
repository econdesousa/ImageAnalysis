/*

#  BIOIMAGING - INEB/i3S
Eduardo Conde-Sousa (econdesousa@gmail.com)

## Neighborhood distance from labelmap
 
### code version
0.1

### last modification
15/04/2021 at 12:28:16 (GMT)

### Attribution:
If you use this macro please add in the acknowledgements of your papers and/or thesis (MSc and PhD) the reference to Bioimaging and the project PPBI-POCI-01-0145-FEDER-022122.
As a suggestion you may use the following sentence:
 * The authors acknowledge the support of the i3S Scientific Platform Bioimaging, member of the national infrastructure PPBI - Portuguese Platform of Bioimaging (PPBI-POCI-01-0145-FEDER-022122).

*/



run("CLIJ2 Macro Extensions", "cl_device=[]");
close("*");

/*
# get a sample image and create label version
this part is just for demo
*/
run("Blobs (25K)");
blobs = "blobs.gif";
Ext.CLIJ2_push(blobs);
imOut = "voronoi_otsu_labeling-blobs";
spot_sigma = 5.0;
outline_sigma = 5.0;
Ext.CLIJx_voronoiOtsuLabeling(blobs, imOut, spot_sigma, outline_sigma);
Ext.CLIJ2_pull(imOut);
Ext.CLIJ2_release(blobs);
Ext.CLIJ2_release(imOut);

/*
# get image info and
*/
label_map = getTitle();
run("glasbey_on_dark");
Ext.CLIJ2_clear();
Ext.CLIJ2_push(label_map);

/*
# get distance map
*/
averageDistance(label_map,label_map+"_averageDist_",3,"Fire",true);


function averageDistance(inputImage,outputName,nNeig,LUT,CalibrationBar){
	outputImage=outputName+nNeig;
	Ext.CLIJ2_closeIndexGapsInLabelMap(inputImage, inputImage_tmp);
	Ext.CLIJx_averageDistanceOfNClosestNeighborsMap(inputImage_tmp, outputImage, nNeig);
	Ext.CLIJ2_pull(outputImage);
	Ext.CLIJ2_release(outputImage);
	Ext.CLIJ2_release(inputImage_tmp);
	run(LUT);
	if (CalibrationBar){
		run("Calibration Bar...", "location=[Upper Right] fill=White label=Black number=5 decimal=0 font=12 zoom=1 overlay");
	}
}
