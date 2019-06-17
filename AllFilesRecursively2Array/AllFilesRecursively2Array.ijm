/*
 * b.IMAGE - 17/06/2019
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
 * Extract an array with all the files in a folder and sub-folders.
 * ########################################################################## 
 * 
 * 
 * function listFiles(dir) is adapted from:
 * 				
 * 				https://imagej.nih.gov/ij/macros/ListFilesRecursively.txt
 * 	
 * 	replace print to setResult
 */

dir = getDirectory("Choose a Directory ");
AllFiles=getFileName(dir);


//Functions:
// ========================================================
function getFileName(dir){
	// Files are temporarilly stored in Result table
	// To avoid clearing previous table, it is rename now and 
	// back to original name at the end
	NR=nResults;
	tmpResults="tmpResults_"+round(100000*random);
	if (nResults>0){
		IJ.renameResults("Results",tmpResults);
	}
	
	run("Clear Results");
	setOption("ShowRowNumbers", true);
	listFiles(dir); 
	updateResults;
	
	AllFiles=newArray(nResults);
	for (ii = 0; ii < nResults; ii++) {
		AllFiles[ii]=getResultString("FileName", ii);
	}
	AllFiles = replaceFolderSep(AllFiles);
	
	if (NR>0){
		IJ.renameResults(tmpResults,"Results");
	}else{
		selectWindow("Results");
		run("Close");
	}
	return AllFiles;
}
// ========================================================
function replaceFolderSep(folder){
	for (i = 0; i < folder.length; i++) {
		folder[i]=replace(folder[i]	, "\\", "/");
	}
	return folder;
}
// ========================================================
function listFiles(dir) {
	list = getFileList(dir);
	for (i=0; i<list.length; i++) {
		if (endsWith(list[i], "/") || endsWith(list[i],"\\")){
			listFiles(""+dir+list[i]);
		}else{
			setResult("FileName", nResults, dir + list[i]);
		}
     }
  }
// ========================================================






