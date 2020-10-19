/*
 * Bioimaging - 19/1/2020
 * INEB -  Instituto Nacional de Engenharia Biomedica
 * i3S - Instituto de Investigacao e Inovacao em Saude
 * 
 * author:
 * Eduardo Conde-Sousa
 * econdesousa@ineb.up.pt
 * econdesousa@gmail.com
 * 
 * 
 *
 * ########################################################################## 
 * Count Number of Nuclei using STARDIST
 * ########################################################################## 
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
 */



#@ Integer (label="Channel of Interest: ",value=1) ch
#@ File (label="Select the Input Directory", style="directory",value="") inDir
#@ File (label="Select the Overview Directory", style="directory",value="") outDir


//setBatchMode(true);
clearWindows();

list = getFileList(inDir);
for (i=0;i<lengthOf(list);i++){
	if ( checkfileformat(list[i]) == 1 ){
		print(list[i]);
		run("Bio-Formats Importer", "open=["+inDir+File.separator+list[i]+"] autoscale color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
		procFile();
	}
}
run("Clear Results");
clearWindows();
print("Done!");


function checkfileformat(filename) { 
	acceptableFormats=newArray(".tif",".tiff",".zvi","lif");
	flag = 0;
	for (f=1;f<lengthOf(acceptableFormats);f++){
		if ( endsWith(toLowerCase(filename), acceptableFormats[f])){
			flag=1;
		}		
	}
	return flag;	
}

function clearWindows(){
	NonImageWindlist = getList("window.titles");
	for (it=0;it<lengthOf(NonImageWindlist);it++){
		selectWindow(NonImageWindlist[it]);
		run("Close");
	}
}


function procFile() { 
	roiManager("reset");
	name=getTitle();
	run("Duplicate...", "title=mask duplicate channels="+ch);
	maskID=getImageID();
	run("Command From Macro", "command=[de.csbdresden.stardist.StarDist2D], args=['input':'mask', 'modelChoice':'Versatile (fluorescent nuclei)', 'normalizeInput':'true', 'percentileBottom':'1.0', 'percentileTop':'99.8', 'probThresh':'0.5', 'nmsThresh':'0.4', 'outputType':'Both', 'nTiles':'1', 'excludeBoundary':'2', 'roiPosition':'Automatic', 'verbose':'false', 'showCsbdeepProgress':'false', 'showProbAndDist':'false'], process=[false]");
	selectWindow("Label Image");
	run("Flatten");
	selectWindow("Label Image-1");
	saveAs("JPEG", outDir + File.separator + name);
	row=nResults;print(row);
	setResult("Label", row, name);
	setResult("NumCells", row, roiManager("count")); 
	close("*");
	run("Collect Garbage");
	saveAs("Results", inDir+File.separator+"NumCells.csv");
}
