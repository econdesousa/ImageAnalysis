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
 * Create a GIF image with some filters applied
 * =====================================================
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



setBatchMode(true);

count=0;
flag=false;
if (nImages!=1){ 
	flag=true;
}else if (bitDepth()!=24){
	flag=true;
}


while (flag){
	oneRGB();
	if (count++ >0){
		waitForUser("open ONE rgb image and press ok");
	}
	if (nImages==1 ){ 
		if (bitDepth==24){
			flag=false;
		}
	}
}	
t=getTitle();
rename("Color");
// Create Gray Scale Image
run("Duplicate...","title=Gray");
run("8-bit");
// Edges
run("Duplicate...","title=[Canny Edge Detector]");
run("Canny Edge Detector", "gaussian=2 low=2.5 high=7.5");

// Gradient
selectWindow("Gray");
run("Morphological Filters", "operation=Gradient element=Disk radius=5");
rename("Gradient");

// Laplacian
selectWindow("Gray");
run("Morphological Filters", "operation=Laplacian element=Disk radius=5");
rename("Laplacian");

// K-Means
selectWindow("Color");
//run("Duplicate...","title=[K-means]");
run("k-means Clustering ...", "number_of_clusters=4 cluster_center_tolerance=0.00010000 enable_randomization_seed randomization_seed=48");
rename("K-means");
addOverlay();

// Create Stack
run("Images to Stack", "name=Stack title=[] use");
setBatchMode(false);

Dialog.create("Save Gif?")
Dialog.addChoice("", newArray("Yes","No"));
Dialog.show();
ans=Dialog.getChoice();
if (ans == "Yes"){
	dir=getDirectory("Choose a directory to save file");
	Dialog.create("")
	Dialog.addString("Name of Gif?", t);
	Dialog.show();
	fName=Dialog.getString();
	saveAs("Gif", dir+fName);
}

function addOverlay() { 
	for (i = 0; i < nImages; i++) {
		selectImage(i+1);
		Overlay.remove
		overlayImageTitle(50,"yellow");
	}
}

function overlayImageTitle(fontSize,color) {
	x = 10;
    y = 10 + fontSize;
    setColor(color);
    setFont("SansSerif", fontSize);
    name = getTitle();
    Overlay.remove;
    Overlay.drawString(name, x, y);
    Overlay.show;
}


function oneRGB(){
	if (nImages!=1){
		close("*");
		open("");
	}
}