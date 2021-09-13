/*

#  BIOIMAGING - INEB/i3S
Eduardo Conde-Sousa (econdesousa@gmail.com)

## Extended Plot Profile

* Runs over all ROIs and get point coordinates
* For each it expands in 3D (image units) and add to 3d manager
* at the end it gets 3d quantif
 
 
### code version
1.0 
	
### last modification
06/09/2021

### Requirements
* update sites (see https://imagej.net/plugins/morpholibj#installation):
	* IJPB-plugins
	


### Attribution:
If you use this macro please add in the acknowledgements of your papers and/or thesis (MSc and PhD) the reference to Bioimaging and the project PPBI-POCI-01-0145-FEDER-022122.
As a suggestion you may use the following sentence:
 * The authors acknowledge the support of the i3S Scientific Platform Bioimaging, member of the national infrastructure PPBI - Portuguese Platform of Bioimaging (PPBI-POCI-01-0145-FEDER-022122).

please cite:
* SNT: https://www.nature.com/articles/s41592-021-01105-7
* 3D ImageJ Suite: https://academic.oup.com/bioinformatics/article/29/14/1840/231770

*/

#@ float (value=5.0 , style="scroll bar", min=0, max=50, stepSize=0.1, label="neurite radius (in microns)", persist=true) nRadius
#@ Integer (label="Quantif channel:",value=1) quantifChannel
print("\\Clear");
print("neurite radius (in microns)", nRadius);
print("Quantif channel:",quantifChannel);

if (nImages!=1){
	close("*");
	filePath = File.openDialog("open image");
	open(filePath);
}


if (roiManager("count")<1){
	roiPath = File.openDialog("open ROI");
	roiManager("open", roiPath);
}

resetResults();


/*
# setup
*/
id=getImageID();
main = getTitle();
dir=getDirectory("image");
print("\\Clear");
mainName=substring(main, 0,lastIndexOf(main, "."));


Stack.getDimensions(w, h, c, s, f);
getVoxelSize(width, height, depth, unit);

run("3D Manager");
Ext.Manager3D_SelectAll();
Ext.Manager3D_Delete();


/*
# Create tmp mask
*/
setBatchMode(true);
newImage("mask", "8-bit black", getWidth, getHeight(), s);
setVoxelSize(width, height, depth, unit);
maskid=getImageID();



/*
# main loop
*/
for (i = 0; i < roiManager("count"); i++) {
	selectImage(id);
	getVoxelSize(width, height, depth, unit);
	roiManager("select", i);
	Stack.getPosition(channel, slice, frame);
	getSelectionCoordinates(xpoints, ypoints);
	print(lengthOf(xpoints));
	for (j = 0; j < lengthOf(xpoints); j++) {
		selectImage(maskid);	
		run("Select All");
		run("Set...", "value=0 stack");
		run("Select None");
		Stack.setSlice(slice);
		setPixel(xpoints[j], ypoints[j], 255);
		expand3Dmeasure(nRadius,maskid,main);
	}
	selectImage(id);
}

/*
# quantifications
*/
selectWindow(main);
Stack.setChannel(quantifChannel);

Ext.Manager3D_SelectAll();
Ext.Manager3D_Quantif();
selectWindow("Log");run("Close");
Ext.Manager3D_SaveResult("Q",dir+mainName+"_Results3D.csv");
Ext.Manager3D_CloseResult("Q");
Ext.Manager3D_Close();
selectWindow("Log");run("Close");

open(dir+"Q_"+mainName+"_Results3D.csv");


x=Table.getColumn("CMx (unit)");
y=Table.getColumn("CMy (unit)");
z=Table.getColumn("CMz (unit)");
Table.set("length (unit)", 0, 0);
Table.set("lengthAccumulated (unit)", 0, 0);
distTotal=0;
for (i = 1; i < lengthOf(x); i++) {
	dist=sqrt(pow(x[i-1]-x[i],2)+pow(y[i-1]-y[i], 2)+pow(z[i-1]-z[i], 2));
	Table.set("length (unit)", i, dist);
	distTotal = distTotal + dist;
	Table.set("lengthAccumulated (unit)", i, distTotal);
}

Table.save(dir+mainName+"_Results3D_ch_"+quantifChannel+".tsv");
Table.rename("Results");
File.delete(dir+"Q_"+mainName+"_Results3D.csv");
print("\\Clear");selectWindow("Log");run("Close");


/*
# plot profile
*/
length = Table.getColumn("lengthAccumulated (unit)");
IntDen = Table.getColumn("IntDen");

Plot.create("Expanded profile", "length (" + unit +")", "IntDen", length, IntDen);
Plot.setColor("red", "red");
Plot.add("circle", length, IntDen);
Plot.setColor("black");
Plot.setLineWidth(2);
Plot.add("line", length, IntDen);
Plot.show();

/*
# save and display "Done!" message
*/
saveAs("PNG", dir+mainName+"_profileExtended_ch_"+quantifChannel+".png");
print("Done!");


/*
# auxiliary functions
*/


function expand3Dmeasure(expandBy,maskid,main){
	selectImage(maskid);
	getVoxelSize(width, height, depth, unit);
	xstep = expandBy * width;
	ystep = expandBy * height;
	zstep = expandBy * depth;
	run("Morphological Filters (3D)", "operation=Dilation element=Ball x-radius="+xstep+" y-radius="+ystep+" z-radius="+zstep);
	id2close = getImageID();
	Ext.Manager3D_AddImage();
	selectImage(id2close);close();
}

function resetResults(){
	list = getList("window.titles");
	for (i = 0; i < lengthOf(list); i++) {
		if (indexOf(list[i],"Results")>=0) {
			selectWindow(list[i]);run("Close");
		}
	}
}
