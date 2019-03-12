/*
 * b.IMAGE - 07/03/2019
 * INEB -  Instituto Nacional de Engenharia Biomedica
 * i3S - Instituto de Investigacao e Inovacao em Saude
 * 
 * authors:
 * Eduardo Conde-Sousa (1)			Paulo Aguiar
 * econdesousa@ineb.up.pt			pauloaguiar@ineb.up.pt
 * 
 * (1) corresponding author
 * 
 */
 
 
if( roiManager("count")>0){
	roiManager("reset");
}
if (nImages<1){
	path = File.openDialog("Choose a File");
	open(path);
}

function doAll(){
	NoiseTol = getNumber("Noise Tolerance: ", 2000);
	Sigma = getNumber("Sigma: ", 5);
	setBatchMode(true);
	T=getTitle();
	// Create Average Projections per channel
	run("Duplicate...", "title=mainWindow duplicate");
	run("Z Project...", "projection=[Average Intensity]");
	run("Split Channels");
	selectWindow("C1-AVG_mainWindow");
	rename("red");
	selectWindow("C2-AVG_mainWindow");
	rename("green");

	// Merge both channels 
	imageCalculator("Average create", "red","green");
	selectWindow("green");
	close();
	selectWindow("red");
	close();
	selectWindow("Result of red");
	rename("mask");

	// Blurring
	run("Gaussian Blur...", "sigma="+Sigma);
	
	//Thresholding
	setAutoThreshold("Triangle dark");
	setOption("BlackBackground", true);
	run("Convert to Mask");

	//Remove small size "fibers" (problably small blobs that are not fibers)
	run("Analyze Particles...", "size=1000-Infinity show=Masks");
	selectWindow("mask");
	close();
	rename("mask");
	run("Create Selection");
	roiManager("add");
	roiManager("select", roiManager("count")-1);
	roiManager("rename", "fibers");

	// Create Max Projections per channel
	selectWindow("mainWindow");
	run("Z Project...", "projection=[Max Intensity]");
	run("Split Channels");
	selectWindow("C1-MAX_mainWindow");
	rename("red");
	selectWindow("C2-MAX_mainWindow");
	rename("green");


	//Find maxima in each channel 
	//green channel
	run("Find Maxima...", "noise="+NoiseTol+" output=[Point Selection]");
	run("Create Mask");
	selectWindow("green");
	close();
	selectWindow("Mask");
	rename("green");
	imageCalculator("AND create", "green","mask");
	selectWindow("green");
	close();
	selectWindow("Result of green");
	rename("green");
	run("Set Measurements...", "  redirect=None decimal=2");
	run("Analyze Particles...", "size=0-Infinity show=Masks summarize");
	//red channel
	selectWindow("red");
	run("Find Maxima...", "noise="+NoiseTol+" output=[Point Selection]");
	run("Create Mask");
	selectWindow("red");
	close();
	selectWindow("Mask");
	rename("red");
	imageCalculator("AND create", "red","mask");
	selectWindow("red");
	close();
	selectWindow("Result of red");
	rename("red");
	run("Set Measurements...", "  redirect=None decimal=2");
	run("Analyze Particles...", "size=0-Infinity show=Masks summarize");



	// enlarge selections for visualization and add them to RoiManager
	selectWindow("Mask of green");
	run("Create Selection");
	roiManager("add")
	roiManager("select", roiManager("count")-1);
	run("Enlarge...", "enlarge=3");
	run("Create Mask");
	selectWindow("Mask of green");
	close();
	rename("Mask of green");
	roiManager("delete");
	run("Create Selection");
	roiManager("add")
	roiManager("select", roiManager("count")-1);
	roiManager("rename", "green_"+NoiseTol+"_"+Sigma);
	selectWindow("Mask of red");
	run("Create Selection");
	roiManager("add")
	roiManager("select", roiManager("count")-1);
	run("Enlarge...", "enlarge=3");
	run("Create Mask");
	selectWindow("Mask of red");
	close();
	rename("Mask of red");
	roiManager("delete");
	run("Create Selection");
	roiManager("add")
	roiManager("select", roiManager("count")-1);
	roiManager("rename", "red_"+NoiseTol+"_"+Sigma);


	//Close unnecessary windows and rename others
	selectWindow("red");
	close();
	selectWindow("green");
	close();
	selectWindow("mask");
	rename("fibres");
	selectWindow("Mask of red");
	rename("red_Fibers");
	selectWindow("Mask of green");
	rename("green_Fibers");
	selectWindow("mainWindow");
	close();
	run("Images to Stack", "name=Stack title=[] use");
	setBatchMode(false);
	rename("out_"+NoiseTol+"_"+Sigma+"_"+T);
	selectWindow(T);
	setBatchMode(true);


	//Create output window for visualization (with overlays)
	run("Duplicate...", "title=mainWindow duplicate");
	run("Z Project...", "projection=[Max Intensity]");
	run("Split Channels");
	selectWindow("C1-MAX_mainWindow");
	rename("red");
	selectWindow("C2-MAX_mainWindow");
	rename("green");
	selectWindow("mainWindow");
	close();
	run("Enhance Contrast", "saturated=0.35");
	run("Apply LUT");
	roiManager("select", 0);
	run("Add Selection...");
	roiManager("select", 1);
	run("Add Selection...");
	selectWindow("red");
	run("Enhance Contrast", "saturated=0.35");
	run("Apply LUT");
	roiManager("select", 0);
	run("Add Selection...");
	roiManager("select", 2);
	run("Add Selection...");
	run("Images to Stack", "name=Stack title=[] use");
	rename("Stack_out_"+NoiseTol+"_"+Sigma+"_"+T);
	run("Grays");
	setBatchMode(false);
}

doAll();