/*
 * bioimaging - 28/11/2019
 * INEB -  Instituto Nacional de Engenharia Biomedica
 * i3S - Instituto de Investigacao e Inovacao em Saude
 * 
 * Eduardo Conde-Sousa
 * econdesousa@ineb.up.pt
 * econdesousa@gmail.com
 * 
 * 
 * =====================================================
 * Get Basic Stats from combination of mask + main image
 * =====================================================
 * 
 * 
 * USAGE:
 * 		1) Select a folder containing labled mask	
 * 				(it assumes 16-bit labeled image) 
 * 		2) In the input folder it looks for *.tiff files 
				(choose another if necessary)
 * 		3) In the parent directory it will find the original image
 * 				(it assumes the same name and extension *.tif)
 * 		4) saves in a folder the combined results and summary tables
 * 				(it uses *.tsv file format - use e.g. excel to open)
 * 		
 * 		
 * 		
 * 
 * If you use this macro please add in the acknowledgements 
 * of your papers and/or thesis (MSc and PhD) the reference 
 * to Bioimaging and the project PPBI-POCI-01-0145-FEDER-022122. 
 * 
 * As a suggestion you may use the following sentence:
 * 
 * The authors acknowledge the support of the i3S Scientific Platform 
 * Bioimaging, member of the national infrastructure 
 * PPBI - Portuguese Platform of Bioimaging (PPBI-POCI-01-0145-FEDER-022122).
 * 
 * 
 * code version: 0.1	
 */

 
close("*");

filePath=getDirectory("Select the Condition/output Directory");

ext=".tiff";
ext = getString("Labeled mask file extension", ext);

procMultipleFiles(filePath,ext);




function procMultipleFiles(filePath,ext){
	setBatchMode(true);
	list=getFileList(filePath);
	close("*");
	closeAllWindows();
	for (i = 0; i < lengthOf(list); i++) {
		if (endsWith(list[i],ext)){
			fileName=list[i];
			proc1File(filePath,fileName);
		}	
	}
	close("*");
	outFolder=File.getParent(filePath)+File.separator+"ResultsTables"+File.separator;
	if (!File.exists(outFolder)){
		File.makeDirectory(outFolder);
	}
	selectWindow("Results");
	saveAs("Results", outFolder+"RESULTS.tsv");
	selectWindow("Summary");
	saveAs("Results", outFolder+"SUMMARY.tsv");
}

function proc1File(filePath,fileName){ 
	
	mainFilePath=File.getParent(filePath)+File.separator;
	mainFileName=replace(fileName, ext, ".tif");
	
	open(filePath+fileName);
	run("Select None");
	setThreshold(1, 65535);
	setOption("BlackBackground", true);
	run("Convert to Mask");
	
	mask=replace(mainFileName,".tif","");
	rename(mask);
	open(mainFilePath+mainFileName);
	run("Tile");
	
	
	run("Set Measurements...", "area mean standard modal min perimeter fit shape feret's integrated median skewness kurtosis area_fraction display redirect="+mainFileName+" decimal=3");
	selectWindow(mask);
	run("Analyze Particles...", "  show=Overlay display summarize");
}

function closeAllWindows(){
	wind=getList("window.titles");
	for (i = 0; i < lengthOf(wind); i++) {
		selectWindow(wind[i]);
		run("Close");
	}
}