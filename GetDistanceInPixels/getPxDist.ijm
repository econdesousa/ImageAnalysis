/*
 * Determine the length in pixels of line tool
 * 
 *  
 * Eduardo Conde-Sousa
 * BioImaging @ i3S
 * B.Image @ INEB
 * 
 * econdesousa@ineb.up.pt
 * econdesousa@i3s.up.pt
 * econdesousa@gmail.com
 * 
 */

macro "get Pixel Distance" {
	existResultsFlag=0;
	if (nResults>0){
		existResultsFlag=1;
		IJ.renameResults("tmpReSuLtS"); 
	}
	; 
	
	 
	name = getTitle();
	setTool("line");
	while(selectionType != 5) {
		waitForUser("Draw a Line and press OK");
	}
	
	// Get Parametric curve equation
	getSelectionCoordinates(x,y);
	// Compute the distance between the two points
	dist = sqrt(pow(x[1] - x[0], 2) + pow(y[1] - y[0],2));
	
	// Image Name
	setResult("Image", 0, name);
	
	//Length [Pixels]
	setResult("Length [px]", 0, dist);
	//
	//Length [Calibrated Units] 
	getVoxelSize(width, height, depth, unit);
	setResult("Length ["+unit+"]", 0, dist * width);
	
	
	IJ.renameResults("Line Length");
	if (existResultsFlag>0){
		selectWindow("tmpReSuLtS");
		IJ.renameResults("Results");
	}
}