/*
 * b.IMAGE - 10/01/2019
 * INEB -  Instituto Nacional de Engenharia Biomedica
 * i3S - Instituto de Investigacao e Inovacao em Saude
 * 
 * authors:
 * Eduardo Conde-Sousa (1)			Paulo Aguiar
 * econdesousa@ineb.up.pt			pauloaguiar@ineb.up.pt
 * 
 * (1) corresponding author
 * 
 * 
 * 
 * v0.2
 * -> fix mainName for "import sequence" stacks
 * -> add roiManager options to the beginning of macro 
 * 
 */
 
 /*
  * USAGE:
  * Macro that enables the creation of multiple ROIs 
  * for a given image. Three windows will be open:
  * 1st: main ImageJ/Fiji window
  * 2nd: Image
  * 3rd: Roi Manager
  * 
  * After user select one or more regions and add 
  * them to ROI manager by pressing OK buttom ROI will
  * be saved at the same folder of the image and with 
  * the same name (except for the extension)
  * 
  */



macro "save Roi" {
	roiManager("Associate", "true");
	roiManager("Centered", "false");
	roiManager("UseNames", "true");
	if (nImages<1){
		newIm = File.openDialog("Choose a File"); 
		open(newIm);
	}
	name=getTitle();
	ind=lastIndexOf(name,".");
	if (ind>=0) {
		mainName=substring(name, 0, ind);	
	}else {
		mainName = name;
	}
	path=getDirectory("image");
	run("ROI Manager...");
	flag=true;
	while (flag){
		roiManager("show all without labels")
		waitForUser("Press Ok when finished");
		
		flag=false;
	}
	if (roiManager("count")>0){
		roiManager("save", path + File.separator + mainName + ".zip");
		selectWindow("ROI Manager");
		run("Close");
		print("Roi saved at "+ path + mainName + ".zip" );
	}
	selectWindow(name);
	close();
}
